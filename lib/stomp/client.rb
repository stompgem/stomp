# -*- encoding: utf-8 -*-

require 'thread'
require 'digest/sha1'
require 'timeout'
require 'forwardable'

module Stomp

  # Typical Stomp client class. Uses a listener thread to receive frames
  # from the server, any thread can send.
  #
  # Receives all happen in one thread, so consider not doing much processing
  # in that thread if you have much message volume.
  class Client
    extend Forwardable

    # Parameters hash
    attr_reader :parameters

    def_delegators :@connection, :login, :passcode, :port, :host, :ssl
    def_delegator :@parameters, :reliable

    # A new Client object can be initialized using three forms:
    #
    # Hash (this is the recommended Client initialization method):
    #
    #   hash = {
    #     :hosts => [
    #       {:login => "login1", :passcode => "passcode1", :host => "localhost", :port => 61616, :ssl => false},
    #       {:login => "login2", :passcode => "passcode2", :host => "remotehost", :port => 61617, :ssl => false}
    #     ],
    #     # These are the default parameters and do not need to be set
    #     :reliable => true,                  # reliable (use failover)
    #     :initial_reconnect_delay => 0.01,   # initial delay before reconnect (secs)
    #     :max_reconnect_delay => 30.0,       # max delay before reconnect
    #     :use_exponential_back_off => true,  # increase delay between reconnect attpempts
    #     :back_off_multiplier => 2,          # next delay multiplier
    #     :max_reconnect_attempts => 0,       # retry forever, use # for maximum attempts
    #     :randomize => false,                # do not radomize hosts hash before reconnect
    #     :connect_timeout => 0,              # Timeout for TCP/TLS connects, use # for max seconds
    #     :connect_headers => {},             # user supplied CONNECT headers (req'd for Stomp 1.1+)
    #     :parse_timeout => 5,                # IO::select wait time on socket reads
    #     :logger => nil,                     # user suplied callback logger instance
    #     :dmh => false,                      # do not support multihomed IPV4 / IPV6 hosts during failover
    #     :closed_check => true,              # check first if closed in each protocol method
    #     :hbser => false,                    # raise on heartbeat send exception
    #     :stompconn => false,                # Use STOMP instead of CONNECT
    #     :usecrlf => false,                  # Use CRLF command and header line ends (1.2+)
    #     :max_hbread_fails => 0,             # Max HB read fails before retry.  0 => never retry
    #     :max_hbrlck_fails => 0,             # Max HB read lock obtain fails before retry.  0 => never retry
    #     :fast_hbs_adjust => 0.0,            # Fast heartbeat senders sleep adjustment, seconds, needed ...
    #                                         # For fast heartbeat senders.  'fast' == YMMV.  If not
    #                                         # correct for your environment, expect unnecessary fail overs
    #     :connread_timeout => 0,             # Timeout during CONNECT for read of CONNECTED/ERROR, secs
    #     :tcp_nodelay => true,               # Turns on the TCP_NODELAY socket option; disables Nagle's algorithm
    #     :start_timeout => 0,                # Timeout around Stomp::Client initialization
    #     :sslctx_newparm => nil,             # Param for SSLContext.new
    #     :ssl_post_conn_check => true,       # Further verify broker identity
    #   }
    #
    #   e.g. c = Stomp::Client.new(hash)
    #
    # Positional parameters:
    #   login     (String,  default : '')
    #   passcode  (String,  default : '')
    #   host      (String,  default : 'localhost')
    #   port      (Integer, default : 61613)
    #   reliable  (Boolean, default : false)
    #
    #   e.g. c = Stomp::Client.new('login', 'passcode', 'localhost', 61613, true)
    #
    # Stomp URL :
    #   A Stomp URL must begin with 'stomp://' and can be in one of the following forms:
    #
    #   stomp://host:port
    #   stomp://host.domain.tld:port
    #   stomp://login:passcode@host:port
    #   stomp://login:passcode@host.domain.tld:port
    #
    #   e.g. c = Stomp::Client.new(urlstring)
    #
    def initialize(login = '', passcode = '', host = 'localhost', port = 61613, reliable = false, autoflush = false)
      parse_hash_params(login) ||
        parse_stomp_url(login) ||
        parse_failover_url(login) ||
        parse_positional_params(login, passcode, host, port, reliable)

      @logger = @parameters[:logger] ||= Stomp::NullLogger.new
      @start_timeout = @parameters[:start_timeout] || 0
      @parameters[:client_main] = Thread::current
      ## p [ "CLINDBG", @parameters[:client_main] ]
      check_arguments!()

      # p [ "cldbg01", @parameters ]

      begin
        Timeout::timeout(@start_timeout) {
          create_error_handler
          create_connection(autoflush)
          start_listeners()
        }
      rescue TimeoutError
        # p [ "cldbg02" ]
        ex = Stomp::Error::StartTimeoutException.new(@start_timeout)
        raise ex
      end
    end

    def create_error_handler
      client_thread = Thread.current

      @error_listener = lambda do |error|
        exception = case error.body
                      when /ResourceAllocationException/i
                        Stomp::Error::ProducerFlowControlException.new(error)
                      when /ProtocolException/i
                        Stomp::Error::ProtocolException.new(error)
                      else
                        Stomp::Error::BrokerException.new(error)
                    end

        @receipt_listeners.delete(error.headers['receipt-id']) if error.headers['receipt-id']
        client_thread.raise exception
      end
    end

    def create_connection(autoflush)
      # p [ "ccon01", @parameters ]
      @connection = Connection.new(@parameters)
      @connection.autoflush = autoflush
    end
    private :create_connection

    # open is syntactic sugar for 'Client.new', see 'initialize' for usage.
    def self.open(login = '', passcode = '', host = 'localhost', port = 61613, reliable = false)
      Client.new(login, passcode, host, port, reliable)
    end

    # join the listener thread for this client,
    # generally used to wait for a quit signal.
    def join(limit = nil)
      @listener_thread.join(limit)
    end

    # Begin starts work in a a transaction by name.
    def begin(name, headers = {})
      @connection.begin(name, headers)
    end

    # Abort aborts work in a transaction by name.
    def abort(name, headers = {})
      @connection.abort(name, headers)

      # replay any ack'd messages in this transaction
      replay_list = @replay_messages_by_txn[name]
      if replay_list
        replay_list.each do |message|
          find_listener(message) # find_listener also calls the listener
        end
      end
    end

    # Commit commits work in a transaction by name.
    def commit(name, headers = {})
      txn_id = headers[:transaction]
      @replay_messages_by_txn.delete(txn_id)
      @connection.commit(name, headers)
    end

    # Subscribe to a destination, must be passed a block
    # which will be used as a callback listener.
    # Accepts a transaction header ( :transaction => 'some_transaction_id' ).
    def subscribe(destination, headers = {})
      raise Stomp::Error::NoListenerGiven unless block_given?
      headers = headers.symbolize_keys
      raise Stomp::Error::DestinationRequired unless destination
      # use subscription id to correlate messages to subscription. As described in
      # the SUBSCRIPTION section of the protocol: http://stomp.github.com/.
      # If no subscription id is provided, generate one.
      headers = headers.merge(:id => build_subscription_id(destination, headers))
      if @listeners[headers[:id]]
        raise Stomp::Error::DuplicateSubscription
      end
      @listeners[headers[:id]] = lambda {|msg| yield msg}
      @connection.subscribe(destination, headers)
    end

    # Unsubscribe from a subscription by name.
    def unsubscribe(destination, headers = {})
      headers = headers.symbolize_keys
      raise Stomp::Error::DestinationRequired unless destination
      headers = headers.merge(:id => build_subscription_id(destination, headers))
      @connection.unsubscribe(destination, headers)
      @listeners[headers[:id]] = nil
    end

    # Acknowledge a message, used when a subscription has specified
    # client acknowledgement ( connection.subscribe("/queue/a",{:ack => 'client'}).
    # Accepts a transaction header ( :transaction => 'some_transaction_id' ).
    def ack(message, headers = {})
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
        headers = headers.merge(:receipt => register_receipt_listener(lambda {|r| yield r}))
      end
      context = ack_context_for(message, headers)
      @connection.ack context[:message_id], context[:headers]
    end

    # For posterity, we alias:
    alias acknowledge ack

    # Stomp 1.1+ NACK.
    def nack(message, headers = {})
      context = ack_context_for(message, headers)
      @connection.nack context[:message_id], context[:headers]
    end

    #
    def ack_context_for(message, headers)
      id = case protocol
        when Stomp::SPL_12
         'ack'
        when Stomp::SPL_11
         headers = headers.merge(:subscription => message.headers['subscription'])
         'message-id'
        else
         'message-id'
      end
      {:message_id => message.headers[id], :headers => headers}
    end

    # Unreceive a message, sending it back to its queue or to the DLQ.
    def unreceive(message, options = {})
      @connection.unreceive(message, options)
    end

    # Publishes message to destination.
    # If a block is given a receipt will be requested and passed to the
    # block on receipt.
    # Accepts a transaction header ( :transaction => 'some_transaction_id' ).
    def publish(destination, message, headers = {})
      headers = headers.symbolize_keys
      raise Stomp::Error::DestinationRequired unless destination
      if block_given?
        headers = headers.merge(:receipt => register_receipt_listener(lambda {|r| yield r}))
      end
      @connection.publish(destination, message, headers)
    end

    # Return the broker's CONNECTED frame to the client.  Misnamed.
    def connection_frame()
      @connection.connection_frame
    end

    # Return any RECEIPT frame received by DISCONNECT.
    def disconnect_receipt()
      @connection.disconnect_receipt
    end

    # open? tests if this client connection is open.
    def open?
      @connection.open?()
    end

    # close? tests if this client connection is closed.
    def closed?()
      @connection.closed?()
    end

    # jruby? tests if the connection has detcted a JRuby environment
    def jruby?()
      @connection.jruby
    end

    # close frees resources in use by this client.  The listener thread is
    # terminated, and disconnect on the connection is called.
    def close(headers={})
      @listener_thread.exit
      @connection.disconnect(headers)
    end

    # running checks if the thread was created and is not dead.
    def running()
      @listener_thread && !!@listener_thread.status
    end

    # set_logger identifies a new callback logger.
    def set_logger(logger)
      @logger = logger
      @connection.set_logger(logger)
    end

    # protocol returns the current client's protocol level.
    def protocol()
      @connection.protocol()
    end

    # valid_utf8? validates any given string for UTF8 compliance.
    def valid_utf8?(s)
      @connection.valid_utf8?(s)
    end

    # sha1 returns a SHA1 sum of a given string.
    def sha1(data)
      @connection.sha1(data)
    end

    # uuid returns a type 4 UUID.
    def uuid()
      @connection.uuid()
    end

    # hbsend_interval returns the connection's heartbeat send interval.
    def hbsend_interval()
      @connection.hbsend_interval()
    end

    # hbrecv_interval returns the connection's heartbeat receive interval.
    def hbrecv_interval()
      @connection.hbrecv_interval()
    end

    # hbsend_count returns the current connection's heartbeat send count.
    def hbsend_count()
      @connection.hbsend_count()
    end

    # hbrecv_count returns the current connection's heartbeat receive count.
    def hbrecv_count()
      @connection.hbrecv_count()
    end

    # Poll for asynchronous messages issued by broker.
    # Return nil of no message available, else the message
    def poll()
      @connection.poll()
    end

    # autoflush= sets the current connection's autoflush setting.
    def autoflush=(af)
      @connection.autoflush = af
    end

    # autoflush returns the current connection's autoflush setting.
    def autoflush()
      @connection.autoflush()
    end

  end # Class

end # Module
