# -*- encoding: utf-8 -*-

require 'socket'
require 'timeout'
require 'io/wait'
require 'digest/sha1'

module Stomp

  # Low level connection which maps commands and supports
  # synchronous receives
  class Connection

    public

    # The CONNECTED frame from the broker.
    attr_reader   :connection_frame

    # Any disconnect RECEIPT frame if requested.
    attr_reader   :disconnect_receipt

    # The Stomp Protocol version.
    attr_reader   :protocol

    # A unique session ID, assigned by the broker.
    attr_reader   :session

    # Heartbeat receive has been on time.
    attr_reader   :hb_received # Heartbeat received on time

    # Heartbeat send has been successful.
    attr_reader   :hb_sent # Heartbeat sent successfully

    # JRuby detected
    attr_reader   :jruby

    # Autoflush forces a flush on each transmit.  This may be changed
    # dynamically by calling code.
    attr_accessor :autoflush

    # Currently-connected host and port
    attr_reader :host, :port

    # default_port returns the default port used by the gem for TCP or SSL.
    def self.default_port(ssl)
      ssl ? 61612 : 61613
    end

    # A new Connection object can be initialized using two forms:
    #
    # Hash (this is the recommended Connection initialization method):
    #
    #   hash = {
    #     :hosts => [
    #       {:login => "login1", :passcode => "passcode1", :host => "localhost", :port => 61616, :ssl => false},
    #       {:login => "login2", :passcode => "passcode2", :host => "remotehost", :port => 61617, :ssl => false}
    #     ],
    #     :reliable => true,
    #     :initial_reconnect_delay => 0.01,
    #     :max_reconnect_delay => 30.0,
    #     :use_exponential_back_off => true,
    #     :back_off_multiplier => 2,
    #     :max_reconnect_attempts => 0,
    #     :randomize => false,
    #     :connect_timeout => 0,
    #     :connect_headers => {},
    #     :parse_timeout => 5,
    #     :logger => nil,
    #     :dmh => false,
    #     :closed_check => true,
    #     :hbser => false,
    #     :stompconn => false,
    #     :usecrlf => false,
    #     :max_hbread_fails => 0,
    #     :max_hbrlck_fails => 0,
    #     :fast_hbs_adjust => 0.0,
    #     :connread_timeout => 0,
    #   }
    #
    #   e.g. c = Stomp::Connection.new(hash)
    #
    # Positional parameters:
    #
    #   login             (String,  default : '')
    #   passcode          (String,  default : '')
    #   host              (String,  default : 'localhost')
    #   port              (Integer, default : 61613)
    #   reliable          (Boolean, default : false)
    #   reconnect_delay   (Integer, default : 5)
    #
    #   e.g. c = Stomp::Connection.new("username", "password", "localhost", 61613, true)
    #
    def initialize(login = '', passcode = '', host = 'localhost', port = 61613, reliable = false, reconnect_delay = 5, connect_headers = {})
      @protocol = Stomp::SPL_10 # Assumed at first
      @hb_received = true       # Assumed at first
      @hb_sent = true           # Assumed at first
      @hbs = @hbr = false       # Sending/Receiving heartbeats. Assume no for now.
      @jruby = false            # Assumed at first
      if defined?(RUBY_ENGINE) && RUBY_ENGINE =~ /jruby/
        @jruby = true
      end
      if login.is_a?(Hash)
        hashed_initialize(login)
      else
        @host = host
        @port = port
        @login = login
        @passcode = passcode
        @reliable = reliable
        @reconnect_delay = reconnect_delay
        @connect_headers = connect_headers
        @ssl = false
        @parameters = nil
        @parse_timeout = 5		# To override, use hashed parameters
        @connect_timeout = 0	# To override, use hashed parameters
        @logger = nil     		# To override, use hashed parameters
        @autoflush = false    # To override, use hashed parameters or setter
        @closed_check = true  # Run closed check in each protocol method
        @hbser = false        # Raise if heartbeat send exception
        @stompconn = false    # If true, use STOMP rather than CONNECT
        @usecrlf = false      # If true, use \r\n as line ends (1.2 only)
        @max_hbread_fails = 0 # 0 means never retry for HB read failures
        @max_hbrlck_fails = 0 # 0 means never retry for HB read lock failures
        @fast_hbs_adjust = 0.0 # Fast heartbeat senders sleep adjustment
        @connread_timeout = 0 # Connect read CONNECTED/ERROR timeout
        warn "login looks like a URL, do you have the correct parameters?" if @login =~ /:\/\//
      end

      # Use Mutexes:  only one lock per each thread.
      # Reverted to original implementation attempt using Mutex.
      @transmit_semaphore = Mutex.new
      @read_semaphore = Mutex.new
      @socket_semaphore = Mutex.new

      @subscriptions = {}
      @failure = nil
      @connection_attempts = 0

      socket
    end

    # hashed_initialize prepares a new connection with a Hash of initialization
    # parameters.
    def hashed_initialize(params)

      @parameters = refine_params(params)
      @reliable =  @parameters[:reliable]
      @reconnect_delay = @parameters[:initial_reconnect_delay]
      @connect_headers = @parameters[:connect_headers]
      @parse_timeout =  @parameters[:parse_timeout]
      @connect_timeout =  @parameters[:connect_timeout]
      @logger =  @parameters[:logger]
      @autoflush = @parameters[:autoflush]
      @closed_check = @parameters[:closed_check]
      @hbser = @parameters[:hbser]
      @stompconn = @parameters[:stompconn]
      @usecrlf = @parameters[:usecrlf]
      @max_hbread_fails = @parameters[:max_hbread_fails]
      @max_hbrlck_fails = @parameters[:max_hbrlck_fails]
      @fast_hbs_adjust = @parameters[:fast_hbs_adjust]
      @connread_timeout = @parameters[:connread_timeout]
      #sets the first host to connect
      change_host
    end

    # open is syntactic sugar for 'Connection.new', see 'initialize' for usage.
    def Connection.open(login = '', passcode = '', host = 'localhost', port = 61613, reliable = false, reconnect_delay = 5, connect_headers = {})
      Connection.new(login, passcode, host, port, reliable, reconnect_delay, connect_headers)
    end

    # open? tests if this connection is open.
    def open?
      !@closed
    end

    # closed? tests if this connection is closed.
    def closed?
      @closed
    end

    # Begin starts a transaction, and requires a name for the transaction
    def begin(name, headers = {})
      raise Stomp::Error::NoCurrentConnection if @closed_check && closed?
      headers = headers.symbolize_keys
      headers[:transaction] = name
      _headerCheck(headers)
      if @logger && @logger.respond_to?(:on_begin)
        @logger.on_begin(log_params, headers)
      end
      transmit(Stomp::CMD_BEGIN, headers)
    end

    # Acknowledge a message, used when a subscription has specified
    # client acknowledgement i.e. connection.subscribe("/queue/a", :ack => 'client').
    # Accepts an optional transaction header ( :transaction => 'some_transaction_id' )
    # Behavior is protocol level dependent, see the specifications or comments below.
    def ack(message_id, headers = {})
      raise Stomp::Error::NoCurrentConnection if @closed_check && closed?
      raise Stomp::Error::MessageIDRequiredError if message_id.nil? || message_id == ""
      headers = headers.symbolize_keys

      case @protocol
        when Stomp::SPL_12
          # The ACK frame MUST include an id header matching the ack header 
          # of the MESSAGE being acknowledged.
          headers[:id] = message_id
        when Stomp::SPL_11
          # ACK has two REQUIRED headers: message-id, which MUST contain a value 
          # matching the message-id for the MESSAGE being acknowledged and 
          # subscription, which MUST be set to match the value of the subscription's 
          # id header.
          headers[:'message-id'] = message_id
          raise Stomp::Error::SubscriptionRequiredError unless headers[:subscription]
        else # Stomp::SPL_10
          # ACK has one required header, message-id, which must contain a value 
          # matching the message-id for the MESSAGE being acknowledged.
          headers[:'message-id'] = message_id
      end
      _headerCheck(headers)
      if @logger && @logger.respond_to?(:on_ack)
        @logger.on_ack(log_params, headers)
      end
      transmit(Stomp::CMD_ACK, headers)
    end

    # STOMP 1.1+ NACK.
    def nack(message_id, headers = {})
      raise Stomp::Error::NoCurrentConnection if @closed_check && closed?
      raise Stomp::Error::UnsupportedProtocolError if @protocol == Stomp::SPL_10
      raise Stomp::Error::MessageIDRequiredError if message_id.nil? || message_id == ""
      headers = headers.symbolize_keys
      case @protocol
        when Stomp::SPL_12
          # The ACK frame MUST include an id header matching the ack header 
          # of the MESSAGE being acknowledged.
          headers[:id] = message_id
        else # Stomp::SPL_11 only
          # ACK has two REQUIRED headers: message-id, which MUST contain a value 
          # matching the message-id for the MESSAGE being acknowledged and 
          # subscription, which MUST be set to match the value of the subscription's 
          # id header.
          headers[:'message-id'] = message_id
          raise Stomp::Error::SubscriptionRequiredError unless headers[:subscription]
      end
      _headerCheck(headers)
      if @logger && @logger.respond_to?(:on_nack)
        @logger.on_nack(log_params, headers)
      end
      transmit(Stomp::CMD_NACK, headers)
    end

    # Commit commits a transaction by name.
    def commit(name, headers = {})
      raise Stomp::Error::NoCurrentConnection if @closed_check && closed?
      headers = headers.symbolize_keys
      headers[:transaction] = name
      _headerCheck(headers)
      if @logger && @logger.respond_to?(:on_commit)
        @logger.on_commit(log_params, headers)
      end
      transmit(Stomp::CMD_COMMIT, headers)
    end

    # Abort aborts a transaction by name.
    def abort(name, headers = {})
      raise Stomp::Error::NoCurrentConnection if @closed_check && closed?
      headers = headers.symbolize_keys
      headers[:transaction] = name
      _headerCheck(headers)
      if @logger && @logger.respond_to?(:on_abort)
        @logger.on_abort(log_params, headers)
      end
      transmit(Stomp::CMD_ABORT, headers)
    end

    # Subscribe subscribes to a destination.  A subscription name is required.
    # For Stomp 1.1+ a session unique subscription ID is also required.
    def subscribe(name, headers = {}, subId = nil)
      raise Stomp::Error::NoCurrentConnection if @closed_check && closed?
      headers = headers.symbolize_keys
      headers[:destination] = name
      if @protocol >= Stomp::SPL_11
        raise Stomp::Error::SubscriptionRequiredError if (headers[:id].nil? && subId.nil?)
        headers[:id] = subId if headers[:id].nil?
      end
      _headerCheck(headers)
      if @logger && @logger.respond_to?(:on_subscribe)
        @logger.on_subscribe(log_params, headers)
      end

      # Store the subscription so that we can replay if we reconnect.
      if @reliable
        subId = name if subId.nil?
        raise Stomp::Error::DuplicateSubscription if @subscriptions[subId]
        @subscriptions[subId] = headers
      end

      transmit(Stomp::CMD_SUBSCRIBE, headers)
    end

    # Unsubscribe from a destination.   A subscription name is required.
    # For Stomp 1.1+ a session unique subscription ID is also required.
    def unsubscribe(dest, headers = {}, subId = nil)
      raise Stomp::Error::NoCurrentConnection if @closed_check && closed?
      headers = headers.symbolize_keys
      headers[:destination] = dest
      if @protocol >= Stomp::SPL_11
        raise Stomp::Error::SubscriptionRequiredError if (headers[:id].nil? && subId.nil?)
        headers[:id] = subId unless headers[:id]
      end
      _headerCheck(headers)
      if @logger && @logger.respond_to?(:on_unsubscribe)
        @logger.on_unsubscribe(log_params, headers)
      end
      transmit(Stomp::CMD_UNSUBSCRIBE, headers)
      if @reliable
        subId = dest if subId.nil?
        @subscriptions.delete(subId)
      end
    end

    # Publish message to destination.
    # To disable content length header use header ( :suppress_content_length => true ).
    # Accepts a transaction header ( :transaction => 'some_transaction_id' ).
    def publish(destination, message, headers = {})
      raise Stomp::Error::NoCurrentConnection if @closed_check && closed?
      headers = headers.symbolize_keys
      headers[:destination] = destination
      _headerCheck(headers)
      if @logger && @logger.respond_to?(:on_publish)
        @logger.on_publish(log_params, message, headers)
      end
      transmit(Stomp::CMD_SEND, headers, message)
    end

    # Send a message back to the source or to the dead letter queue.
    # Accepts a dead letter queue option ( :dead_letter_queue => "/queue/DLQ" ).
    # Accepts a limit number of redeliveries option ( :max_redeliveries => 6 ).
    # Accepts a force client acknowledgement option (:force_client_ack => true).
    def unreceive(message, options = {})
      raise Stomp::Error::NoCurrentConnection if @closed_check && closed?
      options = { :dead_letter_queue => "/queue/DLQ", :max_redeliveries => 6 }.merge(options)
      # Lets make sure all keys are symbols
      message.headers = message.headers.symbolize_keys
      retry_count = message.headers[:retry_count].to_i || 0
      message.headers[:retry_count] = retry_count + 1
      transaction_id = "transaction-#{message.headers[:'message-id']}-#{retry_count}"
      message_id = message.headers.delete(:'message-id')

      # Prevent duplicate 'subscription' headers on subsequent receives
      message.headers.delete(:subscription) if message.headers[:subscription]

      begin
        self.begin transaction_id

        if client_ack?(message) || options[:force_client_ack]
          self.ack(message_id, :transaction => transaction_id)
        end

        if message.headers[:retry_count] <= options[:max_redeliveries]
          self.publish(message.headers[:destination], message.body, 
            message.headers.merge(:transaction => transaction_id))
        else
          # Poison ack, sending the message to the DLQ
          self.publish(options[:dead_letter_queue], message.body, 
            message.headers.merge(:transaction => transaction_id, 
            :original_destination => message.headers[:destination], 
            :persistent => true))
        end
        self.commit transaction_id
      rescue Exception => exception
        self.abort transaction_id
        raise exception
      end
    end

    # client_ack? determines if headers contain :ack => "client".
    def client_ack?(message)
      headers = @subscriptions[message.headers[:destination]]
      !headers.nil? && headers[:ack] == "client"
    end

    # disconnect closes this connection.  If requested, a disconnect RECEIPT 
    # will be received.
    def disconnect(headers = {})
      raise Stomp::Error::NoCurrentConnection if @closed_check && closed?
      headers = headers.symbolize_keys
      _headerCheck(headers)
      if @protocol >= Stomp::SPL_11
        @st.kill if @st # Kill ticker thread if any
        @rt.kill if @rt # Kill ticker thread if any
      end
      transmit(Stomp::CMD_DISCONNECT, headers)
      @disconnect_receipt = receive if headers[:receipt]
      if @logger && @logger.respond_to?(:on_disconnect)
        @logger.on_disconnect(log_params)
      end
      close_socket
    end

    # poll returns a pending message if one is available, otherwise
    # returns nil.
    def poll()
      raise Stomp::Error::NoCurrentConnection if @closed_check && closed?
      # No need for a read lock here.  The receive method eventually fulfills
      # that requirement.
      return nil if @socket.nil? || !@socket.ready?
      receive()
    end

    # receive returns the next Message off of the wire.  this can return nil
    # in cases where:
    # * the broker has closed the connection
    # * the connection is not reliable
    def receive()
      raise Stomp::Error::NoCurrentConnection if @closed_check && closed?
      super_result = __old_receive()
      if super_result.nil? && @reliable && !closed?
        errstr = "connection.receive returning EOF as nil - resetting connection.\n"
        if @logger && @logger.respond_to?(:on_miscerr)
          @logger.on_miscerr(log_params, "es_recv: " + errstr)
        else
          $stderr.print errstr
        end
        # !!! This initiates a re-connect !!!
        # The call to __old_receive() will in turn call socket().  Before
        # that we should change the target host, otherwise the host that
        # just failed may be attempted first.
        _reconn_prep()
        #
        super_result = __old_receive()
      end
      #
      if super_result.nil? && !@reliable
        @st.kill if @st # Kill ticker thread if any
        @rt.kill if @rt # Kill ticker thread if any
        close_socket()
        @closed = true
        warn 'warning: broker sent EOF, and connection not reliable' unless defined?(Test)
      end
      if @logger && @logger.respond_to?(:on_receive)
        @logger.on_receive(log_params, super_result)
      end
      return super_result
    end

    # set_logger selects a new callback logger instance.
    def set_logger(logger)
      @logger = logger
    end

    # valid_utf8? returns an indicator if the given string is a valid UTF8 string.
    def valid_utf8?(s)
      case RUBY_VERSION
      when /1\.8/
        rv = _valid_utf8?(s)
      else
        rv = s.encoding.name != Stomp::UTF8 ? false : s.valid_encoding?
      end
      rv
    end

    # sha1 returns a SHA1 digest for arbitrary string data.
    def sha1(data)
      Digest::SHA1.hexdigest(data)
    end

    # uuid returns a type 4 UUID.
    def uuid()
      b = []
      0.upto(15) do |i|
        b << rand(255)
      end
      b[6] = (b[6] & 0x0F) | 0x40
      b[8] = (b[8] & 0xbf) | 0x80
      #             0  1  2  3   4   5  6  7   8  9  10 11 12 13 14 15
      rs = sprintf("%02x%02x%02x%02x-%02x%02x-%02x%02x-%02x%02x%02x%02x%02x%02x%02x%02x",
      b[0], b[1], b[2], b[3], b[4], b[5], b[6], b[7], b[8], b[9], b[10], b[11], b[12], b[13], b[14], b[15])
      rs
    end

    # hbsend_interval returns the connection's heartbeat send interval.
    def hbsend_interval()
      return 0 unless @hbsend_interval
      @hbsend_interval / 1000.0 # ms
    end

    # hbrecv_interval returns the connection's heartbeat receive interval.
    def hbrecv_interval()
      return 0 unless @hbrecv_interval
      @hbrecv_interval / 1000.0 # ms
    end

    # hbsend_count returns the current connection's heartbeat send count.
    def hbsend_count()
      return 0 unless @hbsend_count
      @hbsend_count
    end

    # hbrecv_count returns the current connection's heartbeat receive count.
    def hbrecv_count()
      return 0 unless @hbrecv_count
      @hbrecv_count
    end

  end # class

end # module

