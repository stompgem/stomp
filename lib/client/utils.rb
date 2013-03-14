# -*- encoding: utf-8 -*-

require 'thread'
require 'digest/sha1'

module Stomp

  class Client

    private

    def parse_hash_params(params)
      return false unless params.is_a?(Hash)

      @parameters = params
      first_host = @parameters[:hosts][0]
      @login = first_host[:login]
      @passcode = first_host[:passcode]
      @host = first_host[:host]
      @port = first_host[:port] || Connection::default_port(first_host[:ssl])
      @reliable = true
      true
    end
    private :parse_hash_params

    def parse_stomp_url(login)
      regexp = /^stomp:\/\/#{url_regex}/ # e.g. stomp://login:passcode@host:port or stomp://host:port
      return false unless login =~ regexp

      @login = $2 || ""
      @passcode = $3 || ""
      @host = $4
      @port = $5.to_i
      @reliable = false
      true
    end
    private :parse_stomp_url

    # e.g. failover://(stomp://login1:passcode1@localhost:61616,stomp://login2:passcode2@remotehost:61617)?option1=param
    def parse_failover_url(login)
      regexp = /^failover:(\/\/)?\(stomp(\+ssl)?:\/\/#{url_regex}(,stomp(\+ssl)?:\/\/#{url_regex}\))+(\?(.*))?$/
      return false unless login =~ regexp

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
      true
    end
    private :parse_failover_url

    def parse_positional_params(login, passcode, host, port, reliable)
      @login = login
      @passcode = passcode
      @host = host
      @port = port.to_i
      @reliable = reliable
      true
    end
    private :parse_positional_params

    # Set a subscription id in the headers hash if one does not already exist.
    # For simplicities sake, all subscriptions have a subscription ID.
    # setting an id in the SUBSCRIPTION header is described in the stomp protocol docs:
    # http://stomp.github.com/
    def set_subscription_id_if_missing(destination, headers)
      headers[:id] = headers[:id] ? headers[:id] : headers['id']
      if headers[:id] == nil
        headers[:id] = Digest::SHA1.hexdigest(destination)
      end
    end

    # Register a receipt listener.
    def register_receipt_listener(listener)
      id = -1
      @id_mutex.synchronize do
        id = @ids.to_s
        @ids = @ids.succ
      end
      @receipt_listeners[id] = listener
      id
    end

    # url_regex defines a regex for e.g. login:passcode@host:port or host:port
    def url_regex
      '(([\w\.\-]*):(\w*)@)?([\w\.\-]+):(\d+)'
    end

    # Parse a stomp URL.
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

    # A very basic check of required arguments.
    def check_arguments!()
      raise ArgumentError if @host.nil? || @host.empty?
      raise ArgumentError if @port.nil? || @port == '' || @port < 1 || @port > 65535
      raise ArgumentError unless @reliable.is_a?(TrueClass) || @reliable.is_a?(FalseClass)
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
      @listeners[subscription_id]
    end

    # Start a single listener thread.  Misnamed I think.
    def start_listeners()
      @listeners = {}
      @receipt_listeners = {}
      @replay_messages_by_txn = {}

      @listener_thread = Thread.start do
        while true
          message = @connection.receive
          if message # AMQ specific?, nil message on multiple reconnects
            if message.command == Stomp::CMD_MESSAGE
              if listener = find_listener(message)
                listener.call(message)
              end
            elsif message.command == Stomp::CMD_RECEIPT
              if listener = @receipt_listeners[message.headers['receipt-id']]
                listener.call(message)
              end
            end
          end
        end # while true
      end
    end # method start_listeners

  end # class Client

end # module Stomp

