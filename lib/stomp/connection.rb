# -*- encoding: utf-8 -*-

require 'socket'
require 'timeout'
require 'io/wait'
require 'digest/sha1'

module Stomp

  # Low level connection which maps commands and supports
  # synchronous receives
  class Connection
    attr_reader :connection_frame
    attr_reader :disconnect_receipt
    attr_reader :protocol
    attr_reader :session
    attr_reader :hb_received # Heartbeat received on time
    attr_reader :hb_sent # Heartbeat sent successfully
    #alias :obj_send :send

    def self.default_port(ssl)
      ssl ? 61612 : 61613
    end

    # A new Connection object accepts the following parameters:
    #
    #   login             (String,  default : '')
    #   passcode          (String,  default : '')
    #   host              (String,  default : 'localhost')
    #   port              (Integer, default : 61613)
    #   reliable          (Boolean, default : false)
    #   reconnect_delay   (Integer, default : 5)
    #
    #   e.g. c = Connection.new("username", "password", "localhost", 61613, true)
    #
    # Hash:
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
    #     :backup => false,
    #     :connect_timeout => 0,
    #     :connect_headers => {},
    #     :parse_timeout => 5,
    #     :logger => nil,
    #   }
    #
    #   e.g. c = Connection.new(hash)
    #
    # TODO
    # Stomp URL :
    #   A Stomp URL must begin with 'stomp://' and can be in one of the following forms:
    #
    #   stomp://host:port
    #   stomp://host.domain.tld:port
    #   stomp://user:pass@host:port
    #   stomp://user:pass@host.domain.tld:port
    #
    def initialize(login = '', passcode = '', host = 'localhost', port = 61613, reliable = false, reconnect_delay = 5, connect_headers = {})
      @received_messages = []
      @protocol = Stomp::SPL_10 # Assumed at first
      @hb_received = true # Assumed at first
      @hb_sent = true # Assumed at first
      @hbs = @hbr = false # Sending/Receiving heartbeats. Assume no for now.

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
      end

      # Use Mutexes:  only one lock per each thread
      # Revert to original implementation attempt
      @transmit_semaphore = Mutex.new
      @read_semaphore = Mutex.new
      @socket_semaphore = Mutex.new

      @subscriptions = {}
      @failure = nil
      @connection_attempts = 0

      socket
    end

    def hashed_initialize(params)

      @parameters = refine_params(params)
      @reliable =  @parameters[:reliable]
      @reconnect_delay = @parameters[:initial_reconnect_delay]
      @connect_headers = @parameters[:connect_headers]
      @parse_timeout =  @parameters[:parse_timeout]
      @connect_timeout =  @parameters[:connect_timeout]
      @logger =  @parameters[:logger]
      #sets the first host to connect
      change_host
    end

    # Syntactic sugar for 'Connection.new' See 'initialize' for usage.
    def Connection.open(login = '', passcode = '', host = 'localhost', port = 61613, reliable = false, reconnect_delay = 5, connect_headers = {})
      Connection.new(login, passcode, host, port, reliable, reconnect_delay, connect_headers)
    end

    def socket
      @socket_semaphore.synchronize do
        used_socket = @socket
        used_socket = nil if closed?

        while used_socket.nil? || !@failure.nil?
          @failure = nil
          begin
            used_socket = open_socket
            # Open complete

            connect(used_socket)
            if @logger && @logger.respond_to?(:on_connected)
              @logger.on_connected(log_params)
            end
            @connection_attempts = 0
          rescue
            @failure = $!
            used_socket = nil
            raise unless @reliable
            if @logger && @logger.respond_to?(:on_connectfail)
              @logger.on_connectfail(log_params)
            else
              $stderr.print "connect to #{@host} failed: #{$!} will retry(##{@connection_attempts}) in #{@reconnect_delay}\n"
            end
            raise Stomp::Error::MaxReconnectAttempts if max_reconnect_attempts?

            sleep(@reconnect_delay)

            @connection_attempts += 1

            if @parameters
              change_host
              increase_reconnect_delay
            end
          end
        end
        @socket = used_socket
      end
    end

    def refine_params(params)
      params = params.uncamelize_and_symbolize_keys

      default_params = {
        :connect_headers => {},
        :reliable => true,
        # Failover parameters
        :initial_reconnect_delay => 0.01,
        :max_reconnect_delay => 30.0,
        :use_exponential_back_off => true,
        :back_off_multiplier => 2,
        :max_reconnect_attempts => 0,
        :randomize => false,
        :backup => false,
        :connect_timeout => 0,
        # Parse Timeout
        :parse_timeout => 5
      }

      default_params.merge(params)

    end

    def change_host
      @parameters[:hosts] = @parameters[:hosts].sort_by { rand } if @parameters[:randomize]

      # Set first as master and send it to the end of array
      current_host = @parameters[:hosts].shift
      @parameters[:hosts] << current_host

      @ssl = current_host[:ssl]
      @host = current_host[:host]
      @port = current_host[:port] || Connection::default_port(@ssl)
      @login = current_host[:login] || ""
      @passcode = current_host[:passcode] || ""

    end

    def max_reconnect_attempts?
      !(@parameters.nil? || @parameters[:max_reconnect_attempts].nil?) && @parameters[:max_reconnect_attempts] != 0 && @connection_attempts >= @parameters[:max_reconnect_attempts]
    end

    def increase_reconnect_delay

      @reconnect_delay *= @parameters[:back_off_multiplier] if @parameters[:use_exponential_back_off]
      @reconnect_delay = @parameters[:max_reconnect_delay] if @reconnect_delay > @parameters[:max_reconnect_delay]

      @reconnect_delay
    end

    # Is this connection open?
    def open?
      !@closed
    end

    # Is this connection closed?
    def closed?
      @closed
    end

    # Begin a transaction, requires a name for the transaction
    def begin(name, headers = {})
      raise Stomp::Error::NoCurrentConnection if closed?
      headers = headers.symbolize_keys
      headers[:transaction] = name
      _headerCheck(headers)
      transmit(Stomp::CMD_BEGIN, headers)
    end

    # Acknowledge a message, used when a subscription has specified
    # client acknowledgement ( connection.subscribe "/queue/a", :ack => 'client'g
    #
    # Accepts a transaction header ( :transaction => 'some_transaction_id' )
    def ack(message_id, headers = {})
      raise Stomp::Error::NoCurrentConnection if closed?
      raise Stomp::Error::MessageIDRequiredError if message_id.nil? || message_id == ""
      headers = headers.symbolize_keys
      headers[:'message-id'] = message_id
      if @protocol >= Stomp::SPL_11
        raise Stomp::Error::SubscriptionRequiredError unless headers[:subscription]
      end
      _headerCheck(headers)
      transmit(Stomp::CMD_ACK, headers)
    end

    # STOMP 1.1+ NACK
    def nack(message_id, headers = {})
      raise Stomp::Error::NoCurrentConnection if closed?
      raise Stomp::Error::UnsupportedProtocolError if @protocol == Stomp::SPL_10
      raise Stomp::Error::MessageIDRequiredError if message_id.nil? || message_id == ""
      headers = headers.symbolize_keys
      headers[:'message-id'] = message_id
      raise Stomp::Error::SubscriptionRequiredError unless headers[:subscription]
      _headerCheck(headers)
      transmit(Stomp::CMD_NACK, headers)
    end

    # Commit a transaction by name
    def commit(name, headers = {})
      raise Stomp::Error::NoCurrentConnection if closed?
      headers = headers.symbolize_keys
      headers[:transaction] = name
      _headerCheck(headers)
      transmit(Stomp::CMD_COMMIT, headers)
    end

    # Abort a transaction by name
    def abort(name, headers = {})
      raise Stomp::Error::NoCurrentConnection if closed?
      headers = headers.symbolize_keys
      headers[:transaction] = name
      _headerCheck(headers)
      transmit(Stomp::CMD_ABORT, headers)
    end

    # Subscribe to a destination, must specify a name
    def subscribe(name, headers = {}, subId = nil)
      raise Stomp::Error::NoCurrentConnection if closed?
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

      # Store the sub so that we can replay if we reconnect.
      if @reliable
        subId = name if subId.nil?
        raise Stomp::Error::DuplicateSubscription if @subscriptions[subId]
        @subscriptions[subId] = headers
      end

      transmit(Stomp::CMD_SUBSCRIBE, headers)
    end

    # Unsubscribe from a destination, which must be specified
    def unsubscribe(dest, headers = {}, subId = nil)
      raise Stomp::Error::NoCurrentConnection if closed?
      headers = headers.symbolize_keys
      headers[:destination] = dest
      if @protocol >= Stomp::SPL_11
        raise Stomp::Error::SubscriptionRequiredError if (headers[:id].nil? && subId.nil?)
      end
      _headerCheck(headers)
      transmit(Stomp::CMD_UNSUBSCRIBE, headers)
      if @reliable
        subId = dest if subId.nil?
        @subscriptions.delete(subId)
      end
    end

    # Publish message to destination
    #
    # To disable content length header ( :suppress_content_length => true )
    # Accepts a transaction header ( :transaction => 'some_transaction_id' )
    def publish(destination, message, headers = {})
      raise Stomp::Error::NoCurrentConnection if closed?
      headers = headers.symbolize_keys
      headers[:destination] = destination
      _headerCheck(headers)
      if @logger && @logger.respond_to?(:on_publish)
        @logger.on_publish(log_params, message, headers)
      end
      transmit(Stomp::CMD_SEND, headers, message)
    end

    def obj_send(*args)
      __send__(*args)
    end

    # Send a message back to the source or to the dead letter queue
    #
    # Accepts a dead letter queue option ( :dead_letter_queue => "/queue/DLQ" )
    # Accepts a limit number of redeliveries option ( :max_redeliveries => 6 )
    # Accepts a force client acknowledgement option (:force_client_ack => true)
    def unreceive(message, options = {})
      raise Stomp::Error::NoCurrentConnection if closed?
      options = { :dead_letter_queue => "/queue/DLQ", :max_redeliveries => 6 }.merge options
      # Lets make sure all keys are symbols
      message.headers = message.headers.symbolize_keys

      retry_count = message.headers[:retry_count].to_i || 0
      message.headers[:retry_count] = retry_count + 1
      transaction_id = "transaction-#{message.headers[:'message-id']}-#{retry_count}"
      message_id = message.headers.delete(:'message-id')

      begin
        self.begin transaction_id

        if client_ack?(message) || options[:force_client_ack]
          self.ack(message_id, :transaction => transaction_id)
        end

        if retry_count <= options[:max_redeliveries]
          self.publish(message.headers[:destination], message.body, message.headers.merge(:transaction => transaction_id))
        else
          # Poison ack, sending the message to the DLQ
          self.publish(options[:dead_letter_queue], message.body, message.headers.merge(:transaction => transaction_id, :original_destination => message.headers[:destination], :persistent => true))
        end
        self.commit transaction_id
      rescue Exception => exception
        self.abort transaction_id
        raise exception
      end
    end

    def client_ack?(message)
      headers = @subscriptions[message.headers[:destination]]
      !headers.nil? && headers[:ack] == "client"
    end

    # Close this connection
    def disconnect(headers = {})
      raise Stomp::Error::NoCurrentConnection if closed?
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

    # Return a pending message if one is available, otherwise
    # return nil
    def poll
      raise Stomp::Error::NoCurrentConnection if closed?
      # No need for a read lock here.  The receive method eventually fulfills
      # that requirement.
      return nil if @socket.nil? || !@socket.ready?
      receive
    end

    # Receive a frame, block until the frame is received
    def __old_receive
      # The receive may fail so we may need to retry.
      while TRUE
        begin
          used_socket = socket
          return _receive(used_socket)
        rescue
          @failure = $!
          raise unless @reliable
          errstr = "receive failed: #{$!}"
          if @logger && @logger.respond_to?(:on_miscerr)
            @logger.on_miscerr(log_params, errstr)
          else
            $stderr.print errstr
          end
        end
      end
    end

    def receive
      raise Stomp::Error::NoCurrentConnection if closed?
      super_result = __old_receive
      if super_result.nil? && @reliable && !closed?
        errstr = "connection.receive returning EOF as nil - resetting connection.\n"
        if @logger && @logger.respond_to?(:on_miscerr)
          @logger.on_miscerr(log_params, errstr)
        else
          $stderr.print errstr
        end
        @socket = nil
        super_result = __old_receive
      end
      #
      if @logger && @logger.respond_to?(:on_receive)
        @logger.on_receive(log_params, super_result)
      end
      return super_result
    end

    # Convenience method
    def set_logger(logger)
      @logger = logger
    end

    # Convenience method
    def valid_utf8?(s)
      case RUBY_VERSION
        when /1\.8/
          rv = _valid_utf8?(s)
        else
          rv = s.encoding.name != Stomp::UTF8 ? false : s.valid_encoding?
      end
      rv
    end

    # Convenience method for clients, return a SHA1 digest for arbitrary data
    def sha1(data)
      Digest::SHA1.hexdigest(data)
    end

    # Convenience method for clients, return a type 4 UUID.
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

    private

      def _receive( read_socket )
        @read_semaphore.synchronize do
          line = read_socket.gets
          return nil if line.nil?
          # If the reading hangs for more than X seconds, abort the parsing process.
          # X defaults to 5.  Override allowed in connection hash parameters.
          Timeout::timeout(@parse_timeout, Stomp::Error::PacketParsingTimeout) do
            # Reads the beginning of the message until it runs into a empty line
            message_header = ''
            begin
              message_header += line
              line = read_socket.gets
            end until line =~ /^\s?\n$/

            # Checks if it includes content_length header
            content_length = message_header.match /content-length\s?:\s?(\d+)\s?\n/
            message_body = ''

            # If it does, reads the specified amount of bytes
            char = ''
            if content_length
              message_body = read_socket.read content_length[1].to_i
              raise Stomp::Error::InvalidMessageLength unless parse_char(read_socket.getc) == "\0"
            # Else reads, the rest of the message until the first \0
            else
              message_body += char while (char = parse_char(read_socket.getc)) != "\0"
            end

            # If the buffer isn't empty, reads trailing new lines.
            #
            # Note: experiments with JRuby seem to show that .ready? never
            # returns true.  This means that this code to drain trailing new
            # lines never runs using JRuby.
            #
            # Note 2: the draining of new lines mmust be done _after_ a message
            # is read.  Do _not_ leave them on the wire and attempt to drain them
            # at the start of the next read.  Attempting to do that breaks the
            # asynchronous nature of the 'poll' method.
            while read_socket.ready?
              last_char = read_socket.getc
              break unless last_char
              if parse_char(last_char) != "\n"
                read_socket.ungetc(last_char)
                break
              end
            end
            # And so, a JRuby hack.  Remove any new lines at the start of the
            # next buffer.
            message_header.gsub!(/^\n?/, "")

            if @protocol >= Stomp::SPL_11
              @lr = Time.now.to_f if @hbr
            end
            # Adds the excluded \n and \0 and tries to create a new message with it
            msg = Message.new(message_header + "\n" + message_body + "\0", @protocol >= Stomp::SPL_11)
            #
            if @protocol >= Stomp::SPL_11 && msg.command != Stomp::CMD_CONNECTED
              msg.headers = _decodeHeaders(msg.headers)
            end
            msg
          end
        end
      end

      def parse_char(char)
        RUBY_VERSION > '1.9' ? char : char.chr
      end

      def transmit(command, headers = {}, body = '')
        # The transmit may fail so we may need to retry.
        while TRUE
          begin
            used_socket = socket
            _transmit(used_socket, command, headers, body)
            return
          rescue Stomp::Error::MaxReconnectAttempts => e
              raise
          rescue
            @failure = $!
            raise unless @reliable
            errstr = "transmit to #{@host} failed: #{$!}\n"
            if @logger && @logger.respond_to?(:on_miscerr)
              @logger.on_miscerr(log_params, errstr)
            else
              $stderr.print errstr
            end
          end
        end
      end

      def _transmit(used_socket, command, headers = {}, body = '')
        if @protocol >= Stomp::SPL_11 && command != Stomp::CMD_CONNECT
          headers = _encodeHeaders(headers)
        end
        @transmit_semaphore.synchronize do
          # Handle nil body
          body = '' if body.nil?
          # The content-length should be expressed in bytes.
          # Ruby 1.8: String#length => # of bytes; Ruby 1.9: String#length => # of characters
          # With Unicode strings, # of bytes != # of characters.  So, use String#bytesize when available.
          body_length_bytes = body.respond_to?(:bytesize) ? body.bytesize : body.length

          # ActiveMQ interprets every message as a BinaryMessage
          # if content_length header is included.
          # Using :suppress_content_length => true will suppress this behaviour
          # and ActiveMQ will interpret the message as a TextMessage.
          # For more information refer to http://juretta.com/log/2009/05/24/activemq-jms-stomp/
          # Lets send this header in the message, so it can maintain state when using unreceive
          headers['content-length'] = "#{body_length_bytes}" unless headers[:suppress_content_length]
          headers['content-type'] = "text/plain; charset=UTF-8" unless headers['content-type']
          used_socket.puts command
          headers.each do |k,v|
            if v.is_a?(Array)
              v.each do |e|
                used_socket.puts "#{k}:#{e}"
              end
            else
              used_socket.puts "#{k}:#{v}"
            end
          end
          used_socket.puts
          used_socket.write body
          used_socket.write "\0"

          if @protocol >= Stomp::SPL_11
            @ls = Time.now.to_f if @hbs
          end

        end
      end

      def open_tcp_socket
      	tcp_socket = nil

        if @logger && @logger.respond_to?(:on_connecting)
          @logger.on_connecting(log_params)
        end

      	Timeout::timeout(@connect_timeout, Stomp::Error::SocketOpenTimeout) do
        	tcp_socket = TCPSocket.open @host, @port
      	end

        tcp_socket
      end

      def open_ssl_socket
        require 'openssl' unless defined?(OpenSSL)
        ctx = OpenSSL::SSL::SSLContext.new
        ctx.verify_mode = OpenSSL::SSL::VERIFY_NONE # Assume for now

        #
        # Here @ssl is either:
        # * true - and no authentication either way is required
        # * an instance of Stomp::SSLParams
        # Control would not be here if @ssl == false or @ssl.nil?.
        #
        if @ssl != true # SSLParams

          # Server authentication parameters if required
          if @ssl.ts_files
            ctx.verify_mode = OpenSSL::SSL::VERIFY_PEER
            truststores = OpenSSL::X509::Store.new
            fl = @ssl.ts_files.split(",")
            fl.each do |fn|
              # Add next cert file listed
              truststores.add_file(fn)
            end
            ctx.cert_store = truststores
          end

          # Client authentication parameters
          # Both must be present or not, can not be a mix
          raise Stomp::Error::SSLClientParamsError if @ssl.cert_file.nil? && !@ssl.key_file.nil?
          raise Stomp::Error::SSLClientParamsError if !@ssl.cert_file.nil? && @ssl.key_file.nil?
          if @ssl.cert_file # Any check will do here
            ctx.cert = OpenSSL::X509::Certificate.new(File.open(@ssl.cert_file))
            ctx.key  = OpenSSL::PKey::RSA.new(File.open(@ssl.key_file))
          end
        end

        #
      	ssl = nil

      	Timeout::timeout(@connect_timeout, Stomp::Error::SocketOpenTimeout) do
        	ssl = OpenSSL::SSL::SSLSocket.new(open_tcp_socket, ctx)
      	end
        def ssl.ready?
          ! @rbuffer.empty? || @io.ready?
        end
        ssl.connect
        if @ssl != true
          # Pass back results if possible
          if RUBY_VERSION =~ /1\.8\.[56]/
            @ssl.verify_result = "N/A for Ruby #{RUBY_VERSION}"
          else
            @ssl.verify_result = ssl.verify_result
          end
          @ssl.peer_cert = ssl.peer_cert
        end
        ssl
      end

      def close_socket
        begin
          # Need to set @closed = true before closing the socket
          # within the @read_semaphore thread
          @closed = true
          @read_semaphore.synchronize do
            @socket.close
          end
        rescue
          #Ignoring if already closed
        end
        @closed
      end

      def open_socket
        used_socket = @ssl ? open_ssl_socket : open_tcp_socket
        # try to close the old connection if any
        close_socket

        @closed = false
        # Use keepalive
        used_socket.setsockopt(Socket::SOL_SOCKET, Socket::SO_KEEPALIVE, true)
        used_socket
      end

      def connect(used_socket)
        @connect_headers = {} unless @connect_headers # Caller said nil/false
        headers = @connect_headers.clone
        headers[:login] = @login
        headers[:passcode] = @passcode
        _pre_connect
        _transmit(used_socket, "CONNECT", headers)
        @connection_frame = _receive(used_socket)
        _post_connect
        @disconnect_receipt = nil
        @session = @connection_frame.headers["session"] if @connection_frame
        # replay any subscriptions.
        @subscriptions.each { |k,v| _transmit(used_socket, Stomp::CMD_SUBSCRIBE, v) }
      end

      def log_params
        lparms = @parameters.clone if @parameters
        lparms = {} unless lparms
        lparms[:cur_host] = @host
        lparms[:cur_port] = @port
        lparms[:cur_login] = @login
        lparms[:cur_passcode] = @passcode
        lparms[:cur_ssl] = @ssl
        lparms[:cur_recondelay] = @reconnect_delay
        lparms[:cur_parseto] = @parse_timeout
        lparms[:cur_conattempts] = @connection_attempts
        #
        lparms
      end

      def _pre_connect
        @connect_headers = @connect_headers.symbolize_keys
        raise Stomp::Error::ProtocolErrorConnect if (@connect_headers[:"accept-version"] && !@connect_headers[:host])
        raise Stomp::Error::ProtocolErrorConnect if (!@connect_headers[:"accept-version"] && @connect_headers[:host])
        return unless (@connect_headers[:"accept-version"] && @connect_headers[:host]) # 1.0
        # Try 1.1 or greater
        okvers = []
        avers = @connect_headers[:"accept-version"].split(",")
        avers.each do |nver|
          if Stomp::SUPPORTED.index(nver)
            okvers << nver
          end
        end
        raise Stomp::Error::UnsupportedProtocolError if okvers == []
        @connect_headers[:"accept-version"] = okvers.join(",") # This goes to server
        # Heartbeats - pre connect
        return unless @connect_headers[:"heart-beat"]
        _validate_hbheader()
      end

      def _post_connect
        return unless (@connect_headers[:"accept-version"] && @connect_headers[:host])
        return if @connection_frame.command == Stomp::CMD_ERROR
        cfh = @connection_frame.headers.symbolize_keys
        @protocol = cfh[:version]
        # Should not happen, but check anyway
        raise Stomp::Error::UnsupportedProtocolError unless Stomp::SUPPORTED.index(@protocol)
        # Heartbeats
        return unless @connect_headers[:"heart-beat"]
        _init_heartbeats()
      end

      def _validate_hbheader()
        return if @connect_headers[:"heart-beat"] == "0,0" # Caller does not want heartbeats.  OK.
        parts = @connect_headers[:"heart-beat"].split(",")
        if (parts.size != 2) || (parts[0] != parts[0].to_i.to_s) || (parts[1] != parts[1].to_i.to_s)
          raise Stomp::Error::InvalidHeartBeatHeaderError
        end
      end

      def _init_heartbeats()
        return if @connect_headers[:"heart-beat"] == "0,0" # Caller does not want heartbeats.  OK.
        #
        @cx = @cy = @sx = @sy = 0, # Variable names as in spec
        #
        @sti = @rti = 0.0 # Send/Receive ticker interval.
        #
        @ls = @lr = -1.0 # Last send/receive time (from Time.now.to_f)
        #
        @st = @rt = nil # Send/receive ticker thread
        #
        cfh = @connection_frame.headers.symbolize_keys
        return if cfh[:"heart-beat"] == "0,0" # Server does not want heartbeats
        #
        parts = @connect_headers[:"heart-beat"].split(",")
        @cx = parts[0].to_i
        @cy = parts[1].to_i
        #
        parts = cfh[:"heart-beat"].split(",")
        @sx = parts[0].to_i
        @sy = parts[1].to_i
        # Catch odd situations like someone has used => heart-beat:000,00000
        return if (@cx == 0 && @cy == 0) || (@sx == 0 && @sy == 0)
        #
        @hbs = @hbr = true # Sending/Receiving heartbeats. Assume yes at first.
        # Check for sending
        @hbs = false if @cx == 0 || @sy == 0
        # Check for receiving
        @hbr = false if @sx == 0 || @cy == 0
        # Should not do heartbeats at all
        return if (!@hbs && !@hbr)
        # If sending
        if @hbs
          sm = @cx >= @sy ? @cx : @sy # ticker interval, ms
          @sti = 1000.0 * sm # ticker interval, μs
          @ls = Time.now.to_f # best guess at start
          _start_send_ticker
        end

        # If receiving
        if @hbr
          rm = @sx >= @cy ? @sx : @cy # ticker interval, ms
          @rti = 1000.0 * rm # ticker interval, μs
          @lr = Time.now.to_f # best guess at start
          _start_receive_ticker
        end

      end

      def _start_send_ticker
        sleeptime = @sti / 1000000.0 # Sleep time secs
        @st = Thread.new {
          while true do
            sleep sleeptime
            curt = Time.now.to_f
            if @logger && @logger.respond_to?(:on_hbfire)
              @logger.on_hbfire(log_params, "send_fire", curt)
            end
            delta = curt - @ls
            if delta > (@sti - (@sti/5.0)) / 1000000.0 # Be tolerant (minus)
              if @logger && @logger.respond_to?(:on_hbfire)
                @logger.on_hbfire(log_params, "send_heartbeat", curt)
              end
              # Send a heartbeat
              @transmit_semaphore.synchronize do
                begin
                  @socket.puts
                  @ls = curt # Update last send
                  @hb_sent = true # Reset if necessary
                rescue Exception => sendex
                  @hb_sent = false # Set the warning flag
                  if @logger && @logger.respond_to?(:on_hbwrite_fail)
                    @logger.on_hbwrite_fail(log_params, {"ticker_interval" => @sti,
                      "exception" => sendex})
                  end
                  raise # Re-raise.  What else could be done here?
                end
              end
            end
            Thread.pass
          end
        }
      end

      def _start_receive_ticker
        sleeptime = @rti / 1000000.0 # Sleep time secs
        @rt = Thread.new {
          while true do
            sleep sleeptime
            curt = Time.now.to_f
            if @logger && @logger.respond_to?(:on_hbfire)
              @logger.on_hbfire(log_params, "receive_fire", curt)
            end
            delta = curt - @lr
            if delta > ((@rti + (@rti/5.0)) / 1000000.0) # Be tolerant (plus)
              if @logger && @logger.respond_to?(:on_hbfire)
                @logger.on_hbfire(log_params, "receive_heartbeat", curt)
              end
              # Client code could be off doing something else (that is, no reading of
              # the socket has been requested by the caller).  Try to  handle that case.
              lock = @read_semaphore.try_lock
              if lock
                last_char = @socket.getc
                plc = parse_char(last_char)
                if plc == "\n" # Server Heartbeat
                  @lr = Time.now.to_f
                else
                  @socket.ungetc(last_char)
                end
                @read_semaphore.unlock
              else
                # Shrug.  Have not received one.  Just set warning flag.
                @hb_received = false
                if @logger && @logger.respond_to?(:on_hbread_fail)
                  @logger.on_hbread_fail(log_params, {"ticker_interval" => @rti})
                end
              end
            else
              @hb_received = true # Reset if necessary
            end
            Thread.pass
          end
        }
      end

    # Ref:
    # http://unicode.org/mail-arch/unicode-ml/y2003-m02/att-0467/01-The_Algorithm_to_Valide_an_UTF-8_String
    #
    def _valid_utf8?(string)
      case RUBY_VERSION
        when /1\.8\.[56]/
          bytes = []
          0.upto(string.length-1) {|i|
            bytes << string[i]
          }
        else
          bytes = string.bytes
      end

      #
      valid = true
      index = -1
      nb_hex = nil
      ni_hex = nil
      state = "start"
      next_byte_save = nil
      #
      bytes.each do |next_byte|
        index += 1
        next_byte_save = next_byte
        ni_hex = sprintf "%x", index
        nb_hex = sprintf "%x", next_byte
        # puts "Top: #{next_byte}(0x#{nb_hex}), index: #{index}(0x#{ni_hex})" if DEBUG
        case state

          # State: 'start'
          # The 'start' state:
          # * handles all occurrences of valid single byte characters i.e., the ASCII character set
          # * provides state transition logic for start bytes of valid characters with 2-4 bytes
          # * signals a validation failure for all other single bytes
          #
          when "start"
            # puts "state: start" if DEBUG
            case next_byte

              # ASCII
              # * Input = 0x00-0x7F : change state to START
              when (0x00..0x7f)
                # puts "state: start 1" if DEBUG
                state = "start"

              # Start byte of two byte characters
              # * Input = 0xC2-0xDF: change state to A
              when (0xc2..0xdf)
                # puts "state: start 2" if DEBUG
                state = "a"

              # Start byte of some three byte characters
              # * Input = 0xE1-0xEC, 0xEE-0xEF: change state to B
              when (0xe1..0xec)
                # puts "state: start 3" if DEBUG
                state = "b"
              when (0xee..0xef)
                # puts "state: start 4" if DEBUG
                state = "b"

              # Start byte of special three byte characters
              # * Input = 0xE0: change state to C
              when 0xe0
                # puts "state: start 5" if DEBUG
                state = "c"

              # Start byte of the remaining three byte characters
              # * Input = 0xED: change state to D
              when 0xed
                # puts "state: start 6" if DEBUG
                state = "d"

              # Start byte of some four byte characters
              # * Input = 0xF1-0xF3:change state to E
              when (0xf1..0xf3)
                # puts "state: start 7" if DEBUG
                state = "e"

              # Start byte of special four byte characters
              # * Input = 0xF0: change state to F
              when 0xf0
                # puts "state: start 8" if DEBUG
                state = "f"

              # Start byte of very special four byte characters
              # * Input = 0xF4: change state to G
              when 0xf4
                # puts "state: start 9" if DEBUG
                state = "g"

              # All other single characters are invalid
              # * Input = Others (0x80-0xBF,0xC0-0xC1, 0xF5-0xFF): ERROR
              else
                valid = false
                break
            end # of the inner case, the 'start' state

          # The last continuation byte of a 2, 3, or 4 byte character
          # State: 'a'
          #  o Input = 0x80-0xBF: change state to START
          #  o Others: ERROR
          when "a"
            # puts "state: a" if DEBUG
            if (0x80..0xbf) === next_byte
              state = "start"
            else
              valid = false
              break
            end

          # The first continuation byte for most 3 byte characters
          # (those with start bytes in: 0xe1-0xec or 0xee-0xef)
          # State: 'b'
          # o Input = 0x80-0xBF: change state to A
          # o Others: ERROR
          when "b"
            # puts "state: b" if DEBUG
            if (0x80..0xbf) === next_byte
              state = "a"
            else
              valid = false
              break
            end

          # The first continuation byte for some special 3 byte characters
          # (those with start byte 0xe0)
          # State: 'c'
          # o Input = 0xA0-0xBF: change state to A
          # o Others: ERROR
          when "c"
            # puts "state: c" if DEBUG
            if (0xa0..0xbf) === next_byte
              state = "a"
            else
              valid = false
              break
            end

          # The first continuation byte for the remaining 3 byte characters
          # (those with start byte 0xed)
          # State: 'd'
          # o Input = 0x80-0x9F: change state to A
          # o Others: ERROR
          when "d"
            # puts "state: d" if DEBUG
            if (0x80..0x9f) === next_byte
              state = "a"
            else
              valid = false
              break
            end

          # The first continuation byte for some 4 byte characters
          # (those with start bytes in: 0xf1-0xf3)
          # State: 'e'
          # o Input = 0x80-0xBF: change state to B
          # o Others: ERROR
          when "e"
            # puts "state: e" if DEBUG
            if (0x80..0xbf) === next_byte
              state = "b"
            else
              valid = false
              break
            end

          # The first continuation byte for some special 4 byte characters
          # (those with start byte 0xf0)
          # State: 'f'
          # o Input = 0x90-0xBF: change state to B
          # o Others: ERROR
          when "f"
            # puts "state: f" if DEBUG
            if (0x90..0xbf) === next_byte
              state = "b"
            else
              valid = false
              break
            end

          # The first continuation byte for the remaining 4 byte characters
          # (those with start byte 0xf4)
          # State: 'g'
          # o Input = 0x80-0x8F: change state to B
          # o Others: ERROR
          when "g"
            # puts "state: g" if DEBUG
            if (0x80..0x8f) === next_byte
              state = "b"
            else
              valid = false
              break
            end

          #
          else
            raise RuntimeError, "state: default"
        end
      end
      #
      # puts "State at end: #{state}" if DEBUG
      # Catch truncation at end of string
      if valid and state != 'start'
        # puts "Resetting valid value" if DEBUG
        valid = false
      end
      #
      valid
    end # of _valid_utf8?

    def _headerCheck(h)
      return if @protocol == Stomp::SPL_10 # Do nothing for this environment
      #
      h.each_pair do |k,v|
        # Keys here are symbolized
        ks = k.to_s
        ks.force_encoding(Stomp::UTF8) if ks.respond_to?(:force_encoding)
        raise Stomp::Error::UTF8ValidationError unless valid_utf8?(ks)
        #
        if v.is_a?(Array)
          v.each do |e|
            e.force_encoding(Stomp::UTF8) if e.respond_to?(:force_encoding)
            raise Stomp::Error::UTF8ValidationError unless valid_utf8?(e)
          end
        else
          vs = v.to_s + "" # Values are usually Strings, but could be TrueClass or Symbol
          # The + "" forces an 'unfreeze' if necessary
          vs.force_encoding(Stomp::UTF8) if vs.respond_to?(:force_encoding)
          raise Stomp::Error::UTF8ValidationError unless valid_utf8?(vs)
        end
      end
    end

    #
    def _encodeHeaders(h)
      eh = {}
      h.each_pair do |k,v|
        # Keys are symbolized
        ks = k.to_s
        if v.is_a?(Array)
          kenc = Stomp::HeaderCodec::encode(ks)
          eh[kenc] = []
          v.each do |e|
            eh[kenc] << Stomp::HeaderCodec::encode(e)
          end
        else
          vs = v.to_s
          eh[Stomp::HeaderCodec::encode(ks)] = Stomp::HeaderCodec::encode(vs)
        end
      end
      eh
    end

    #
    def _decodeHeaders(h)
      dh = {}
      h.each_pair do |k,v|
        # Keys here are NOT! symbolized
        if v.is_a?(Array)
          kdec = Stomp::HeaderCodec::decode(k)
          dh[kdec] = []
          v.each do |e|
            dh[kdec] << Stomp::HeaderCodec::decode(e)
          end
        else
          vs = v.to_s
          dh[Stomp::HeaderCodec::decode(k)] = Stomp::HeaderCodec::decode(vs)
        end
      end
      dh
    end

  end # class

end # module

