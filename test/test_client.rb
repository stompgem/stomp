# -*- encoding: utf-8 -*-

if Kernel.respond_to?(:require_relative)
  require_relative("test_helper")
else
  $:.unshift(File.dirname(__FILE__))
  require 'test_helper'
end

=begin

  Main class for testing Stomp::Client instances.

=end
class TestClient < Test::Unit::TestCase
  include TestBase

  def setup
    @client = get_client()
    # Multi_thread test data
    @max_threads = 20
    @max_msgs = 50
    @tcldbg = ENV['TCLDBG'] || ENV['TDBGALL'] ? true : false
  end

  def teardown
    @client.close if @client && @client.open? # allow tests to close
  end

  # Test poll works.
  def test_poll_async
    mn = "test_poll_async" if @tcldbg
    p [ "01", mn, "starts" ] if @tcldbg
    # If the test 'hangs' here, Connection#poll is broken.
    m = @client.poll
    assert m.nil?
    p [ "99", mn, "ends" ] if @tcldbg
  end  unless RUBY_ENGINE =~ /jruby/

  # Test ACKs.
  def test_ack_api_works
    mn = "test_ack_api_works" if @tcldbg
    p [ "01", mn, "starts" ] if @tcldbg
    @client.publish make_destination, message_text, {:suppress_content_length => true}

    received = nil
    @client.subscribe(make_destination, {:ack => 'client'}) {|msg|
      received = msg
      p [ "02", mn, "have_msg" ] if @tcldbg
    }
    p [ "03", mn, "sub_done" ] if @tcldbg
    sleep 0.01 until received
    assert_equal message_text, received.body
    receipt = nil
    ack_headers = {}
    if @client.protocol == Stomp::SPL_11 # 1.1 only
      ack_headers["subscription"] = received.headers["subscription"]
    end
    @client.acknowledge(received, ack_headers) {|r|
      receipt = r
      p [ "04", mn, "have_rcpt" ] if @tcldbg
    }
    p [ "05", mn, "ack_sent" ] if @tcldbg
    sleep 0.01 until receipt
    assert_not_nil receipt.headers['receipt-id']
    checkEmsg(@client) unless jruby?()
    p [ "99", mn, "ends" ] if @tcldbg
  end

  # Test Client subscribe
  def test_asynch_subscribe
    mn = "test_async_subscribe" if @tcldbg
    p [ "01", mn, "starts" ] if @tcldbg
    received = false
    @client.subscribe(make_destination) {|msg| received = msg}
    @client.publish make_destination, message_text
    sleep 0.01 until received

    assert_equal message_text, received.body
    checkEmsg(@client) unless jruby?()
    p [ "99", mn, "ends" ] if @tcldbg
  end

  # Test not ACKing messages.
  def test_noack
    mn = "test_noack" if @tcldbg
    p [ "01", mn, "starts" ] if @tcldbg

    @client.publish make_destination, message_text

    received = nil
    @client.subscribe(make_destination, :ack => :client) {|msg| received = msg}
    sleep 0.01 until received
    assert_equal message_text, received.body
    @client.close

    # was never acked so should be resent to next client

    @client = get_client()
    received2 = nil
    @client.subscribe(make_destination) {|msg| received2 = msg}
    sleep 0.01 until received2

    assert_equal message_text, received2.body
    assert_equal received.body, received2.body
    assert_equal received.headers['message-id'], received2.headers['message-id'] unless ENV['STOMP_RABBIT']
    checkEmsg(@client)
    p [ "99", mn, "ends" ] if @tcldbg  
  end unless RUBY_ENGINE =~ /jruby/

  # Test obtaining a RECEIPT via a listener.
  def test_receipts
    mn = "test_receipts" if @tcldbg
    p [ "01", mn, "starts" ] if @tcldbg

    receipt = false
    @client.publish(make_destination, message_text) {|r| receipt = r}
    sleep 0.1 until receipt
    assert_equal receipt.command, Stomp::CMD_RECEIPT
    message = nil
    @client.subscribe(make_destination) {|m| message = m}
    sleep 0.1 until message
    assert_equal message_text, message.body
    checkEmsg(@client) unless jruby?()
    p [ "99", mn, "ends" ] if @tcldbg
  end

  # Test requesting a receipt on disconnect.
  def test_disconnect_receipt
    mn = "test_disconnect_receipt" if @tcldbg
    p [ "01", mn, "starts" ] if @tcldbg

    @client.close :receipt => "xyz789"
    assert_not_nil(@client.disconnect_receipt, "should have a receipt")
    assert_equal(@client.disconnect_receipt.headers['receipt-id'],
      "xyz789", "receipt sent and received should match")
    p [ "99", mn, "ends" ] if @tcldbg
  end

  # Test publish and immediate subscribe.
  def test_publish_then_sub
    mn = "test_publish_then_sub" if @tcldbg
    p [ "01", mn, "starts" ] if @tcldbg

    @client.publish make_destination, message_text
    message = nil
    @client.subscribe(make_destination) {|m| message = m}
    sleep 0.01 until message

    assert_equal message_text, message.body
    checkEmsg(@client) unless jruby?() 
    p [ "99", mn, "ends" ] if @tcldbg
  end

  # Test that Client subscribe requires a block.
  def test_subscribe_requires_block
    mn = "test_subscribe_requires_block" if @tcldbg
    p [ "01", mn, "starts" ] if @tcldbg

    assert_raise(Stomp::Error::NoListenerGiven) do
      @client.subscribe make_destination
    end
    checkEmsg(@client) unless jruby?()
    p [ "99", mn, "ends" ] if @tcldbg
  end

  # Test transaction publish.
  def test_transactional_publish
    mn = "test_transactional_publish" if @tcldbg
    p [ "01", mn, "starts" ] if @tcldbg

    tid = "tx1A"
    @client.begin tid
    @client.publish make_destination, message_text, :transaction => tid
    @client.commit tid

    message = nil
    @client.subscribe(make_destination) {|m| message = m}
    sleep 0.01 until message

    assert_equal message_text, message.body
    checkEmsg(@client) unless jruby?()
    p [ "99", mn, "ends" ] if @tcldbg
  end unless ENV['STOMP_ARTEMIS']

  # Test transaction publish and abort.
  def test_transaction_publish_then_rollback
    mn = "test_transaction_publish_then_rollback" if @tcldbg
    p [ "01", mn, "starts" ] if @tcldbg

    tid = "txrb1"
    @client.begin tid
    @client.publish make_destination, "first_message", :transaction => tid
    @client.abort tid

    @client.begin tid
    @client.publish make_destination, "second_message", :transaction => tid
    @client.commit tid

    message = nil
    @client.subscribe(make_destination) {|m| message = m}
    sleep 0.01 until message
    assert_equal "second_message", message.body
    checkEmsg(@client) unless jruby?()
    p [ "99", mn, "ends" ] if @tcldbg
  end unless ENV['STOMP_ARTEMIS']

  # Test transaction publish and abort, receive with new client.
  # New client uses ack => client.
  def test_tran_ack_abrt_newcli_cli
    mn = "test_tran_ack_abrt_newcli_cli" if @tcldbg
    p [ "01", mn, "starts" ] if @tcldbg

    tid = "tx1B"
    @client.close if @client && @client.open? # allow tests to close
    @client = get_client()
    q = make_destination
    data = message_text
    @client.publish q, data

    @client.begin tid
    message = nil
    sid = nil
    if @client.protocol() == Stomp::SPL_10
      @client.subscribe(q, :ack => 'client') {|m| message = m}
    else # 1.1 and 1.2 are the same for this
      sid = @client.uuid()
      @client.subscribe(q, :ack => 'client', :id => sid) {|m| message = m}
    end
    sleep 0.01 until message
    assert_equal data, message.body
    case @client.protocol()
      when Stomp::SPL_10
        @client.acknowledge message, :transaction => tid
        checkEmsg(@client) unless jruby?()
      when Stomp::SPL_11
        @client.acknowledge message, :transaction => tid, :subscription => message.headers['subscription']
        checkEmsg(@client) unless jruby?()
      else # 1.2+
        @client.acknowledge message, :transaction => tid, :id => message.headers['ack']
        checkEmsg(@client) unless jruby?()
    end
    message = nil # reset
    @client.abort tid # now abort
    checkEmsg(@client) unless jruby?()
    # lets recreate the connection
    @client.close
    @client = get_client()
    sid = nil
    message2 = nil
    tid2 = "tx2A"
    @client.begin tid2
    if @client.protocol() == Stomp::SPL_10
      @client.subscribe(q, :ack => 'client') {|m| message2 = m}
    else # 1.1 and 1.2 are the same for this
      sid = @client.uuid()
      @client.subscribe(q, :ack => 'client', :id => sid) {|m| message2 = m}
    end
    sleep 0.01 until message2
    assert_not_nil message
    assert_equal data, message2.body
    case @client.protocol()
      when Stomp::SPL_10
        @client.acknowledge message2, :transaction => tid2
        checkEmsg(@client) unless jruby?()
      when Stomp::SPL_11
        @client.acknowledge message2, :transaction => tid2, :subscription => message2.headers['subscription']
        checkEmsg(@client) unless jruby?()
      else # 1.2+
        @client.acknowledge message2, :transaction => tid2, :id => message2.headers['ack']
        checkEmsg(@client) unless jruby?()
    end
    @client.commit tid2
    checkEmsg(@client) unless jruby?()
    @client.close
    p [ "99", mn, "ends" ] if @tcldbg
  end unless ENV['STOMP_ARTEMIS'] # See Artemis docs for 1.3, page 222

  # Test transaction publish and abort, receive with new client.
  # New client uses ack => auto.
  def test_tran_ack_abrt_newcli_auto
    mn = "test_tran_ack_abrt_newcli_auto" if @tcldbg
    p [ "01", mn, "starts" ] if @tcldbg

    tid = "tx1C"
    @client.close if @client && @client.open? # allow tests to close
    @client = get_client()
    q = make_destination
    data = message_text
    @client.publish q, data

    @client.begin tid
    message = nil
    sid = nil
    if @client.protocol() == Stomp::SPL_10
      @client.subscribe(q, :ack => 'client') {|m| message = m}
    else # 1.1 and 1.2 are the same for this
      sid = @client.uuid()
      @client.subscribe(q, :ack => 'client', :id => sid) {|m| message = m}
    end
    sleep 0.01 until message
    assert_equal data, message.body
    case @client.protocol()
      when Stomp::SPL_10
        @client.acknowledge message, :transaction => tid
        checkEmsg(@client) unless jruby?()
      when Stomp::SPL_11
        @client.acknowledge message, :transaction => tid, :subscription => message.headers['subscription']
        checkEmsg(@client) unless jruby?()
      else # 1.2+
        @client.acknowledge message, :transaction => tid, :id => message.headers['ack']
        checkEmsg(@client) unless jruby?()
    end
    message = nil # reset
    @client.abort tid # now abort
    checkEmsg(@client) unless jruby?()
    # lets recreate the connection
    @client.close

    @client = get_client()
    sid = nil
    message2 = nil
    tid2 = "tx2C"
    @client.begin tid2 
    if @client.protocol() == Stomp::SPL_10
      @client.subscribe(q, :ack => 'auto') {|m| message2 = m}
    else # 1.1 and 1.2 are the same for this
      sid = @client.uuid()
      @client.subscribe(q, :ack => 'auto', :id => sid) {|m| message2 = m}
    end
    sleep 0.01 until message2
    assert_not_nil message2
    assert_equal data, message2.body
    @client.commit tid2 
    checkEmsg(@client) unless jruby?()
    @client.close
    p [ "99", mn, "ends" ] if @tcldbg
  end unless ENV['STOMP_ARTEMIS'] # See Artemis docs for 1.3, page 222

  # Test that subscription destinations must be unique for a Client.
  def test_raise_on_multiple_subscriptions_to_same_make_destination
    mn = "test_raise_on_multiple_subscriptions_to_same_make_destination" if @tcldbg
    p [ "01", mn, "starts" ] if @tcldbg

    subscribe_dest = make_destination
    @client.subscribe(subscribe_dest) {|m| nil }
    assert_raise(Stomp::Error::DuplicateSubscription) do
      @client.subscribe(subscribe_dest) {|m| nil }
    end
    checkEmsg(@client) unless jruby?()
    p [ "99", mn, "ends" ] if @tcldbg
  end

  # Test that subscription IDs must be unique for a Client.
  def test_raise_on_multiple_subscriptions_to_same_id
    mn = "test_raise_on_multiple_subscriptions_to_same_id" if @tcldbg
    p [ "01", mn, "starts" ] if @tcldbg

    subscribe_dest = make_destination
    @client.subscribe(subscribe_dest, {'id' => 'myid'}) {|m| nil }
    assert_raise(Stomp::Error::DuplicateSubscription) do
      @client.subscribe(subscribe_dest, {'id' => 'myid'}) {|m| nil }
    end
    checkEmsg(@client) unless jruby?()
    p [ "99", mn, "ends" ] if @tcldbg
  end

  # Test that subscription IDs must be unique for a Client, mixed id specification.
  def test_raise_on_multiple_subscriptions_to_same_id_mixed
    mn = "test_raise_on_multiple_subscriptions_to_same_id_mixed" if @tcldbg
    p [ "01", mn, "starts" ] if @tcldbg

    subscribe_dest = make_destination
    @client.subscribe(subscribe_dest, {'id' => 'myid'}) {|m| nil }
    assert_raise(Stomp::Error::DuplicateSubscription) do
      @client.subscribe(subscribe_dest, {:id => 'myid'}) {|m| nil }
    end
    checkEmsg(@client)  unless jruby?()
    p [ "99", mn, "ends" ] if @tcldbg
  end

  # Test wildcard subscribe.  Primarily for AMQ.
  def  test_asterisk_wildcard_subscribe
    mn = "test_asterisk_wildcard_subscribe" if @tcldbg
    p [ "01", mn, "starts" ] if @tcldbg

    queue_base_name = make_destination
    queue1 = queue_base_name + ".a"
    queue2 = queue_base_name + ".b"
    send_message = message_text
    @client.publish queue1, send_message
    @client.publish queue2, send_message
    messages = []
    @client.subscribe(queue_base_name + ".*", :ack => 'client') do |m|
      messages << m
      @client.acknowledge(m)
    end
    Timeout::timeout(4) do
      sleep 0.1 while messages.size < 2
    end

    messages.each do |message|
      assert_not_nil message
      assert_equal send_message, message.body
    end
    results = [queue1, queue2].collect do |queue|
      messages.any? do |message|
        message_source = message.headers['destination']
        message_source == queue
      end
    end
    assert results.all?{|a| a == true }
    checkEmsg(@client)
    p [ "99", mn, "ends" ] if @tcldbg
  end unless ENV['STOMP_NOWILD']

  # Test wildcard subscribe with >.  Primarily for AMQ.
  def test_greater_than_wildcard_subscribe
    mn = "test_greater_than_wildcard_subscribe" if @tcldbg
    p [ "01", mn, "starts" ] if @tcldbg

    queue_base_name = make_destination + "."
    queue1 = queue_base_name + "foo.a"
    queue2 = queue_base_name + "bar.a"
    queue3 = queue_base_name + "foo.b"
    send_message = message_text
    @client.publish queue1, send_message
    @client.publish queue2, send_message
    @client.publish queue3, send_message
    messages = []
    # should subscribe to all three queues
    @client.subscribe(queue_base_name + ">", :ack => 'client') do |m|
      messages << m
      @client.acknowledge(m)
    end
    Timeout::timeout(4) do
      sleep 0.1 while messages.size < 3
    end

    messages.each do |message|
      assert_not_nil message
      assert_equal send_message, message.body
    end
    # make sure that the messages received came from the expected queues
    results = [queue1, queue2, queue3].collect do |queue|
      messages.any? do |message|
        message_source = message.headers['destination']
        message_source == queue
      end
    end
    assert results.all?{|a| a == true }
    checkEmsg(@client)
    p [ "99", mn, "ends" ] if @tcldbg
  end unless ENV['STOMP_NOWILD'] || ENV['STOMP_DOTQUEUE']

  # Test transaction with client side reacknowledge.
  def test_transaction_with_client_side_reack
    mn = "test_transaction_with_client_side_reack" if @tcldbg
    p [ "01", mn, "starts" ] if @tcldbg

    @client.close if @client && @client.open? # allow tests to close
    @client = get_client()
    q = make_destination
    data = message_text
    @client.publish q, data
    tid = "tx1D"
    @client.begin tid
    message = nil
    sid = nil
    if @client.protocol() == Stomp::SPL_10
      @client.subscribe(q, :ack => 'client') { |m| message = m }
    else
      sid = @client.uuid()
      @client.subscribe(q, :ack => 'client', :id => sid) { |m| message = m }
    end
    sleep 0.1 while message.nil?
    assert_equal data, message.body
    case @client.protocol()
      when Stomp::SPL_10
        @client.acknowledge message, :transaction => tid
        checkEmsg(@client) unless jruby?()
      when Stomp::SPL_11
        @client.acknowledge message, :transaction => tid, :subscription => message.headers['subscription']
        checkEmsg(@client) unless jruby?()
      else # 1.2+
        @client.acknowledge message, :transaction => tid, :id => message.headers['ack']
        checkEmsg(@client) unless jruby?()
    end
    message = nil
    @client.abort tid
    # Wait for redlivery (Client logic)
    sleep 0.1 while message.nil?
    assert_not_nil message
    assert_equal data, message.body
    tid2 = "tx2D"
    @client.begin tid2
    case @client.protocol()
      when Stomp::SPL_10
        @client.acknowledge message, :transaction => tid2
        checkEmsg(@client) unless jruby?()
      when Stomp::SPL_11
        @client.acknowledge message, :transaction => tid2, :subscription => message.headers['subscription']
        checkEmsg(@client) unless jruby?()
      else # 1.2+
        @client.acknowledge message, :transaction => tid2, :id => message.headers['ack']
        checkEmsg(@client) unless jruby?()
    end
    @client.commit tid2
    checkEmsg(@client) unless jruby?()
    @client.close
    @client = nil
    p [ "99", mn, "ends" ] if @tcldbg
  end unless ENV['STOMP_ARTEMIS']

  # Test that a connection frame is received.
  def test_connection_frame
    mn = "test_connection_frame" if @tcldbg
    p [ "01", mn, "starts" ] if @tcldbg

    assert_not_nil @client.connection_frame
    checkEmsg(@client)
    p [ "99", mn, "ends" ] if @tcldbg
  end unless RUBY_ENGINE =~ /jruby/

  # Test basic unsubscribe.
  def test_unsubscribe
    mn = "test_unsubscribe" if @tcldbg
    p [ "01", mn, "starts" ] if @tcldbg

    @client.close if @client && @client.open? # close setup work
    @client = nil
    message = nil
    dest = make_destination
    to_send = message_text
    client = get_client()
    sid = nil
    if client.protocol() == Stomp::SPL_10
      client.subscribe(dest, :ack => 'client') { |m| message = m }
    else
      sid = client.uuid()
      client.subscribe(dest, :ack => 'client', :id => sid) { |m| message = m }
    end
    client.publish dest, to_send
    Timeout::timeout(4) do
      sleep 0.01 until message
    end
    assert_equal to_send, message.body, "first body check"
    if client.protocol() == Stomp::SPL_10
      client.unsubscribe dest
    else
      client.unsubscribe dest, :id => sid
    end
    client.close
    #  Same message should remain on the queue.  Receive it again with ack=>auto.
    message_copy = nil
    client = get_client()
    if client.protocol() == Stomp::SPL_10
      client.subscribe(dest, :ack => 'auto') { |m| message_copy = m }
    else
      sid = client.uuid()
      client.subscribe(dest, :ack => 'auto', :id => sid) { |m| message_copy = m }
    end
    Timeout::timeout(4) do
      sleep 0.01 until message_copy
    end
    assert_equal to_send, message_copy.body, "second body check"
    assert_equal message.headers['message-id'], message_copy.headers['message-id'], "header check" unless ENV['STOMP_RABBIT']
    checkEmsg(client) unless jruby?()
    client.close
    p [ "99", mn, "ends" ] if @tcldbg
  end

  # Test subscribe from a worker thread.
  def test_thread_one_subscribe
    mn = "test_thread_one_subscribe" if @tcldbg
    p [ "01", mn, "starts" ] if @tcldbg

    msg = nil
    dest = make_destination
    Thread.new(@client) do |acli|
      no_rep_error()
      if acli.protocol() == Stomp::SPL_10
        acli.subscribe(dest) { |m| msg = m }
      else
        acli.subscribe(dest, :id => acli.uuid()) { |m| msg = m }
      end
      Timeout::timeout(4) do
        sleep 0.01 until msg
      end
    end
    #
    @client.publish(dest, message_text)
    sleep 1
    assert_not_nil msg
    checkEmsg(@client)
    p [ "99", mn, "ends" ] if @tcldbg
  end unless RUBY_ENGINE =~ /jruby/

  # Test subscribe from multiple worker threads.
  def test_thread_multi_subscribe
    mn = "test_thread_multi_subscribe" if @tcldbg
    p [ "01", mn, "starts" ] if @tcldbg

    #
    lock = Mutex.new
    msg_ctr = 0
    dest = make_destination
    1.upto(@max_threads) do |tnum|
      # Threads within threads .....
      Thread.new(@client) do |acli|
        no_rep_error()
        # this is ugly .....
        if acli.protocol() == Stomp::SPL_10
          acli.subscribe(dest) { |m|
            _ = m
            lock.synchronize do
              msg_ctr += 1
            end
            # Simulate message processing
            sleep 0.05
          }
        else
          acli.subscribe(dest, :id => acli.uuid()) { |m|
            _ = m
            lock.synchronize do
              msg_ctr += 1
            end
            # Simulate message processing
            sleep 0.05
          }
        end
      end
    end
    #
    1.upto(@max_msgs) do |mnum|
      msg = Time.now.to_s + " #{mnum}"
      @client.publish(dest, msg)
    end
    #
    max_sleep = (RUBY_VERSION =~ /1\.8\.6/) ? 30 : 5
    sleep_incr = 0.10
    total_slept = 0
    while true
      break if @max_msgs == msg_ctr
      total_slept += sleep_incr
      break if total_slept > max_sleep
      sleep sleep_incr
    end
    assert_equal @max_msgs, msg_ctr
    checkEmsg(@client) unless jruby?()
    p [ "99", mn, "ends" ] if @tcldbg
  end

  # Test that methods detect no client connection is present.
  def test_closed_checks_client
    mn = "test_closed_checks_client" if @tcldbg
    p [ "01", mn, "starts" ] if @tcldbg

    @client.close
    #
    assert_raise Stomp::Error::NoCurrentConnection do
      m = Stomp::Message.new("")
      @client.acknowledge(m) {|r| _ = r}
    end
    #
    assert_raise Stomp::Error::NoCurrentConnection do
      @client.begin("dummy_data")
    end
    #
    assert_raise Stomp::Error::NoCurrentConnection do
      @client.commit("dummy_data")
    end
    #
    assert_raise Stomp::Error::NoCurrentConnection do
      @client.abort("dummy_data")
    end
    #
    assert_raise Stomp::Error::NoCurrentConnection do
      @client.subscribe("dummy_data", {:ack => 'auto'}) {|msg| _ = msg}
    end
    #
    assert_raise Stomp::Error::NoCurrentConnection do
      @client.unsubscribe("dummy_data")
    end
    #
    assert_raise Stomp::Error::NoCurrentConnection do
      @client.publish("dummy_data","dummy_data")
    end
    #
    assert_raise Stomp::Error::NoCurrentConnection do
      @client.unreceive("dummy_data")
    end
    #
    assert_raise Stomp::Error::NoCurrentConnection do
      @client.close("dummy_data")
    end
    p [ "99", mn, "ends" ] if @tcldbg
  end

  # test JRuby detection
  def test_jruby_presence
    mn = "test_jruby_presence" if @tcldbg
    p [ "01", mn, "starts" ] if @tcldbg

    if defined?(RUBY_ENGINE) && RUBY_ENGINE =~ /jruby/
      assert @client.jruby?
    else
      assert !@client.jruby?
    end
    p [ "99", mn, "ends" ] if @tcldbg
  end

  # test max redeliveries is not broken (6c2c1c1)
  def test_max_redeliveries
    mn = "test_max_redeliveries" if @tcldbg
    p [ "01", mn, "starts" ] if @tcldbg

    @client.close
    2.upto(2) do |max_re|
      rdmsg = "To Be Redelivered: #{max_re.to_s}"
      dest = make_destination + ".#{max_re.to_s}"
      @client = get_client()
      sid = "sid_max_redeliveries_#{max_re.to_s}"
      received = nil
      rm_actual = 0
      sh = @client.protocol() == Stomp::SPL_10 ?  {} : {:id => sid}
      @client.subscribe(dest, sh) {|msg|
        rm_actual += 1
        @client.unreceive(msg, :max_redeliveries => max_re,
			:dead_letter_queue => make_dlq())
        received = msg if rm_actual - 1 == max_re
      }
      @client.publish(dest, rdmsg)
      sleep 0.01 until received
      assert_equal rdmsg, received.body
      sleep 0.5
      @client.unsubscribe dest, sh
      assert_equal max_re, rm_actual - 1
      @client.close
    end
    p [ "99", mn, "ends" ] if @tcldbg
  end unless ENV['STOMP_ARTEMIS'] # need to investigate this, but skip
  # Artemis for now

  # test issue99, OK values
  def test_cli_iss99_ok

    return unless host() == "localhost" && port() == 61613
    mn = "test_cli_iss99_ok" if @tcldbg
    p [ "01", mn, "starts" ] if @tcldbg

    @client.close
    #
    ok_vals = dflt_data_ok()
    ok_vals.each do |hsv|
      cli = Stomp::Client.open(hsv)
      cli.close
    end
    p [ "99", mn, "ends" ] if @tcldbg
  end

  # test issue99, exception values
  def test_cli_iss99_ex
    return unless host() == "localhost" && port() == 61613
    mn = "test_cli_iss99_ex" if @tcldbg
    p [ "01", mn, "starts" ] if @tcldbg

    @client.close
    #
    ex_vals = dflt_data_ex()
    ex_vals.each do |hsv|
      assert_raise ArgumentError do
        _ = Stomp::Client.open(hsv)
      end
    end
    p [ "99", mn, "ends" ] if @tcldbg
  end

  def test_cli_nodest_sub
    mn = "test_cli_nodest_sub" if @tcldbg
    p [ "01", mn, "starts" ] if @tcldbg

    assert_raise Stomp::Error::DestinationRequired do
      @client.subscribe(nil) {|msg| puts msg}
    end
    p [ "99", mn, "ends" ] if @tcldbg
  end

  def test_cli_nodest_unsub
    mn = "test_cli_nodest_unsub" if @tcldbg
    p [ "01", mn, "starts" ] if @tcldbg

    assert_raise Stomp::Error::DestinationRequired do
      @client.unsubscribe(nil)
    end
    p [ "99", mn, "ends" ] if @tcldbg
  end

  def test_cli_nodest_pub
    mn = "test_cli_nodest_pub" if @tcldbg
    p [ "01", mn, "starts" ] if @tcldbg

    assert_raise Stomp::Error::DestinationRequired do
      @client.publish(nil, "msg")
    end
    p [ "99", mn, "ends" ] if @tcldbg
  end

  private
    def message_text
      name = caller_method_name unless name
      "test_client#" + name
    end
end
