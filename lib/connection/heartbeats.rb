# -*- encoding: utf-8 -*-

require 'socket'
require 'timeout'
require 'io/wait'
require 'digest/sha1'

module Stomp

  class Connection

    private

    def _validate_hbheader()
      return if @connect_headers[:"heart-beat"] == "0,0" # Caller does not want heartbeats.  OK.
      parts = @connect_headers[:"heart-beat"].split(",")
      if (parts.size != 2) || (parts[0] != parts[0].to_i.to_s) || (parts[1] != parts[1].to_i.to_s)
        raise Stomp::Error::InvalidHeartBeatHeaderError
      end
    end

    def _init_heartbeats()
      return if @connect_headers[:"heart-beat"] == "0,0" # Caller does not want heartbeats.  OK.

      # Init.

      #
      @cx = @cy = @sx = @sy = 0   # Variable names as in spec

      #
      @hbsend_interval = @hbrecv_interval = 0.0 # Send/Receive ticker interval.

      #
      @hbsend_count = @hbrecv_count = 0 # Send/Receive ticker counts.

      #
      @ls = @lr = -1.0 # Last send/receive time (from Time.now.to_f)

      #
      @st = @rt = nil # Send/receive ticker thread

      # Handle current client / server capabilities.

      #
      cfh = @connection_frame.headers.symbolize_keys
      return if cfh[:"heart-beat"] == "0,0" # Server does not want heartbeats

      # Conect header parts.
      parts = @connect_headers[:"heart-beat"].split(",")
      @cx = parts[0].to_i
      @cy = parts[1].to_i

      # Connected frame header parts.
      parts = cfh[:"heart-beat"].split(",")
      @sx = parts[0].to_i
      @sy = parts[1].to_i

      # Catch odd situations like server has used => heart-beat:000,00000
      return if (@cx == 0 && @cy == 0) || (@sx == 0 && @sy == 0)

      # See if we are doing anything at all.

      @hbs = @hbr = true # Sending/Receiving heartbeats. Assume yes at first.
      # Check if sending is possible.
      @hbs = false if @cx == 0 || @sy == 0  # Reset if neither side wants
      # Check if receiving is possible.
      @hbr = false if @sx == 0 || @cy == 0  # Reset if neither side wants

      # Check if we should not do heartbeats at all
      return if (!@hbs && !@hbr)

      # If sending
      if @hbs
        sm = @cx >= @sy ? @cx : @sy     # ticker interval, ms
        @hbsend_interval = 1000.0 * sm  # ticker interval, μs
        @ls = Time.now.to_f             # best guess at start
        _start_send_ticker()
      end

      # If receiving
      if @hbr
        rm = @sx >= @cy ? @sx : @cy     # ticker interval, ms
        @hbrecv_interval = 1000.0 * rm  # ticker interval, μs
        @lr = Time.now.to_f             # best guess at start
        _start_receive_ticker()
      end

    end

    # _start_send_ticker starts a thread to send heartbeats when required.
    def _start_send_ticker()
      sleeptime = @hbsend_interval / 1000000.0 # Sleep time secs
      reconn = false
      adjust = 0.0
      @st = Thread.new {
        first_time = true
        while true do
          #
          slt = sleeptime - adjust - @fast_hbs_adjust
          sleep(slt)
          next unless @socket # nil under some circumstances ??
          curt = Time.now.to_f
          slog(:on_hbfire, log_params, "send_fire", :curt => curt, :last_sleep => slt)
          delta = curt - @ls
          # Be tolerant (minus), and always do this the first time through.
          # Reintroduce logic removed in d922fa.
          compval = (@hbsend_interval - (@hbsend_interval/5.0)) / 1000000.0
          if delta > compval || first_time
            first_time = false
            slog(:on_hbfire, log_params, "send_heartbeat", {:last_sleep => slt,
                    :curt => curt, :last_send => @ls, :delta => delta,
                    :compval => compval})
            # Send a heartbeat
            @transmit_semaphore.synchronize do
              begin
                @socket.puts
                @socket.flush       # Do not buffer heartbeats
                @ls = Time.now.to_f # Update last send
                @hb_sent = true     # Reset if necessary
                @hbsend_count += 1
              rescue Exception => sendex
                @hb_sent = false # Set the warning flag
                slog(:on_hbwrite_fail, log_params, {"ticker_interval" => sleeptime,
                  "exception" => sendex})
                if @hbser
                  raise # Re-raise if user requested this, otherwise ignore
                end
                if @reliable
                  reconn = true
                  break # exit the synchronize do
                end
              end
            end # of the synchronize
            if reconn
              # Attempt a fail over reconnect.  This is 'safe' here because
              # this thread no longer holds the @transmit_semaphore lock.
              @rt.kill if @rt   # Kill the receiver thread if one exists
              _reconn_prep_hb() # Drive reconnection logic
              Thread.exit       # This sender thread is done
            end
          end
          adjust = Time.now.to_f - curt
          Thread.pass
        end
      }
    end

    # _start_receive_ticker starts a thread that receives heartbeats when required.
    def _start_receive_ticker()
      sleeptime = @hbrecv_interval / 1000000.0 # Sleep time secs
      read_fail_count = 0
      lock_fail_count = 0
      fail_hard = false
      @rt = Thread.new {

        #
        while true do
          sleep sleeptime
          next unless @socket # nil under some circumstances ??
          rdrdy = _is_ready?(@socket)
          curt = Time.now.to_f
          slog(:on_hbfire, log_params, "receive_fire", :curt => curt)
          #
          begin
            delta = curt - @lr
            if delta > sleeptime
              slog(:on_hbfire, log_params, "receive_heartbeat", {})
              # Client code could be off doing something else (that is, no reading of
              # the socket has been requested by the caller).  Try to  handle that case.
              lock = @read_semaphore.try_lock
              if lock
                lock_fail_count = 0 # clear
                rdrdy = _is_ready?(@socket)
                if rdrdy
                  read_fail_count = 0 # clear
                  last_char = @socket.getc
                  if last_char.nil? # EOF from broker?
                    fail_hard = true
                  else
                    @lr = Time.now.to_f
                    plc = parse_char(last_char)
                    if plc == "\n" # Server Heartbeat
                      @hbrecv_count += 1
                      @hb_received = true # Reset if necessary
                    else
                      @socket.ungetc(last_char)
                    end
                  end
                  @read_semaphore.unlock # Release read lock
                else # Socket is not ready
                  @read_semaphore.unlock # Release read lock
                  @hb_received = false
                  read_fail_count += 1
                  slog(:on_hbread_fail, log_params, {"ticker_interval" => sleeptime,
                    "read_fail_count" => read_fail_count,
                    "lock_fail" => false,
                    "lock_fail_count" => lock_fail_count,
                    "fail_point" => "not_ready"})
                end
              else  # try_lock failed
                # Shrug.  Could not get lock.  Client must be actually be reading.
                @hb_received = false
                # But notify caller if possible
                lock_fail_count += 1
                slog(:on_hbread_fail, log_params, {"ticker_interval" => sleeptime,
                  "read_fail_count" => read_fail_count,
                  "lock_fail" => true,
                  "lock_fail_count" => lock_fail_count,
                  "fail_point" => "try_lock_fail"})
              end # of the try_lock

            else # delta <= sleeptime
              @hb_received = true # Reset if necessary
              read_fail_count = 0 # reset
              lock_fail_count = 0 # reset
            end # of the if delta > sleeptime
          rescue Exception => recvex
            slog(:on_hbread_fail, log_params, {"ticker_interval" => sleeptime,
              "exception" => recvex,
              "read_fail_count" => read_fail_count,
              "lock_fail_count" => lock_fail_count,
              "fail_point" => "receive_exception"})
            fail_hard = true
          end
          # Do we want to attempt a retry?
          if @reliable
            # Retry on hard fail or max read fails
            if fail_hard ||
              (@max_hbread_fails > 0 && read_fail_count >= @max_hbread_fails)
              # This is an attempt at a connection retry.
              @st.kill if @st   # Kill the sender thread if one exists
              _reconn_prep_hb() # Drive reconnection logic
              Thread.exit       # This receiver thread is done
            end
            # Retry on max lock fails.  Different logic in order to avoid a deadlock.
            if (@max_hbrlck_fails > 0 && lock_fail_count >= @max_hbrlck_fails)
              # This is an attempt at a connection retry.
              @gets_semaphore.synchronize do
                @getst.raise(Errno::EBADF.new) if @getst # kill the socket reading thread if exists
                @socket.close rescue nil # Attempt a forced close
              end
              @st.kill if @st   # Kill the sender thread if one exists
              Thread.exit       # This receiver thread is done
            end
          end
          Thread.pass         # Prior to next receive loop
        #
        end # of the "while true"
      } # end of the Thread.new
    end

    # _reconn_prep_hb prepares for a reconnect retry
    def _reconn_prep_hb()
      if @parameters
        change_host()
      end
      @socket = nil
      used_socket = socket()
      return used_socket
    end

  end # class Connection

end # module Stomp
