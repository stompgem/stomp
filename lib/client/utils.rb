# -*- encoding: utf-8 -*-

require 'thread'
require 'digest/sha1'

module Stomp

  class Client

    private

    def parse_hash_params(params)
      return false unless params.is_a?(Hash)

      @parameters = params
      @parameters[:reliable] = true

      true
    end

    def parse_stomp_url(login)
      regexp = /^stomp:\/\/#{URL_REPAT}/
      return false unless url = regexp.match(login)

      @parameters = { :reliable => false,
                      :hosts => [ { :login => url[3] || "",
                                    :passcode => url[4] || "",
                                    :host => url[5],
                                    :port => url[6].to_i} ] }
      true
    end

    # e.g. failover://(stomp://login1:passcode1@localhost:61616,stomp://login2:passcode2@remotehost:61617)?option1=param
    def parse_failover_url(login)
      rval = nil
      if md = FAILOVER_REGEX.match(login)
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

# Parse a stomp URL.
def parse_hosts(url)
  hosts = []
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
  hosts
end

    # A very basic check of required arguments.
    def check_arguments!()
      first_host = @parameters && @parameters[:hosts] && @parameters[:hosts].first

      raise ArgumentError if first_host.nil?
      raise ArgumentError if first_host[:host].nil? || first_host[:host].empty?
      raise ArgumentError if first_host[:port].nil? || first_host[:port] == '' || first_host[:port] < 1 || first_host[:port] > 65535
      raise ArgumentError unless @parameters[:reliable].is_a?(TrueClass) || @parameters[:reliable].is_a?(FalseClass)
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
          # AMQ specific behavior
          if message.nil? && (!@parameters[:reliable])
            raise Stomp::Error::NilMessageError
          end
          if message # message can be nil on rapid AMQ stop / start sequences
          # OK, we have some real data
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

