require 'thread'
require 'digest/sha1'

module Stomp

  # Typical Stomp client class. Uses a listener thread to receive frames
  # from the server, any thread can send.
  #
  # Receives all happen in one thread, so consider not doing much processing
  # in that thread if you have much message volume.
  class Client

    attr_reader :login, :passcode, :host, :port, :reliable, :parameters
    
    #alias :obj_send :send

    # A new Client object can be initialized using two forms:
    #
    # Standard positional parameters:
    #   login     (String,  default : '')
    #   passcode  (String,  default : '')
    #   host      (String,  default : 'localhost')
    #   port      (Integer, default : 61613)
    #   reliable  (Boolean, default : false)
    #
    #   e.g. c = Client.new('login', 'passcode', 'localhost', 61613, true)
    #
    # Stomp URL :
    #   A Stomp URL must begin with 'stomp://' and can be in one of the following forms:
    #
    #   stomp://host:port
    #   stomp://host.domain.tld:port
    #   stomp://login:passcode@host:port
    #   stomp://login:passcode@host.domain.tld:port
    #
    def initialize(login = '', passcode = '', host = 'localhost', port = 61613, reliable = false)

      # Parse stomp:// URL's or set params
      if login.is_a?(Hash)
        @parameters = login
        
        first_host = @parameters[:hosts][0]
        
        @login = first_host[:login]
        @passcode = first_host[:passcode]
        @host = first_host[:host]
        @port = first_host[:port] || Connection::default_port(first_host[:ssl])
        
        @reliable = true
        
      elsif login =~ /^stomp:\/\/#{url_regex}/ # e.g. stomp://login:passcode@host:port or stomp://host:port
        @login = $2 || ""
        @passcode = $3 || ""
        @host = $4
        @port = $5.to_i
        @reliable = false
      elsif login =~ /^failover:(\/\/)?\(stomp(\+ssl)?:\/\/#{url_regex}(,stomp(\+ssl)?:\/\/#{url_regex}\))+(\?(.*))?$/ # e.g. failover://(stomp://login1:passcode1@localhost:61616,stomp://login2:passcode2@remotehost:61617)?option1=param

        first_host = {}
        first_host[:ssl] = !$2.nil?
        @login = first_host[:login] = $4 || ""
        @passcode = first_host[:passcode] = $5 || ""
        @host = first_host[:host] = $6
        @port = first_host[:port] = $7.to_i || Connection::default_port(first_host[:ssl])
        
        options = $16 || ""
        parts = options.split(/&|=/)
        options = Hash[*parts]
        
        hosts = [first_host] + parse_hosts(login)
        
        @parameters = {}
        @parameters[:hosts] = hosts
        
        @parameters.merge! filter_options(options)
                
        @reliable = true
      else
        @login = login
        @passcode = passcode
        @host = host
        @port = port.to_i
        @reliable = reliable
      end

      check_arguments!

      @id_mutex = Mutex.new
      @ids = 1

      if @parameters
        @connection = Connection.new(@parameters)
      else
        @connection = Connection.new(@login, @passcode, @host, @port, @reliable)
      end
      
      start_listeners

    end
    
    # Syntactic sugar for 'Client.new' See 'initialize' for usage.
    def self.open(login = '', passcode = '', host = 'localhost', port = 61613, reliable = false)
      Client.new(login, passcode, host, port, reliable)
    end

    # Join the listener thread for this client,
    # generally used to wait for a quit signal
    def join(limit = nil)
      @listener_thread.join(limit)
    end

    # Begin a transaction by name
    def begin(name, headers = {})
      @connection.begin(name, headers)
    end

    # Abort a transaction by name
    def abort(name, headers = {})
      @connection.abort(name, headers)

      # lets replay any ack'd messages in this transaction
      replay_list = @replay_messages_by_txn[name]
      if replay_list
        replay_list.each do |message|
          if listener = find_listener(message)
            listener.call(message)
          end
        end
      end
    end

    # Commit a transaction by name
    def commit(name, headers = {})
      txn_id = headers[:transaction]
      @replay_messages_by_txn.delete(txn_id)
      @connection.commit(name, headers)
    end

    # Subscribe to a destination, must be passed a block
    # which will be used as a callback listener
    #
    # Accepts a transaction header ( :transaction => 'some_transaction_id' )
    def subscribe(destination, headers = {})
      raise "No listener given" unless block_given?
      # use subscription id to correlate messages to subscription. As described in
      # the SUBSCRIPTION section of the protocol: http://stomp.codehaus.org/Protocol.
      # If no subscription id is provided, generate one.
      set_subscription_id_if_missing(destination, headers)
      if @listeners[headers[:id]]
        raise "attempting to subscribe to a queue with a previous subscription"
      end
      @listeners[headers[:id]] = lambda {|msg| yield msg}
      @connection.subscribe(destination, headers)
    end

    # Unsubecribe from a channel
    def unsubscribe(name, headers = {})
      set_subscription_id_if_missing(name, headers)
      @connection.unsubscribe(name, headers)
      @listeners[headers[:id]] = nil
    end

    # Acknowledge a message, used when a subscription has specified
    # client acknowledgement ( connection.subscribe "/queue/a", :ack => 'client'g
    #
    # Accepts a transaction header ( :transaction => 'some_transaction_id' )
    def acknowledge(message, headers = {})
      txn_id = headers[:transaction]
      if txn_id
        # lets keep around messages ack'd in this transaction in case we rollback
        replay_list = @replay_messages_by_txn[txn_id]
        if replay_list.nil?
          replay_list = []
          @replay_messages_by_txn[txn_id] = replay_list
        end
        replay_list << message
      end
      if block_given?
        headers['receipt'] = register_receipt_listener lambda {|r| yield r}
      end
      @connection.ack message.headers['message-id'], headers
    end
    
    # Unreceive a message, sending it back to its queue or to the DLQ
    #
    def unreceive(message, options = {})
      @connection.unreceive(message, options)
    end
    
    # Publishes message to destination
    #
    # If a block is given a receipt will be requested and passed to the
    # block on receipt
    #
    # Accepts a transaction header ( :transaction => 'some_transaction_id' )
    def publish(destination, message, headers = {})
      if block_given?
        headers['receipt'] = register_receipt_listener lambda {|r| yield r}
      end
      @connection.publish(destination, message, headers)
    end
    
    def obj_send(*args)
      __send__(*args)
    end
    
    def send(*args)
      warn("This method is deprecated and will be removed on the next release. Use 'publish' instead")
      publish(*args)
    end
    
    def connection_frame
      @connection.connection_frame
    end

    def disconnect_receipt
      @connection.disconnect_receipt
    end

    # Is this client open?
    def open?
      @connection.open?
    end

    # Is this client closed?
    def closed?
      @connection.closed?
    end

    # Close out resources in use by this client
    def close headers={}
      @listener_thread.exit
      @connection.disconnect headers
    end

    # Check if the thread was created and isn't dead
    def running
      @listener_thread && !!@listener_thread.status
    end

    private
      # Set a subscription id in the headers hash if one does not already exist.
      # For simplicities sake, all subscriptions have a subscription ID.
      # setting an id in the SUBSCRIPTION header is described in the stomp protocol docs:
      # http://stomp.codehaus.org/Protocol
      def set_subscription_id_if_missing(destination, headers)
        headers[:id] = headers[:id] ? headers[:id] : headers['id'] 
        if headers[:id] == nil
          headers[:id] = Digest::SHA1.hexdigest(destination)
        end
      end

      def register_receipt_listener(listener)
        id = -1
        @id_mutex.synchronize do
          id = @ids.to_s
          @ids = @ids.succ
        end
        @receipt_listeners[id] = listener
        id
      end
      
       # e.g. login:passcode@host:port or host:port
      def url_regex
        '(([\w\.\-]*):(\w*)@)?([\w\.\-]+):(\d+)'
      end
      
      def parse_hosts(url)
        hosts = []
        
        host_match = /stomp(\+ssl)?:\/\/(([\w\.]*):(\w*)@)?([\w\.]+):(\d+)\)/
        url.scan(host_match).each do |match|
          host = {}
          host[:ssl] = !match[0].nil?
          host[:login] =  match[2] || ""
          host[:passcode] = match[3] || ""
          host[:host] = match[4]
          host[:port] = match[5].to_i
          
          hosts << host
        end
        
        hosts
      end
      
      def check_arguments!
        raise ArgumentError if @host.nil? || @host.empty?
        raise ArgumentError if @port.nil? || @port == '' || @port < 1 || @port > 65535
        raise ArgumentError unless @reliable.is_a?(TrueClass) || @reliable.is_a?(FalseClass)
      end
      
      def filter_options(options)
        new_options = {}
        new_options[:initial_reconnect_delay] = (options["initialReconnectDelay"] || 10).to_f / 1000 # In ms
        new_options[:max_reconnect_delay] = (options["maxReconnectDelay"] || 30000 ).to_f / 1000 # In ms
        new_options[:use_exponential_back_off] = !(options["useExponentialBackOff"] == "false") # Default: true
        new_options[:back_off_multiplier] = (options["backOffMultiplier"] || 2 ).to_i
        new_options[:max_reconnect_attempts] = (options["maxReconnectAttempts"] || 0 ).to_i
        new_options[:randomize] = options["randomize"] == "true" # Default: false
        new_options[:backup] = false # Not implemented yet: I'm using a master X slave solution
        new_options[:timeout] = -1 # Not implemented yet: a "timeout(5) do ... end" would do the trick, feel free
        
        new_options
      end
      
      def find_listener(message)
        subscription_id = message.headers['subscription']
        if subscription_id == nil
          # For backward compatibility, some messages may already exist with no
          # subscription id, in which case we can attempt to synthesize one.
          set_subscription_id_if_missing(message.headers['destination'], message.headers)
          subscription_id = message.headers[:id]
        end
        @listeners[subscription_id]
      end

      def start_listeners
        @listeners = {}
        @receipt_listeners = {}
        @replay_messages_by_txn = {}

        @listener_thread = Thread.start do
          while true
            message = @connection.receive
            if message.command == 'MESSAGE'
              if listener = find_listener(message)
                listener.call(message)
              end
            elsif message.command == 'RECEIPT'
              if listener = @receipt_listeners[message.headers['receipt-id']]
                listener.call(message)
              end
            end
          end
        end
        
      end
  end
end

