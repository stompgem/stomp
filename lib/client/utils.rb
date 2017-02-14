# -*- encoding: utf-8 -*-

require 'thread'
require 'digest/sha1'

module Stomp

  class Client

    private

    def parse_hash_params(params)
      return false unless params.is_a?(Hash)

      @parameters = params
      # Do not override user choice of false.
      @parameters[:reliable] = true unless @parameters[:reliable] == false

      true
    end

    def parse_stomp_url(login)
      original_verbose, $VERBOSE = $VERBOSE, nil # shut off warnings
      regexp = /^stomp:\/\/#{URL_REPAT}/
      url = regexp.match(login)
      $VERBOSE = original_verbose
      return false unless url
      @login =  url[3] || ""
      @passcode = url[4] || ""
      @host = url[5]
      @port = url[6].to_i
      @parameters = { :reliable => false,
                      :hosts => [ { :login => @login,
                                    :passcode => @passcode,
                                    :host => @host,
                                    :port => @port} ] }
      true
    end

    # e.g. failover://(stomp://login1:passcode1@localhost:61616,stomp://login2:passcode2@remotehost:61617)?option1=param
    def parse_failover_url(login)
      rval = nil
      original_verbose, $VERBOSE = $VERBOSE, nil # shut off warnings
      md = FAILOVER_REGEX.match(login)
      $VERBOSE = original_verbose
      if md
        finhosts = parse_hosts(login)

        options = {}
        if md_last = md[-1]
          parts = md_last.split(/&|=/)
          raise Stomp::Error::MalformedFailoverOptionsError unless ( parts.size % 2 ) == 0
          options = Hash[*parts]
        end

        @parameters = {:hosts => finhosts}.merge!(filter_options(options))

        @parameters[:reliable] = true
        rval = true
      end
      rval
    end

    def parse_positional_params(login, passcode, host, port, reliable)
      @parameters = { :reliable => reliable,
                      :hosts => [ { :login => login,
                                    :passcode => passcode,
                                    :host => host,
                                    :port => port.to_i } ] }
      true
    end

    # Set a subscription id in the headers hash if one does not already exist.
    # For simplicities sake, all subscriptions have a subscription ID.
    # setting an id in the SUBSCRIPTION header is described in the stomp protocol docs:
    # http://stomp.github.com/
    def set_subscription_id_if_missing(destination, headers)
      headers[:id] = build_subscription_id(destination, headers)
    end

    def build_subscription_id(destination, headers)
      return headers[:id] until headers[:id].nil?
      return headers['id'] until headers['id'].nil?
      # p [ "DBBSID1", destination, headers ]
      Digest::SHA1.hexdigest(destination)
    end

    # Parse a stomp URL.
    def parse_hosts(url)
      hosts = []
      original_verbose, $VERBOSE = $VERBOSE, nil # shut off warnings
      host_match = /stomp(\+ssl)?:\/\/#{URL_REPAT}/
      url.scan(host_match).each do |match|
        host = {}
        host[:ssl] = match[0] == "+ssl" ? true : false
        host[:login] =  match[3] || ""
        host[:passcode] = match[4] || ""
        host[:host] = match[5]
        host[:port] = match[6].to_i
        hosts << host
      end
      $VERBOSE = original_verbose
      hosts
    end

    # A sanity check of required arguments.
    def check_arguments!()
      raise ArgumentError.new("missing :hosts parameter") unless @parameters[:hosts]
      raise ArgumentError.new("invalid :hosts type") unless @parameters[:hosts].is_a?(Array)
      @parameters[:hosts].each do |hv|
        # Validate port requested
        raise ArgumentError.new("empty :port value in #{hv.inspect}") if hv[:port] == ''
        unless hv[:port].nil?
          tpv = hv[:port].to_i
          raise ArgumentError.new("invalid :port value=#{tpv} from #{hv.inspect}") if tpv < 1 || tpv > 65535
        end
        # Validate host requested (no validation here.  if nil or '', localhost will
        # be used in #Connection.)
      end
      raise ArgumentError unless @parameters[:reliable].is_a?(TrueClass) || @parameters[:reliable].is_a?(FalseClass)
      #
      if @parameters[:reliable] && @start_timeout > 0
        warn "WARN detected :reliable == true and :start_timeout > 0"
        warn "WARN this may cause incorrect fail-over behavior"
        warn "WARN use :start_timeout => 0 to correct fail-over behavior"
      end
    end

    # filter_options returns a new Hash of filtered options.
    def filter_options(options)
      new_options = {}
      new_options[:initial_reconnect_delay] = (options["initialReconnectDelay"] || 10).to_f / 1000 # In ms
      new_options[:max_reconnect_delay] = (options["maxReconnectDelay"] || 30000 ).to_f / 1000 # In ms
      new_options[:use_exponential_back_off] = !(options["useExponentialBackOff"] == "false") # Default: true
      new_options[:back_off_multiplier] = (options["backOffMultiplier"] || 2 ).to_i
      new_options[:max_reconnect_attempts] = (options["maxReconnectAttempts"] || 0 ).to_i
      new_options[:randomize] = options["randomize"] == "true" # Default: false
      new_options[:connect_timeout] = 0

      new_options
    end

    # find_listener returns the listener for a given subscription in a given message.
    def find_listener(message)
      subscription_id = message.headers['subscription']
      if subscription_id == nil
        # For backward compatibility, some messages may already exist with no
        # subscription id, in which case we can attempt to synthesize one.
        set_subscription_id_if_missing(message.headers['destination'], message.headers)
        subscription_id = message.headers[:id]
      end

      listener = @listeners[subscription_id]
      listener.call(message) if listener
    end

    # Register a receipt listener.
    def register_receipt_listener(listener)
      id = uuid
      @receipt_listeners[id] = listener
      id
    end

    def find_receipt_listener(message)
      listener = @receipt_listeners[message.headers['receipt-id']]
      if listener
         listener.call(message)
         @receipt_listeners.delete(message.headers['receipt-id'])
      end
    end

    def create_listener_maps
      @listeners = {}
      @receipt_listeners = {}
      @replay_messages_by_txn = {}

      @listener_map = Hash.new do |message|
        unless @connection.slog(:on_miscerr, @connection.log_params, "Received unknown frame type: '#{message.command}'\n")
          warn "Received unknown frame type: '#{message.command}'\n"
        end
      end

      @listener_map[Stomp::CMD_MESSAGE] = lambda {|message| find_listener(message) }
      @listener_map[Stomp::CMD_RECEIPT] = lambda {|message| find_receipt_listener(message) }
      @listener_map[Stomp::CMD_ERROR]   = @error_listener
    end

    # Start a single listener thread.  Misnamed I think.
    def start_listeners()
      create_listener_maps

      @listener_thread = Thread.start do
        loop do
          message = @connection.receive
          # AMQ specific behavior
          if message.nil? && (!@parameters[:reliable])
            raise Stomp::Error::NilMessageError
          end

          next unless message # message can be nil on rapid AMQ stop/start sequences

          @listener_map[message.command].call(message)
        end

      end
    end # method start_listeners

  end # class Client

end # module Stomp
