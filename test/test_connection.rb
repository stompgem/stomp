# -*- encoding: utf-8 -*-

if Kernel.respond_to?(:require_relative)
  require_relative("test_helper")
else
  $:.unshift(File.dirname(__FILE__))
  require 'test_helper'
end

=begin

  Main class for testing Stomp::Connection instances.

=end
class TestConnection < Test::Unit::TestCase
  include TestBase
  
  def setup
    @conn = get_connection()
    # Data for multi_thread tests
    @max_threads = 20
    @max_msgs = 100
  end

  def teardown
    @conn.disconnect if @conn.open? # allow tests to disconnect
  end

  # Test basic connection creation.
  def test_connection_exists
    assert_not_nil @conn
  end

  # Test asynchronous polling.
  def test_poll_async
	  sq = ENV['STOMP_ARTEMIS'] ? "jms.queue.queue.do.not.put.messages.on.this.queue" :
		  "/queue/do.not.put.messages.on.this.queue"
    @conn.subscribe(sq, :id => "a.no.messages.queue")
    # If the test 'hangs' here, Connection#poll is broken.
    m = @conn.poll
    assert m.nil?
  end

  # Test suppression of content length header.
  def test_no_length
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
  end unless ENV['STOMP_RABBIT']

  # Test direct / explicit receive.
  def test_explicit_receive
    conn_subscribe make_destination
    @conn.publish make_destination, "test_stomp#test_explicit_receive"
    msg = @conn.receive
    assert_equal "test_stomp#test_explicit_receive", msg.body
  end

  # Test asking for a receipt.
  def test_receipt
    conn_subscribe make_destination, :receipt => "abc"
    msg = @conn.receive
    assert_equal "abc", msg.headers['receipt-id']
    checkEmsg(@conn)
  end

  # Test asking for a receipt on disconnect.
  def test_disconnect_receipt
    @conn.disconnect :receipt => "abc123"
    assert_not_nil(@conn.disconnect_receipt, "should have a receipt")
    assert_equal(@conn.disconnect_receipt.headers['receipt-id'],
      "abc123", "receipt sent and received should match")
  end

  # Test ACKs for Stomp 1.0
  def test_client_ack_with_symbol_10
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
  end

  # Test ACKs for Stomp 1.1
  def test_client_ack_with_symbol_11
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
  end

  # Test ACKs for Stomp 1.2
  def test_client_ack_with_symbol_12
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
  end

  # Test a message with 0x00 embedded in the body.
  def test_embedded_null
    conn_subscribe make_destination
    @conn.publish make_destination, "a\0"
    msg = @conn.receive
    assert_equal "a\0" , msg.body
    checkEmsg(@conn)
  end

  # Test connection open checking.
  def test_connection_open?
    assert_equal true , @conn.open?
    @conn.disconnect
    assert_equal false, @conn.open?
  end

  # Test connection closed checking.
  def test_connection_closed?
    assert_equal false, @conn.closed?
    @conn.disconnect
    assert_equal true, @conn.closed?
  end

  # Test that methods detect a closed connection.
  def test_closed_checks_conn
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
  end

  # Test that we receive a Stomp::Message.
  def test_response_is_instance_of_message_class
    conn_subscribe make_destination
    @conn.publish make_destination, "a\0"
    msg = @conn.receive
    assert_instance_of Stomp::Message , msg
    checkEmsg(@conn)
  end

  # Test converting a Message to a string.
  def test_message_to_s
    conn_subscribe make_destination
    @conn.publish make_destination, "a\0"
    msg = @conn.receive
    assert_match(/^<Stomp::Message headers=/ , msg.to_s)
    checkEmsg(@conn)
  end
  
  # Test that a connection frame is present.
  def test_connection_frame
    assert_not_nil @conn.connection_frame
  end
  
  # Test messages with multiple line ends.
  def test_messages_with_multipleLine_ends
    conn_subscribe make_destination
    @conn.publish make_destination, "a\n\n"
    @conn.publish make_destination, "b\n\na\n\n"
    
    msg_a = @conn.receive
    msg_b = @conn.receive

    assert_equal "a\n\n", msg_a.body
    assert_equal "b\n\na\n\n", msg_b.body
    checkEmsg(@conn)
  end

  # Test publishing multiple messages.
  def test_publish_two_messages
    conn_subscribe make_destination
    @conn.publish make_destination, "a\0"
    @conn.publish make_destination, "b\0"
    msg_a = @conn.receive
    msg_b = @conn.receive

    assert_equal "a\0", msg_a.body
    assert_equal "b\0", msg_b.body
    checkEmsg(@conn)
  end

  def test_thread_hang_one
    received = nil
    Thread.new(@conn) do |amq|
        while true
            received = amq.receive
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
  end

  # Test polling with a single thread.
  def test_thread_poll_one
    received = nil
    max_sleep = (RUBY_VERSION =~ /1\.8/) ? 10 : 1
    Thread.new(@conn) do |amq|
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
  end

  # Test receiving with multiple threads.
  def test_multi_thread_receive
    lock = Mutex.new
    msg_ctr = 0
    dest = make_destination
    #
    1.upto(@max_threads) do |tnum|
      Thread.new(@conn) do |amq|
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
  end unless RUBY_ENGINE =~ /jruby/

  # Test polling with multiple threads.
  def test_multi_thread_poll
    #
    lock = Mutex.new
    msg_ctr = 0
    dest = make_destination
    #
    1.upto(@max_threads) do |tnum|
      Thread.new(@conn) do |amq|
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
  end unless RUBY_ENGINE =~ /jruby/

  # Test using a nil body.
  def test_nil_body
    dest = make_destination
    @conn.publish dest, nil
    conn_subscribe dest
    msg = @conn.receive
    assert_equal "", msg.body
    checkEmsg(@conn)
  end

  # Test transaction message sequencing.
  def test_transaction
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
  end unless ENV['STOMP_ARTEMIS'] # See Artemis docs for 1.3, page 222

  # Test duplicate subscriptions.
  def test_duplicate_subscription
    @conn.disconnect # not reliable
    @conn = Stomp::Connection.open(user, passcode, host, port, true) # reliable
    dest = make_destination
    conn_subscribe dest
    #
    assert_raise Stomp::Error::DuplicateSubscription do
      conn_subscribe dest
    end
    checkEmsg(@conn)
  end

  # Test nil 1.1 connection parameters.
  def test_nil_connparms
    @conn.disconnect
    #
    @conn = Stomp::Connection.open(user, passcode, host, port, false, 5, nil)
    checkEmsg(@conn)
  end

  # Basic NAK test.
  def test_nack11p_0010
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
    end
  end unless (ENV['STOMP_AMQ11'] || ENV['STOMP_ARTEMIS'])

  # Test to illustrate Issue #44.  Prior to a fix for #44, these tests would
  # fail only when connecting to a pure STOMP 1.0 server that does not 
  # return a 'version' header at all.
  def test_conn10_simple
    @conn.disconnect
    #
    vhost = ENV['STOMP_RABBIT'] ? "/" : host
    hash = { :hosts => [ 
      {:login => user, :passcode => passcode, :host => host, :port => port, :ssl => false},
      ],
      :connect_headers => {"accept-version" => "1.0", "host" => vhost},
      :reliable => false,
    }
    c = nil
    c = Stomp::Connection.new(hash)
    c.disconnect if c
    #
    hash = { :hosts => [ 
      {:login => user, :passcode => passcode, :host => host, :port => port, :ssl => false},
      ],
      :connect_headers => {"accept-version" => "3.14159,1.0,12.0", "host" => vhost},
      :reliable => false,
    }
    c = nil
    c = Stomp::Connection.new(hash)
    c.disconnect if c
  end

  # test JRuby detection
  def test_jruby_presence
    if defined?(RUBY_ENGINE) && RUBY_ENGINE =~ /jruby/
      assert @conn.jruby
    else
      assert !@conn.jruby
    end
  end

  # Test that methods detect an empty header key.
  def test_empty_header_key
    #
    bad_headers = {"a" => "11", "" => "emptykey", :c => "ccc"}
    #
    assert_raise Stomp::Error::ProtocolErrorEmptyHeaderKey do
      @conn.ack("dummy_data", bad_headers)
    end
    #
    assert_raise Stomp::Error::ProtocolErrorEmptyHeaderKey do
      @conn.nack("dummy_data", bad_headers)
    end if @conn.protocol != Stomp::SPL_10
    #
    assert_raise Stomp::Error::ProtocolErrorEmptyHeaderKey do
      @conn.begin("dummy_data", bad_headers)
    end
    #
    assert_raise Stomp::Error::ProtocolErrorEmptyHeaderKey do
      @conn.commit("dummy_data", bad_headers)
    end
    #
    assert_raise Stomp::Error::ProtocolErrorEmptyHeaderKey do
      @conn.abort("dummy_data", bad_headers)
    end
    #
    assert_raise Stomp::Error::ProtocolErrorEmptyHeaderKey do
      @conn.subscribe("dummy_data", bad_headers)
    end
    #
    assert_raise Stomp::Error::ProtocolErrorEmptyHeaderKey do
      @conn.unsubscribe("dummy_data", bad_headers)
    end
    #
    assert_raise Stomp::Error::ProtocolErrorEmptyHeaderKey do
      @conn.publish("dummy_data","dummy_data", bad_headers)
    end
    #
    assert_raise Stomp::Error::ProtocolErrorEmptyHeaderKey do
      @conn.disconnect(bad_headers)
    end
  end

  # Test that methods detect an empty header value.
  # STOMP 1.0 only.
  def test_empty_header_value
    if @conn.protocol != Stomp::SPL_10
      assert true
      return
    end
    #
    bad_headers = {"a" => "11", "hdra" => "", :c => "ccc"}
    #
    assert_raise Stomp::Error::ProtocolErrorEmptyHeaderValue do
      @conn.ack("dummy_data", bad_headers)
    end
    #
    assert_raise Stomp::Error::ProtocolErrorEmptyHeaderValue do
      @conn.nack("dummy_data", bad_headers)
    end if @conn.protocol != Stomp::SPL_10
    #
    assert_raise Stomp::Error::ProtocolErrorEmptyHeaderValue do
      @conn.begin("dummy_data", bad_headers)
    end
    #
    assert_raise Stomp::Error::ProtocolErrorEmptyHeaderValue do
      @conn.commit("dummy_data", bad_headers)
    end
    #
    assert_raise Stomp::Error::ProtocolErrorEmptyHeaderValue do
      @conn.abort("dummy_data", bad_headers)
    end
    #
    assert_raise Stomp::Error::ProtocolErrorEmptyHeaderValue do
      @conn.subscribe("dummy_data", bad_headers)
    end
    #
    assert_raise Stomp::Error::ProtocolErrorEmptyHeaderValue do
      @conn.unsubscribe("dummy_data", bad_headers)
    end
    #
    assert_raise Stomp::Error::ProtocolErrorEmptyHeaderValue do
      @conn.publish("dummy_data","dummy_data", bad_headers)
    end
    #
    assert_raise Stomp::Error::ProtocolErrorEmptyHeaderValue do
      @conn.disconnect(bad_headers)
    end
  end

  # test issue99, OK values
  def test_con_iss99_ok
    return unless host() == "localhost" && port() == 61613
    #
    ok_vals = dflt_data_ok()
    ok_vals.each do |hsv|
      conn = Stomp::Connection.new(hsv)
      conn.disconnect
    end
  end

  def test_conn_nodest_sub
    assert_raise Stomp::Error::DestinationRequired do
      @conn.subscribe(nil)
    end
  end

  def test_conn_nodest_unsub
    assert_raise Stomp::Error::DestinationRequired do
      @conn.unsubscribe(nil)
    end
  end

  def test_conn_nodest_pub
    assert_raise Stomp::Error::DestinationRequired do
      @conn.publish(nil, "msg")
    end
  end

end

