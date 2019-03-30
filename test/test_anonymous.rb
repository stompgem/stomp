# -*- encoding: utf-8 -*-

if Kernel.respond_to?(:require_relative)
  require_relative("test_helper")
else
  $:.unshift(File.dirname(__FILE__))
  require 'test_helper'
end

=begin

  Main class for testing Stomp::Connection instances with anonymous logins.

=end
class TestAnonymous < Test::Unit::TestCase
  include TestBase

  def setup
    @conn = get_anonymous_connection()
    # Data for multi_thread tests
    @max_threads = 20
    @max_msgs = 100
    @tandbg = ENV['TANDBG'] || ENV['TDBGALL']  ? true : false
  end

  def teardown
    @conn.disconnect if @conn.open? # allow tests to disconnect
  end

  # Test basic connection creation.
  def test_connection_exists
    mn = "test_connection_exists" if @tandbg
    p [ "01", mn, "starts" ] if @tandbg
    assert_not_nil @conn
    p [ "99", mn, "ends" ] if @tandbg
  end

  # Test asynchronous polling.
  def test_poll_async
    mn = "test_poll_async" if @tandbg
    p [ "01", mn, "starts" ] if @tandbg
  	sq = ENV['STOMP_ARTEMIS'] ? "jms.queue.queue.do.not.put.messages.on.this.queue" :
		  "/queue/do.not.put.messages.on.this.queue"
    @conn.subscribe(sq, :id => "a.no.messages.queue")
    # If the test 'hangs' here, Connection#poll is broken.
    m = @conn.poll
    assert m.nil?
    p [ "99", mn, "ends" ] if @tandbg
  end

  # Test suppression of content length header.
  def test_no_length
    mn = "test_no_length" if @tandbg
    p [ "01", mn, "starts" ] if @tandbg
    conn_subscribe make_destination
    #
    @conn.publish make_destination, "test_stomp#test_no_length",
                  { :suppress_content_length => true }
    msg = @conn.receive
    assert_equal "test_stomp#test_no_length", msg.body
    #
    @conn.publish make_destination, "test_stomp#test_\000_length",
                  { :suppress_content_length => true }
    msg2 = @conn.receive
    assert_equal "test_stomp#test_", msg2.body
    checkEmsg(@conn)
    p [ "99", mn, "ends" ] if @tandbg
  end unless ENV['STOMP_RABBIT']

  # Test direct / explicit receive.
  def test_explicit_receive
    mn = "test_explicit_receive" if @tandbg
    p [ "01", mn, "starts" ] if @tandbg
    conn_subscribe make_destination
    @conn.publish make_destination, "test_stomp#test_explicit_receive"
    msg = @conn.receive
    assert_equal "test_stomp#test_explicit_receive", msg.body
    p [ "99", mn, "ends" ] if @tandbg
  end

  # Test asking for a receipt.
  def test_receipt
    mn = "test_receipt" if @tandbg
    p [ "01", mn, "starts" ] if @tandbg
    conn_subscribe make_destination, :receipt => "abc"
    msg = @conn.receive
    tval = msg.headers['receipt-id']
    tval = msg.headers['receipt-id'][0] if msg.headers['receipt-id'].is_a?(Array)
    assert_equal "abc", tval
    checkEmsg(@conn)
    p [ "99", mn, "ends" ] if @tandbg
  end

  # Test asking for a receipt on disconnect.
  def test_disconnect_receipt
    mn = "test_disconnect_receipt" if @tandbg
    p [ "01", mn, "starts" ] if @tandbg
    @conn.disconnect :receipt => "abc123"
    assert_not_nil(@conn.disconnect_receipt, "should have a receipt")
    assert_equal(@conn.disconnect_receipt.headers['receipt-id'],
                  "abc123", "receipt sent and received should match")
    p [ "99", mn, "ends" ] if @tandbg
  end

  # Test ACKs for Stomp 1.0
  def test_client_ack_with_symbol_10
    mn = "test_client_ack_with_symbol_10" if @tandbg
    p [ "01", mn, "starts" ] if @tandbg
    if @conn.protocol != Stomp::SPL_10
      assert true
      return
    end
    queue = make_destination()
    @conn.subscribe queue, :ack => :client
    @conn.publish queue, "test_stomp#test_client_ack_with_symbol_10"
    msg = @conn.receive
    # ACK has one required header, message-id, which must contain a value 
    # matching the message-id for the MESSAGE being acknowledged.
    @conn.ack msg.headers['message-id']
    checkEmsg(@conn)
    p [ "99", mn, "ends" ] if @tandbg
  end

  # Test ACKs for Stomp 1.1
  def test_client_ack_with_symbol_11
    mn = "test_client_ack_with_symbol_11" if @tandbg
    p [ "01", mn, "starts" ] if @tandbg
    if @conn.protocol != Stomp::SPL_11
      assert true
      return
    end
    sid = @conn.uuid()
    queue = make_destination()
    @conn.subscribe queue, :ack => :client, :id => sid
    @conn.publish queue, "test_stomp#test_client_ack_with_symbol_11"
    msg = @conn.receive
    # ACK has two REQUIRED headers: message-id, which MUST contain a value 
    # matching the message-id for the MESSAGE being acknowledged and 
    # subscription, which MUST be set to match the value of the subscription's 
    # id header.
    @conn.ack msg.headers['message-id'], :subscription => msg.headers['subscription']
    checkEmsg(@conn)
    p [ "99", mn, "ends" ] if @tandbg
  end

  # Test ACKs for Stomp 1.2
  def test_client_ack_with_symbol_12
    mn = "test_client_ack_with_symbol_12" if @tandbg
    p [ "01", mn, "starts" ] if @tandbg
    if @conn.protocol != Stomp::SPL_12
      assert true
      return
    end
    sid = @conn.uuid()
    queue = make_destination()
    @conn.subscribe queue, :ack => :client, :id => sid
    @conn.publish queue, "test_stomp#test_client_ack_with_symbol_11"
    msg = @conn.receive
    # The ACK frame MUST include an id header matching the ack header 
    # of the MESSAGE being acknowledged.
    @conn.ack msg.headers['ack']
    checkEmsg(@conn)
    p [ "99", mn, "ends" ] if @tandbg
  end

  # Test a message with 0x00 embedded in the body.
  def test_embedded_null
    mn = "test_embedded_null" if @tandbg
    p [ "01", mn, "starts" ] if @tandbg
    conn_subscribe make_destination
    @conn.publish make_destination, "a\0"
    msg = @conn.receive
    assert_equal "a\0" , msg.body
    checkEmsg(@conn)
    p [ "99", mn, "ends" ] if @tandbg
  end

  # Test connection open checking.
  def test_connection_open?
    mn = "test_connection_open?" if @tandbg
    p [ "01", mn, "starts" ] if @tandbg
    assert_equal true , @conn.open?
    @conn.disconnect
    assert_equal false, @conn.open?
    p [ "99", mn, "ends" ] if @tandbg
  end

  # Test connection closed checking.
  def test_connection_closed?
    mn = "test_connection_closed?" if @tandbg
    p [ "01", mn, "starts" ] if @tandbg
    assert_equal false, @conn.closed?
    @conn.disconnect
    assert_equal true, @conn.closed?
    p [ "99", mn, "ends" ] if @tandbg
  end

  # Test that methods detect a closed connection.
  def test_closed_checks_conn
    mn = "test_closed_checks_conn" if @tandbg
    p [ "01", mn, "starts" ] if @tandbg
    @conn.disconnect
    #
    assert_raise Stomp::Error::NoCurrentConnection do
      @conn.ack("dummy_data")
    end
    #
    assert_raise Stomp::Error::NoCurrentConnection do
      @conn.begin("dummy_data")
    end
    #
    assert_raise Stomp::Error::NoCurrentConnection do
      @conn.commit("dummy_data")
    end
    #
    assert_raise Stomp::Error::NoCurrentConnection do
      @conn.abort("dummy_data")
    end
    #
    assert_raise Stomp::Error::NoCurrentConnection do
      conn_subscribe("dummy_data")
    end
    #
    assert_raise Stomp::Error::NoCurrentConnection do
      @conn.unsubscribe("dummy_data")
    end
    #
    assert_raise Stomp::Error::NoCurrentConnection do
      @conn.publish("dummy_data","dummy_data")
    end
    #
    assert_raise Stomp::Error::NoCurrentConnection do
      @conn.unreceive("dummy_data")
    end
    #
    assert_raise Stomp::Error::NoCurrentConnection do
      @conn.disconnect("dummy_data")
    end
    #
    assert_raise Stomp::Error::NoCurrentConnection do
      _ = @conn.receive
    end
    #
    assert_raise Stomp::Error::NoCurrentConnection do
      _ = @conn.poll
    end
    p [ "99", mn, "ends" ] if @tandbg
  end

  # Test that we receive a Stomp::Message.
  def test_response_is_instance_of_message_class
    mn = "test_response_is_instance_of_message_class" if @tandbg
    p [ "01", mn, "starts" ] if @tandbg
    conn_subscribe make_destination
    @conn.publish make_destination, "a\0"
    msg = @conn.receive
    assert_instance_of Stomp::Message , msg
    checkEmsg(@conn)
    p [ "99", mn, "ends" ] if @tandbg
  end

  # Test converting a Message to a string.
  def test_message_to_s
    mn = "test_message_to_s" if @tandbg
    p [ "01", mn, "starts" ] if @tandbg
    conn_subscribe make_destination
    @conn.publish make_destination, "a\0"
    msg = @conn.receive
    assert_match(/^<Stomp::Message headers=/ , msg.to_s)
    checkEmsg(@conn)
    p [ "99", mn, "ends" ] if @tandbg
  end

  # Test that a connection frame is present.
  def test_connection_frame
    mn = "test_connection_frame" if @tandbg
    p [ "01", mn, "starts" ] if @tandbg
    assert_not_nil @conn.connection_frame
    p [ "99", mn, "ends" ] if @tandbg
  end

  # Test messages with multiple line ends.
  def test_messages_with_multipleLine_ends
    mn = "test_messages_with_multipleLine_ends" if @tandbg
    p [ "01", mn, "starts" ] if @tandbg
    conn_subscribe make_destination
    @conn.publish make_destination, "a\n\n"
    @conn.publish make_destination, "b\n\na\n\n"

    msg_a = @conn.receive
    msg_b = @conn.receive

    assert_equal "a\n\n", msg_a.body
    assert_equal "b\n\na\n\n", msg_b.body
    checkEmsg(@conn)
    p [ "99", mn, "ends" ] if @tandbg
  end

  # Test publishing multiple messages.
  def test_publish_two_messages
    mn = "test_publish_two_messages" if @tandbg
    p [ "01", mn, "starts" ] if @tandbg
    conn_subscribe make_destination
    @conn.publish make_destination, "a\0"
    @conn.publish make_destination, "b\0"
    msg_a = @conn.receive
    msg_b = @conn.receive

    assert_equal "a\0", msg_a.body
    assert_equal "b\0", msg_b.body
    checkEmsg(@conn)
    p [ "99", mn, "ends" ] if @tandbg
  end

  def test_thread_hang_one
    mn = "test_thread_hang_one" if @tandbg
    p [ "01", mn, "starts" ] if @tandbg
    received = nil
    Thread.new(@conn) do |amq|
      no_rep_error()
      while true
        received = amq.receive
        Thread::exit if received
      end
    end
    #
    conn_subscribe( make_destination )
    message = Time.now.to_s
    @conn.publish(make_destination, message)
    sleep 1
    assert_not_nil received
    assert_equal message, received.body
    checkEmsg(@conn)
    p [ "99", mn, "ends" ] if @tandbg
  end

  # Test polling with a single thread.
  def test_thread_poll_one
    mn = "test_thread_poll_one" if @tandbg
    p [ "01", mn, "starts" ] if @tandbg
    received = nil
    max_sleep = (RUBY_VERSION =~ /1\.8/) ? 10 : 1
    Thread.new(@conn) do |amq|
      no_rep_error()
      while true
        received = amq.poll
        # One message is needed
        Thread.exit if received
        sleep max_sleep
      end
    end
    #
    conn_subscribe( make_destination )
    message = Time.now.to_s
    @conn.publish(make_destination, message)
    sleep max_sleep+1
    assert_not_nil received
    assert_equal message, received.body
    checkEmsg(@conn)
    p [ "99", mn, "ends" ] if @tandbg
  end

  # Test receiving with multiple threads.
  def test_multi_thread_receive
    mn = "test_multi_thread_receive" if @tandbg
    p [ "01", mn, "starts" ] if @tandbg
    lock = Mutex.new
    msg_ctr = 0
    dest = make_destination
    #
    1.upto(@max_threads) do |tnum|
      Thread.new(@conn) do |amq|
        no_rep_error()
        while true
          _ = amq.receive
          lock.synchronize do
            msg_ctr += 1
          end
          # Simulate message processing
          sleep 0.05
        end
      end
    end
    #
    conn_subscribe( dest )
    1.upto(@max_msgs) do |mnum|
      msg = Time.now.to_s + " #{mnum}"
      @conn.publish(dest, msg)
    end
    #
    max_sleep = (RUBY_VERSION =~ /1\.8/) ? 30 : 5
    max_sleep = 30 if RUBY_ENGINE =~ /mingw/
    sleep_incr = 0.10
    total_slept = 0
    while true
      break if @max_msgs == msg_ctr
      total_slept += sleep_incr
      break if total_slept > max_sleep
      sleep sleep_incr
    end
    assert_equal @max_msgs, msg_ctr
    checkEmsg(@conn)
    p [ "99", mn, "ends" ] if @tandbg
  end unless RUBY_ENGINE =~ /jruby/

  # Test polling with multiple threads.
  def test_multi_thread_poll
    mn = "test_multi_thread_poll" if @tandbg
    p [ "01", mn, "starts" ] if @tandbg
    #
    lock = Mutex.new
    msg_ctr = 0
    dest = make_destination
    #
    1.upto(@max_threads) do |tnum|
      Thread.new(@conn) do |amq|
        no_rep_error()
        while true
          received = amq.poll
          if received
            lock.synchronize do
              msg_ctr += 1
            end
            # Simulate message processing
            sleep 0.05
          else
            # Wait a bit for more work
            sleep 0.05
          end
        end
      end
    end
    #
    conn_subscribe( dest )
    1.upto(@max_msgs) do |mnum|
      msg = Time.now.to_s + " #{mnum}"
      @conn.publish(dest, msg)
    end
    #
    max_sleep = (RUBY_VERSION =~ /1\.8\.6/) ? 30 : 5
    max_sleep = 30 if RUBY_ENGINE =~ /mingw/
    sleep_incr = 0.10
    total_slept = 0
    while true
      break if @max_msgs == msg_ctr
      total_slept += sleep_incr
      break if total_slept > max_sleep
      sleep sleep_incr
    end
    assert_equal @max_msgs, msg_ctr
    checkEmsg(@conn)
    p [ "99", mn, "ends" ] if @tandbg
  end unless RUBY_ENGINE =~ /jruby/

  # Test using a nil body.
  def test_nil_body
    mn = "test_nil_body" if @tandbg
    p [ "01", mn, "starts" ] if @tandbg
    dest = make_destination
    @conn.publish dest, nil
    conn_subscribe dest
    msg = @conn.receive
    assert_equal "", msg.body
    checkEmsg(@conn)
    p [ "99", mn, "ends" ] if @tandbg
  end

  # Test transaction message sequencing.
  def test_transaction
    mn = "test_transaction" if @tandbg
    p [ "01", mn, "starts" ] if @tandbg
    conn_subscribe make_destination

    @conn.begin "txA"
    @conn.publish make_destination, "txn message", 'transaction' => "txA"

    @conn.publish make_destination, "first message"

    msg = @conn.receive
    assert_equal "first message", msg.body

    @conn.commit "txA"
    msg = @conn.receive
    assert_equal "txn message", msg.body
    checkEmsg(@conn)
    p [ "99", mn, "ends" ] if @tandbg
  end unless ENV['STOMP_ARTEMIS'] # See Artemis docs for 1.3, page 222

  # Test duplicate subscriptions.
  def test_duplicate_subscription
    mn = "test_duplicate_subscription" if @tandbg
    p [ "01", mn, "starts" ] if @tandbg
    @conn.disconnect # not reliable
    @conn = Stomp::Connection.open(nil, nil, host, port, true, nil, nil) # reliable
    dest = make_destination
    conn_subscribe dest
                     #
    assert_raise Stomp::Error::DuplicateSubscription do
      conn_subscribe dest
    end
    checkEmsg(@conn)
    p [ "99", mn, "ends" ] if @tandbg
  end

  # Test nil 1.1 connection parameters.
  def test_nil_connparms
    mn = "test_nil_connparms" if @tandbg
    p [ "01", mn, "starts" ] if @tandbg
    @conn.disconnect
    #
    @conn = Stomp::Connection.open(nil, nil, host, port, false, 5, nil)
    checkEmsg(@conn)
    p [ "99", mn, "ends" ] if @tandbg
  end

  # Basic NAK test.
  def test_nack11p_0010
    mn = "test_nack11p_0010" if @tandbg
    p [ "01", mn, "starts" ] if @tandbg
    if @conn.protocol == Stomp::SPL_10
      assert_raise Stomp::Error::UnsupportedProtocolError do
        @conn.nack "dummy msg-id"
      end
    else
      dest = make_destination
      smsg = "test_stomp#test_nack01: #{Time.now.to_f}"
      @conn.publish dest, smsg
      #
      sid = @conn.uuid()
      @conn.subscribe dest, :ack => :client, :id => sid
      msg = @conn.receive
      assert_equal smsg, msg.body
      case @conn.protocol
        when Stomp::SPL_12
          @conn.nack msg.headers["ack"]
          sleep 0.05 # Give racy brokers a chance to handle the last nack before unsubscribe
          @conn.unsubscribe dest, :id => sid
        else # Stomp::SPL_11
          @conn.nack msg.headers["message-id"], :subscription => sid
          sleep 0.05 # Give racy brokers a chance to handle the last nack before unsubscribe
          @conn.unsubscribe dest, :id => sid
      end

      # phase 2
      teardown()
      setup()
      sid = @conn.uuid()
      @conn.subscribe dest, :ack => :auto, :id => sid
      msg2 = @conn.receive
      assert_equal smsg, msg2.body
      checkEmsg(@conn)
      p [ "99", mn, "ends" ] if @tandbg
    end
  end unless (ENV['STOMP_AMQ11'] || ENV['STOMP_ARTEMIS'])

  # Test to illustrate Issue #44.  Prior to a fix for #44, these tests would
  # fail only when connecting to a pure STOMP 1.0 server that does not 
  # return a 'version' header at all.
  def test_conn10_simple
    mn = "test_conn10_simple" if @tandbg
    p [ "01", mn, "starts" ] if @tandbg
    @conn.disconnect
    #
    vhost = ENV['STOMP_RABBIT'] ? "/" : host
    hash = { :hosts => [
        {:host => host, :port => port, :ssl => false},
    ],
             :connect_headers => {"accept-version" => "1.0", "host" => vhost},
             :reliable => false,
    }
    c = nil
    c = Stomp::Connection.new(hash)
    c.disconnect if c
    #
    hash = { :hosts => [
        {:host => host, :port => port, :ssl => false},
    ],
             :connect_headers => {"accept-version" => "3.14159,1.0,12.0", "host" => vhost},
             :reliable => false,
    }
    c = nil
    c = Stomp::Connection.new(hash)
    c.disconnect if c
    p [ "99", mn, "ends" ] if @tandbg
  end

  # test JRuby detection
  def test_jruby_presence
    mn = "test_jruby_presence" if @tandbg
    p [ "01", mn, "starts" ] if @tandbg
    if defined?(RUBY_ENGINE) && RUBY_ENGINE =~ /jruby/
      assert @conn.jruby
    else
      assert !@conn.jruby
    end
    p [ "99", mn, "ends" ] if @tandbg
  end

end

