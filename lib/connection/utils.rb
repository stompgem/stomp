# -*- encoding: utf-8 -*-

require 'socket'
require 'timeout'
require 'io/wait'
require 'digest/sha1'

module Stomp

  class Connection

    private

    # Support multi-homed servers.
    def _expand_hosts(hash)
      new_hash = hash.clone
      new_hash[:hosts_cloned] = hash[:hosts].clone
      new_hash[:hosts] = []
      #
      hash[:hosts].each do |host_parms|
        ai = Socket.getaddrinfo(host_parms[:host], nil, nil, Socket::SOCK_STREAM)
        next if ai.nil? || ai.size == 0
        info6 = ai.detect {|info| info[4] == Socket::AF_INET6}
        info4 = ai.detect {|info| info[4] == Socket::AF_INET}
        if info6
          new_hostp = host_parms.clone
          new_hostp[:host] = info6[3]
          new_hash[:hosts] << new_hostp
        end
        if info4
          new_hostp = host_parms.clone
          new_hostp[:host] = info4[3]
          new_hash[:hosts] << new_hostp
        end
      end
      return new_hash
    end

    # Handle 1.9+ character representation.
    def parse_char(char)
      RUBY_VERSION > '1.9' ? char : char.chr
    end

    # Create parameters for any callback logger.
    def log_params()
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
      lparms[:cur_failure] = @failure # To assist in debugging
      lparms[:openstat] = open?
      #
      lparms
    end

    # _pre_connect handles low level logic just prior to a physical connect.
    def _pre_connect()
      @connect_headers = @connect_headers.symbolize_keys
      raise Stomp::Error::ProtocolErrorConnect if (@connect_headers[:"accept-version"] && !@connect_headers[:host])
      raise Stomp::Error::ProtocolErrorConnect if (!@connect_headers[:"accept-version"] && @connect_headers[:host])
      return unless (@connect_headers[:"accept-version"] && @connect_headers[:host]) # 1.0
      # Try 1.1 or greater
      @hhas10 = false
      okvers = []
      avers = @connect_headers[:"accept-version"].split(",")
      avers.each do |nver|
        if Stomp::SUPPORTED.index(nver)
          okvers << nver
          @hhas10 = true if nver == Stomp::SPL_10
        end
      end
      raise Stomp::Error::UnsupportedProtocolError if okvers == []
      @connect_headers[:"accept-version"] = okvers.join(",") # This goes to server
      # Heartbeats - pre connect
      return unless @connect_headers[:"heart-beat"]
      _validate_hbheader()
    end

    # _post_connect handles low level logic just after a physical connect.
    def _post_connect()
      return unless (@connect_headers[:"accept-version"] && @connect_headers[:host]) # 1.0
      if @connection_frame.command == Stomp::CMD_ERROR
        @connection_frame.headers = _decodeHeaders(@connection_frame.headers)
        return
      end
      # We are CONNECTed
      cfh = @connection_frame.headers.symbolize_keys
      @protocol = cfh[:version]
      if @protocol
        # Should not happen, but check anyway
        raise Stomp::Error::UnsupportedProtocolError unless Stomp::SUPPORTED.index(@protocol)
      else # CONNECTed to a 1.0 server that does not return *any* 1.1 type headers
        @protocol = Stomp::SPL_10 # reset
        return
      end
      # Heartbeats
      return unless @connect_headers[:"heart-beat"]
      _init_heartbeats()
    end

    # socket creates and returns a new socket for use by the connection.
    def socket()
      @socket_semaphore.synchronize do
        used_socket = @socket
        used_socket = nil if closed?

        while used_socket.nil? || !@failure.nil?
          @failure = nil
          begin
            used_socket = open_socket() # sets @closed = false if OK
            # Open is complete
            connect(used_socket)
            slog(:on_connected, log_params)
            @connection_attempts = 0
          rescue
            @failure = $!
            used_socket = nil
            @closed = true

            raise unless @reliable
            raise if @failure.is_a?(Stomp::Error::LoggerConnectionError)
            # Catch errors which are:
            # a) emitted from corrupted 1.1+ 'connect' (caller programming error)
            # b) should never be retried
            raise if @failure.is_a?(Stomp::Error::ProtocolError11p)

            begin
              unless slog(:on_connectfail,log_params)
                $stderr.print "connect to #{@host} failed: #{$!} will retry(##{@connection_attempts}) in #{@reconnect_delay}\n"
              end
            rescue Exception => aex
              raise if aex.is_a?(Stomp::Error::LoggerConnectionError)
            end
            if max_reconnect_attempts?
              $stderr.print "In socket() Reached MaxReconnectAttempts"
              ### _dump_threads()
              mt = @parameters[:client_main]
              if !mt.nil?
                mt.raise Stomp::Error::MaxReconnectAttempts
                Thread::exit
              end
              raise Stomp::Error::MaxReconnectAttempts
            end
            sleep(@reconnect_delay)
            @connection_attempts += 1

            if @parameters
              change_host()
              increase_reconnect_delay()
            end
          end
        end
        @socket = used_socket
      end
    end

    # refine_params sets up defaults for a Hash initialize.
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
        :connect_timeout => 0,
        # Parse Timeout
        :parse_timeout => 5,
        :dmh => false,
        # Closed check logic
        :closed_check => true,
        :hbser => false,
        :stompconn => false,
        :max_hbread_fails => 0,
        :max_hbrlck_fails => 0,
        :fast_hbs_adjust => 0.0,
        :connread_timeout => 0,
        :tcp_nodelay => true,
        :start_timeout => 0,
        :sslctx_newparm => nil,
        :ssl_post_conn_check => true,
      }

      res_params = default_params.merge(params)
      if res_params[:dmh]
        res_params = _expand_hosts(res_params)
      end
      return res_params
    end

    # change_host selects the next host for retries.
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

    # Duplicate parameters hash
    def _hdup(h)
      ldup = {}
      ldup.merge!(h)
      ldup[:hosts] = []
      hvals = h[:hosts].nil? ? h["hosts"] : h[:hosts]
      hvals.each do |hv|
        ldup[:hosts] << hv.dup
      end
      ldup
    end

    # max_reconnect_attempts? returns nil or the number of maximum reconnect
    # attempts.
    def max_reconnect_attempts?
      !(@parameters.nil? || @parameters[:max_reconnect_attempts].nil?) && @parameters[:max_reconnect_attempts] != 0 && @connection_attempts >= @parameters[:max_reconnect_attempts]
    end

    # increase_reconnect_delay increases the reconnect delay for the next connection
    # attempt.
    def increase_reconnect_delay

      @reconnect_delay *= @parameters[:back_off_multiplier] if @parameters[:use_exponential_back_off]
      @reconnect_delay = @parameters[:max_reconnect_delay] if @reconnect_delay > @parameters[:max_reconnect_delay]

      @reconnect_delay
    end

    # __old_receive receives a frame, blocks until the frame is received.
    def __old_receive()
      # The receive may fail so we may need to retry.
      while true
        begin
          used_socket = socket()
          return _receive(used_socket)
        rescue Stomp::Error::MaxReconnectAttempts
          unless slog(:on_miscerr, log_params, "Reached MaxReconnectAttempts")
            $stderr.print "Reached MaxReconnectAttempts\n"
          end
          raise
        rescue
          @failure = $!
          raise unless @reliable
          errstr = "receive failed: #{$!}"
          unless slog(:on_miscerr, log_params, "es1_oldrecv: " + errstr)
            $stderr.print "\non_miscerr\n"
            $stderr.print log_params.inspect
            $stderr.print "\n"
            $stderr.print "es2_oldrecv: " + errstr
            $stderr.print "\n"
          end

          # !!! This initiates a re-connect !!!
          _reconn_prep()
        end
      end
    end

    # _reconn_prep prepares for a reconnect retry
    def _reconn_prep()
      close_socket()
      if @parameters
        change_host()
      end
      @st.kill if @st # Kill ticker thread if any
      @rt.kill if @rt # Kill ticker thread if any
      @socket = nil
    end

  end # class Connection

end # module Stomp
