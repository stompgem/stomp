# -*- encoding: utf-8 -*-

require 'socket'
require 'timeout'
require 'io/wait'
require 'digest/sha1'

module Stomp

  class Connection

      def _interruptible_gets(read_socket)
        # The gets thread may be interrupted by the heartbeat thread. Ensure that
        # if so interrupted, a new gets cannot start until after the heartbeat
        # thread finishes its work. This is PURELY to avoid a segfault bug
        # involving OpenSSL::Buffer.
        @gets_semaphore.synchronize { @getst = Thread.current }
        read_socket.gets
      ensure
        @gets_semaphore.synchronize { @getst = nil }
      end

      private

      # Really read from the wire.
      def _receive(read_socket, connread = false)
        # p [ "ioscheck", @iosto, connread ]
        # _dump_callstack()
        # drdbg = true
        drdbg = false
        @read_semaphore.synchronize do
          line = nil
          if connread
            begin
              Timeout::timeout(@connread_timeout, Stomp::Error::ConnectReadTimeout) do
                line = _init_line_read(read_socket)
              end
            rescue Stomp::Error::ConnectReadTimeout => ex
              if @reliable
                _reconn_prep()
              end
              raise ex
            end
          else
            p [ "CONR01" ] if drdbg
            _dump_callstack() if drdbg
            line = _init_line_read(read_socket)
          end
          #
          p [ "nilcheck", line.nil? ] if drdbg
          return nil if line.nil?
          #An extra \n at the beginning of the frame, possibly not caught by is_ready?
          line = '' if line == "\n"
          if line == HAND_SHAKE_DATA
            raise Stomp::Error::HandShakeDetectedError
          end
          p [ "wiredatain_01A", line, Time.now ] if drdbg
          line = _normalize_line_end(line) if @protocol >= Stomp::SPL_12
          p [ "wiredatain_01B", line, Time.now ] if drdbg
          # Reads the beginning of the message until it runs into a empty line
          message_header = ''
          begin
            message_header += line
            p [ "wiredatain_02A", line, Time.now ] if drdbg
            unless connread || @ssl
              raise Stomp::Error::ReceiveTimeout unless IO.select([read_socket], nil, nil, @iosto)
            end
            p [ "wiredatain_02B", line, Time.now ] if drdbg
            line = _interruptible_gets(read_socket)
            p [ "wiredatain_02C", line ] if drdbg
            raise  if line.nil?
            line = _normalize_line_end(line) if @protocol >= Stomp::SPL_12
            p [ "wiredatain_02D", line ] if drdbg
          end until line =~ /^\s?\n$/
          p [ "wiredatain_03A" ] if drdbg
          # Checks if it includes content_length header
          content_length = message_header.match(/content-length\s?:\s?(\d+)\s?\n/)
          message_body = ''

          p [ "wiredatain_03B", content_length ] if drdbg
          # If content_length is present, read the specified amount of bytes
          if content_length
            unless connread || @ssl
              raise Stomp::Error::ReceiveTimeout unless IO.select([read_socket], nil, nil, @iosto)
            end
            p [ "CL01" ] if drdbg
            message_body = read_socket.read content_length[1].to_i
            unless connread || @ssl
              raise Stomp::Error::ReceiveTimeout unless IO.select([read_socket], nil, nil, @iosto)
            end
            raise Stomp::Error::InvalidMessageLength unless parse_char(read_socket.getc) == "\0"
            # Else read the rest of the message until the first \0
          else
            unless connread || @ssl
              raise Stomp::Error::ReceiveTimeout unless IO.select([read_socket], nil, nil, @iosto)
            end
            p [ "NOCL01" ] if drdbg
            message_body = read_socket.readline("\0")
            message_body.chop!
          end

          p [ "wiredatain_04" ] if drdbg
          # If the buffer isn't empty, reads trailing new lines.
          #
          # Note: experiments with JRuby seem to show that socket.ready? never
          # returns true.  It appears that in cases where Ruby returns true
          # that JRuby returns a Fixnum.  We attempt to adjust for this
          # in the _is_ready? method.
          #
          # Note 2: the draining of new lines must be done _after_ a message
          # is read.  Do _not_ leave them on the wire and attempt to drain them
          # at the start of the next read.  Attempting to do that breaks the
          # asynchronous nature of the 'poll' method.
          p [ "wiredatain_05_prep", "isr", _is_ready?(read_socket) ] if drdbg
          while _is_ready?(read_socket)
            unless connread || @ssl
              raise Stomp::Error::ReceiveTimeout unless IO.select([read_socket], nil, nil, @iosto)
            end
            p [ "WHIR01" ] if drdbg
            last_char = read_socket.getc
            break unless last_char
            if parse_char(last_char) != "\n"
              read_socket.ungetc(last_char)
              break
            end
          end
          p [ "wiredatain_05A" ] if drdbg
          if @protocol >= Stomp::SPL_11
            @lr = Time.now.to_f if @hbr
          end
          # Adds the excluded \n and \0 and tries to create a new message with it
          p [ "wiredatain_05B" ] if drdbg
          msg = Message.new(message_header + "\n" + message_body + "\0", @protocol >= Stomp::SPL_11)
          p [ "wiredatain_06", msg.command, msg.headers ] if drdbg
          #
          if @protocol >= Stomp::SPL_11 && msg.command != Stomp::CMD_CONNECTED
            msg.headers = _decodeHeaders(msg.headers)
          end
          p [ "wiredatain_99", msg.command, msg.headers ] if drdbg
          msg
        end
      end

      #
      # This is a total hack, to try and guess how JRuby will behave today.
      #
      def _is_ready?(s)
        rdy = s.ready?
        ### p [ "isr?", rdy ]
        return rdy unless @jruby
        ### p [ "jrdychk", rdy.class ]
        if rdy.class == NilClass
          # rdy = true
          rdy = false # A test
        else
          rdy = (rdy.class == Fixnum || rdy.class == TrueClass) ? true : false
        end
        ### p [ "isr?_last", rdy ]
        rdy
      end


      # Normalize line ends because 1.2+ brokers can send 'mixed mode' headers, i.e.:
      # - Some headers end with '\n'
      # - Other headers end with '\r\n'
      def _normalize_line_end(line)
        return line unless @usecrlf
        # p [ "nleln", line ]
        line_len = line.respond_to?(:bytesize) ? line.bytesize : line.length
        last2 = line[line_len-2...line_len]
        # p [ "nlel2", last2 ]
        return line unless last2 == "\r\n"
        return line[0...line_len-2] + "\n"
      end

      # transmit logically puts a Message on the wire.
      def transmit(command, headers = {}, body = '')
        # The transmit may fail so we may need to retry.
        while true
          begin
            used_socket = socket()
            _transmit(used_socket, command, headers, body)
            return
          rescue Stomp::Error::MaxReconnectAttempts => e
            _ = e
            raise
          rescue
            @failure = $!
            raise unless @reliable
            errstr = "transmit to #{@host} failed: #{$!}\n"
            unless slog(:on_miscerr, log_params, "es_trans: " + errstr)
              $stderr.print errstr
            end
            # !!! This loop initiates a re-connect !!!
            _reconn_prep()
          end
        end
      end

      # _transmit is the real wire write logic.
      def _transmit(used_socket, command, headers = {}, body = '')

        # p [ "wirewrite" ]
        # _dump_callstack()

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
          headers[:'content-length'] = "#{body_length_bytes}" unless headers[:suppress_content_length]
          headers[:'content-type'] = "text/plain; charset=UTF-8" unless headers[:'content-type'] || headers[:suppress_content_type]
          _wire_write(used_socket,command)
          headers.each do |k,v|
            if v.is_a?(Array)
              v.each do |e|
                _wire_write(used_socket,"#{k}:#{e}")
              end
            else
              _wire_write(used_socket,"#{k}:#{v}")
            end
          end
          _wire_write(used_socket,"")
          if body != ''
            if headers[:suppress_content_length]
              if tz = body.index("\00")
                used_socket.write body[0..tz-1]
              else
                used_socket.write body
              end
            else
              used_socket.write body
            end
          end
          used_socket.write "\0"
          used_socket.flush if autoflush

          if @protocol >= Stomp::SPL_11
            @ls = Time.now.to_f if @hbs
          end

        end
      end

      # Use CRLF if protocol is >= 1.2, and the client requested CRLF
      def _wire_write(sock, data)
        # p [ "debug_01", @protocol, @usecrlf ]
        if @protocol >= Stomp::SPL_12 && @usecrlf
          wiredata = "#{data}#{Stomp::CR}#{Stomp::LF}"
          # p [ "wiredataout_01:", wiredata ]
          sock.write(wiredata)
        else
          # p [ "wiredataout_02:", "#{data}\n" ]
          sock.puts data
        end
      end

      # open_tcp_socket opens a TCP socket.
      def open_tcp_socket()

        ## $stderr.print("h: #{@host}, p: #{@port}\n")

        tcp_socket = nil
        slog(:on_connecting, log_params)
        Timeout::timeout(@connect_timeout, Stomp::Error::SocketOpenTimeout) do
          tcp_socket = TCPSocket.open(@host, @port)
        end
        tcp_socket
      end

      # open_ssl_socket opens an SSL socket.
      def open_ssl_socket()
        require 'openssl' unless defined?(OpenSSL)
        begin # Any raised SSL exceptions
          ctx = @sslctx_newparm ? OpenSSL::SSL::SSLContext.new(@sslctx_newparm) : OpenSSL::SSL::SSLContext.new
          ctx.verify_mode = OpenSSL::SSL::VERIFY_NONE # Assume for now
          #
          # Note: if a client uses :ssl => true this would result in the gem using
          # the _default_ Ruby ciphers list.  This is _known_ to fail in later
          # Ruby releases.  The gem now detects :ssl => true, and replaces that
          # with:
          # * :ssl => Stomp::SSLParams.new
          #
          # The above results in the use of Stomp default parameters.
          #
          # To specifically request Stomp default parameters, use:
          # * :ssl => Stomp::SSLParams.new(..., :ciphers => Stomp::DEFAULT_CIPHERS)
          #
          # If connecting with an SSLParams instance, and the _default_ Ruby
          # ciphers list is actually required, use:
          # * :ssl => Stomp::SSLParams.new(..., :use_ruby_ciphers => true)
          #
          # If a custom ciphers list is required, connect with:
          # * :ssl => Stomp::SSLParams.new(..., :ciphers => custom_ciphers_list)
          #
          if @ssl != true
            #
            # Here @ssl is:
            # * an instance of Stomp::SSLParams
            # Control would not be here if @ssl == false or @ssl.nil?.
            #

            # Back reference the SSLContext
            @ssl.ctx = ctx

            # Server authentication parameters if required
            if @ssl.ts_files
              ctx.verify_mode = OpenSSL::SSL::VERIFY_PEER
              truststores = OpenSSL::X509::Store.new
              fl = @ssl.ts_files.split(",")
              fl.each do |fn|
                # Add next cert file listed
                raise Stomp::Error::SSLNoTruststoreFileError if !File::exists?(fn)
                raise Stomp::Error::SSLUnreadableTruststoreFileError if !File::readable?(fn)
                truststores.add_file(fn)
              end
              ctx.cert_store = truststores
            end

            # Client authentication parameters.
            # Both cert file and key file must be present or not, it can not be a mix.
            raise Stomp::Error::SSLClientParamsError if @ssl.cert_file.nil? && !@ssl.key_file.nil?
            raise Stomp::Error::SSLClientParamsError if !@ssl.cert_file.nil? && @ssl.key_file.nil?
            if @ssl.cert_file # Any check will do here
              raise Stomp::Error::SSLNoCertFileError if !File::exists?(@ssl.cert_file)
              raise Stomp::Error::SSLUnreadableCertFileError if !File::readable?(@ssl.cert_file)
              ctx.cert = OpenSSL::X509::Certificate.new(File.read(@ssl.cert_file))
              raise Stomp::Error::SSLNoKeyFileError if !File::exists?(@ssl.key_file)
              raise Stomp::Error::SSLUnreadableKeyFileError if !File::readable?(@ssl.key_file)
              ctx.key  = OpenSSL::PKey::RSA.new(File.read(@ssl.key_file), @ssl.key_password)
            end

            # Cipher list
            # As of this writing, there are numerous problems with supplying
            # cipher lists to jruby.  So we do not attempt to do that here.
            if !@ssl.use_ruby_ciphers # No Ruby ciphers (the default)
              if @ssl.ciphers # User ciphers list?
                ctx.ciphers = @ssl.ciphers # Accept user supplied ciphers
              else
                ctx.ciphers = Stomp::DEFAULT_CIPHERS # Just use Stomp defaults
              end
            end unless @jruby

            # Set SSLContext Options if user asks for it in Stomp::SSLParams
            # and SSL supports it.
            if @ssl.ssl_ctxopts && ctx.respond_to?(:options=)
              ctx.options = @ssl.ssl_ctxopts
            end

          end

          #
          ssl = nil
          slog(:on_ssl_connecting, log_params)
          # _dump_ctx(ctx)
          Timeout::timeout(@connect_timeout, Stomp::Error::SocketOpenTimeout) do
            tcp_socket = TCPSocket.open(@host, @port)
            ssl = OpenSSL::SSL::SSLSocket.new(tcp_socket, ctx)
            ssl.hostname = @host if ssl.respond_to? :hostname=
            ssl.sync_close = true # Sync ssl close with underlying TCP socket
            ssl.connect
            if (ssl.context.verify_mode != OpenSSL::SSL::VERIFY_NONE) && @ssl_post_conn_check
              ssl.post_connection_check(@host)
            end
          end
          def ssl.ready?
            ! @rbuffer.empty? || @io.ready?
          end
          if @ssl != true
            # Pass back results if possible
            if RUBY_VERSION =~ /1\.8\.[56]/
              @ssl.verify_result = "N/A for Ruby #{RUBY_VERSION}"
            else
              @ssl.verify_result = ssl.verify_result
            end
            @ssl.peer_cert = ssl.peer_cert
          end
          slog(:on_ssl_connected, log_params)
          ssl
        rescue Exception => ex
          lp = log_params.clone
          lp[:ssl_exception] = ex
          slog(:on_ssl_connectfail, lp)
          if ssl
            # shut down the TCP socket - we just failed to do the SSL handshake in time
            ssl.close
          end
          #
          puts ex.backtrace
          $stdout.flush
          raise # Reraise
        end
      end

      # close_socket closes the current open socket, and hence the connection.
      def close_socket()
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

      # open_socket opens a TCP or SSL soclet as required.
      def open_socket()
        used_socket = @ssl ? open_ssl_socket : open_tcp_socket
        # try to close the old connection if any
        close_socket

        @closed = false
        if @parameters # nil in some rspec tests
          unless @reconnect_delay
            @reconnect_delay = @parameters[:initial_reconnect_delay] || iosto1
          end
        end
        # Use keepalive
        used_socket.setsockopt(Socket::SOL_SOCKET, Socket::SO_KEEPALIVE, true)

        # TCP_NODELAY option (disables Nagle's algorithm)
        used_socket.setsockopt(Socket::IPPROTO_TCP, Socket::TCP_NODELAY, !!(@parameters && @parameters[:tcp_nodelay]))

        @iosto = @parse_timeout ? @parse_timeout.to_f : 0.0

        used_socket
      end

      # connect performs a basic STOMP CONNECT operation.
      def connect(used_socket)
        @connect_headers = {} unless @connect_headers # Caller said nil/false
        headers = @connect_headers.clone
        headers[:login] = @login unless @login.to_s.empty?
        headers[:passcode] = @passcode unless @login.to_s.empty?
        _pre_connect
        if !@hhas10 && @stompconn
          _transmit(used_socket, Stomp::CMD_STOMP, headers)
        else
          _transmit(used_socket, Stomp::CMD_CONNECT, headers)
        end
        @connection_frame = _receive(used_socket, true)
        _post_connect
        @disconnect_receipt = nil
        @session = @connection_frame.headers["session"] if @connection_frame
        # replay any subscriptions.
        @subscriptions.each {|k,v|
          _transmit(used_socket, Stomp::CMD_SUBSCRIBE, v)
        }
      end

      def _init_line_read(read_socket)
          line = ''
          if @protocol == Stomp::SPL_10 || (@protocol >= Stomp::SPL_11 && !@hbr)
            if @jruby
              # Handle JRuby specific behavior.
              ### p [ "ilrjr00", _is_ready?(read_socket), RUBY_VERSION ]
              if RUBY_VERSION <  "2"
                while true
                  ### p [ "ilrjr01A1", _is_ready?(read_socket) ]
                  line = _interruptible_gets(read_socket) # Data from wire
                  break unless line == "\n"
                  line = ''
                end
              else # RUBY_VERSION >= "2"
                while _is_ready?(read_socket)
                  ### p [ "ilrjr01B2", _is_ready?(read_socket) ]
                  line = _interruptible_gets(read_socket) # Data from wire
                  break unless line == "\n"
                  line = ''
                end
              end
            else
              line = _interruptible_gets(read_socket) # The old way
            end
          else # We are >= 1.1 *AND* receiving heartbeats.
            while true
              line = _interruptible_gets(read_socket) # Data from wire
              break unless line == "\n"
              line = ''
              @lr = Time.now.to_f
            end
          end
          line
      end

      # Used for debugging
      def _dump_ctx(ctx)
        p [ "dc01", ctx.inspect ]
        p [ "dc02ciphers", ctx.ciphers ]
      end

      # used for debugging
      def _dump_callstack()
        i = 0
        caller.each do |c|
          p [ "csn", i, c ]
          i += 1
        end
      end # _dump_callstack

      # used for debugging
      def _dump_threads()
        tl = Thread::list
        tl.each do |at|
          p [ "THDMPN", at ]
        end
        p [ "THDMPMain", @parameters[:client_main] ]
      end

  end # class Connection

end # module Stomp
