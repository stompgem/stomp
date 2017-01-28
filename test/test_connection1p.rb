# -*- encoding: utf-8 -*-

if Kernel.respond_to?(:require_relative)
  require_relative("test_helper")
else
  $:.unshift(File.dirname(__FILE__))
  require 'test_helper'
end

=begin

  Main class for testing Stomp::Connection instances, protocol levels 1.1+.

=end
class TestConnection1P < Test::Unit::TestCase
  include TestBase
  
  def setup
    @conn = get_connection()
  end

  def teardown
    @conn.disconnect if @conn.open? # allow tests to disconnect
  end

  # Test basic connection open.
  def test_conn_1p_0000
    assert @conn.open?
  end

  # Test missing connect headers - part 1.
  def test_conn_1p_0010
    @conn.disconnect
    #
    cha = {:host => "localhost"}
    assert_raise Stomp::Error::ProtocolErrorConnect do
      _ = Stomp::Connection.open(user, passcode, host, port, false, 5, cha)
    end    
    #
    chb = {"accept-version" => "1.0"}
    assert_raise Stomp::Error::ProtocolErrorConnect do
      _ = Stomp::Connection.open(user, passcode, host, port, false, 5, chb)
    end    
  end

  # Test missing connect headers - part 2.
  def test_conn_1p_0015
    @conn.disconnect
    #
    cha = {:host => "localhost"}
    hash = { :hosts => [ 
      {:login => user, :passcode => passcode, :host => host, :port => port, :ssl => nil},
      ],
      :reliable => true, # Note, issue #57 discussion
      :connect_headers => cha,
      :stompconn => get_stomp_conn(),
      :usecrlf => get_crlf(),
      :initial_reconnect_delay => 0.1,
      :max_reconnect_delay => 30,
      :use_exponential_back_off => true,
      :back_off_multiplier => 2,
      :max_reconnect_attempts => 10,
    }
    assert_raise Stomp::Error::ProtocolErrorConnect do
      _ = Stomp::Connection.open(hash)
    end
    hash[:connect_headers] = {"accept-version" => "1.1"}
    assert_raise Stomp::Error::ProtocolErrorConnect do
      _ = Stomp::Connection.open(hash)
    end
  end

  # Test requesting only a 1.0 connection.
  def test_conn_1p_0020
    @conn.disconnect
    #
    cha = {:host => "localhost", "accept-version" => "1.0"}
    cha[:host] = "/" if ENV['STOMP_RABBIT']
    conn = nil
    conn = Stomp::Connection.open(user, passcode, host, port, false, 5, cha)
    conn.disconnect
    assert_equal conn.protocol, Stomp::SPL_10
  end

  # Test requesting only a 1.1+ connection.
  def test_conn_1p_0030
    @conn.disconnect
    #
    cha = get_conn_headers()
    conn = nil
    conn = Stomp::Connection.open(user, passcode, host, port, false, 5, cha)
    conn.disconnect
    assert conn.protocol >= Stomp::SPL_11
  end

  # Test basic request for no heartbeats.
  def test_conn_1p_0040
    @conn.disconnect
    #
    cha = get_conn_headers()    
    cha["heart-beat"] = "0,0" # No heartbeats
    conn = nil
    conn = Stomp::Connection.open(user, passcode, host, port, false, 5, cha)
    conn.disconnect
    assert conn.protocol >= Stomp::SPL_11
  end

  # Test malformed heartbeat header.
  def test_conn_1p_0050
    @conn.disconnect
    #
    cha = get_conn_headers()    
    cha["heart-beat"] = "10,10,20" # Bad header Heartbeats
    conn = nil
    assert_raise Stomp::Error::InvalidHeartBeatHeaderError do
      conn = Stomp::Connection.open(user, passcode, host, port, false, 5, cha)
    end
  end

  # Test malformed heartbeat header.
  def test_conn_11h_0060
    @conn.disconnect
    #
    cha = get_conn_headers()
    cha["heart-beat"] = "a,10" # Bad header Heartbeats
    conn = nil
    assert_raise Stomp::Error::InvalidHeartBeatHeaderError do
      conn = Stomp::Connection.open(user, passcode, host, port, false, 5, cha)
    end
  end

  # Test a valid heartbeat header.
  def test_conn_1p_0070
    @conn.disconnect
    #
    cha = get_conn_headers()    
    cha["heart-beat"] = "500,1000" # Valid heart beat headers
    conn = nil
    conn = Stomp::Connection.open(user, passcode, host, port, false, 5, cha)
    conn.disconnect
    assert conn.hbsend_interval > 0
    assert conn.hbrecv_interval > 0
  end

  # Test only sending heartbeats.
  def test_conn_1p_0080
    @conn.disconnect
    #
    cha = get_conn_headers()    
    cha["heart-beat"] = "10000,0" # Valid heart beat headers, send only
    conn = nil
    logger = Tlogger.new
    conn = Stomp::Connection.open(user, passcode, host, port, false, 5, cha)
    conn.set_logger(logger)
    sleep 65
    conn.set_logger(nil)
    conn.disconnect
    hb_asserts_send(conn)
  end if ENV['STOMP_HB11LONG']

  # Test only receiving heartbeats.
  def test_conn_1p_0090
    @conn.disconnect
    #
    cha = get_conn_headers()    
    cha["heart-beat"] = "0,6000" # Valid heart beat headers, receive only
    conn = nil
    logger = Tlogger.new
    conn = Stomp::Connection.open(user, passcode, host, port, false, 5, cha)
#      m = conn.receive # This will hang forever .....
    conn.set_logger(logger)
    sleep 65
    conn.set_logger(nil)
    conn.disconnect
    hb_asserts_recv(conn)
  end if ENV['STOMP_HB11LONG']

  # Test sending and receiving heartbeats.
  def test_conn_1p_0100
    @conn.disconnect
    #
    cha = get_conn_headers()    
    cha["heart-beat"] = "5000,10000" # Valid heart beat headers, send and receive
    conn = nil
    logger = Tlogger.new
    conn = Stomp::Connection.open(user, passcode, host, port, false, 5, cha)
#      m = conn.receive # This will hang forever .....
    conn.set_logger(logger)
    sleep 65
    conn.set_logger(nil)
    conn.disconnect
    hb_asserts_both(conn)
  end if ENV['STOMP_HB11LONG']

  # Test valid UTF8 data.
  def test_conn_1p_0110
    @conn.disconnect
    #
    cha = get_conn_headers()    
    cha["heart-beat"] = "0,0" # No heartbeats
    conn = nil
    conn = Stomp::Connection.open(user, passcode, host, port, false, 5, cha)
    good_data = [
      "\x41\xc3\xb1\x42",
      "\xc2\x80", # 2 byte characters
      "\xc2\xbf",
      "\xdf\x80",
      "\xdf\xbf",
      "\xe0\xa0\x80", # 3 byte characters
      "\xe0\xbf\x80",
      "\xe0\xa0\xbf",
      "\xe0\xbf\xbf",
      "\xf1\x80\x80\x80", # 4 byte characters
      "\xf1\xbf\xbf\xbf",
      "\xf2\x80\x80\x80",
      "\xf2\xbf\xbf\xbf",
      "\xf3\x80\x80\x80",
      "\xf3\xbf\xbf\xbf",
    ]
    good_data.each do |string|
      assert conn.valid_utf8?(string), "good unicode specs 01: #{string}"
    end
    conn.disconnect
  end

  # Test invalid UTF8 data.
  def test_conn_1p_0120
    @conn.disconnect
    #
    cha = get_conn_headers()    
    cha["heart-beat"] = "0,0" # No heartbeats
    conn = nil
    conn = Stomp::Connection.open(user, passcode, host, port, false, 5, cha)
    bad_data = [
      "\x41\xc2\xc3\xb1\x42",
      "\xed\xa0\x80", # UTF-16 surrogate halves
      "\xed\xad\xbf",
      "\xed\xae\x80",
      "\xed\xaf\xbf",
      "\xed\xb0\x80",
      "\xed\xbe\x80",
      "\xed\xbf\xbf",
      "\xc0", # Single bytes
      "\xc1",
      "\xf5","\xf6","\xf7","\xf8","\xf9","\xfa","\xfb","\xfc",
      "\xfd","\xfe","\xff",
      "\xc0\x80", # Not shortest representation
      "\xc1\x80",
      "\xc0\x30",
      "\xc1\x30",
      "\xe0\x80\x80",
      "\xf0\x80\x80\x80",
    ]
    bad_data.each do |string|
      assert !conn.valid_utf8?(string), "bad unicode specs 01: #{string}"
    end
    conn.disconnect
  end

  # Repeated headers test. Brokers have a lot of freedom given the verbiage
  # in the specs.
  def test_conn_1p_0124
    dest = make_destination
    msg = "payload: #{Time.now.to_f}"
    shdrs = { "key1" => "val1", "key2" => "val2",
      "key3" => ["kv3", "kv2", "kv1"] }
    @conn.publish dest, msg, shdrs
    #
    sid = @conn.uuid()
    @conn.subscribe dest, :id => sid
    #
    received = @conn.receive
    assert_equal msg, received.body
    if @conn.protocol != Stomp::SPL_10
      assert_equal shdrs["key3"], received.headers["key3"] unless ENV['STOMP_RABBIT'] || ENV['STOMP_AMQ11'] || ENV['STOMP_ARTEMIS']
    else
      assert_equal "kv3", received.headers["key3"]
    end
    #
    @conn.unsubscribe dest, :id => sid
  end

  # Test frozen headers.
  def test_conn_1p_0127
    dest = make_destination
    sid = @conn.uuid()
    sid.freeze
    @conn.subscribe dest, :id => sid
  end

  # Test heartbeats with send and receive.
  def test_conn_1p_0130
    @conn.disconnect
    #
    cha = get_conn_headers()    
    cha["heart-beat"] = "10000,6000" # Valid heart beat headers, send and receive
    conn = nil
    logger = Tlogger.new
    conn = Stomp::Connection.open(user, passcode, host, port, false, 5, cha)
#      m = conn.receive # This will hang forever .....
    conn.set_logger(logger)
    sleep 65
    conn.set_logger(nil)
    conn.disconnect
    hb_asserts_both(conn)
  end if ENV['STOMP_HB11LONG']

  # Test heartbeats with send and receive.
  def test_conn_1p_0135
    @conn.disconnect
    #
    cha = get_conn_headers()    
    cha["heart-beat"] = "10000,1000" # Valid heart beat headers, send and receive
    conn = nil
    logger = Tlogger.new
    conn = Stomp::Connection.open(user, passcode, host, port, false, 5, cha)
#      m = conn.receive # This will hang forever .....
    conn.set_logger(logger)
    sleep 65
    conn.set_logger(nil)
    conn.disconnect
    hb_asserts_both(conn)
  end if ENV['STOMP_HB11LONG']

  # Test heartbeats with send and receive.
  def test_conn_1p_0140
    @conn.disconnect
    #
    cha = get_conn_headers()    
    cha["heart-beat"] = "1000,10000" # Valid heart beat headers, send and receive
    conn = nil
    logger = Tlogger.new
    conn = Stomp::Connection.open(user, passcode, host, port, false, 5, cha)
#      m = conn.receive # This will hang forever .....
    conn.set_logger(logger)
    sleep 65
    conn.set_logger(nil)
    conn.disconnect
    hb_asserts_both(conn)
  end if ENV['STOMP_HB11LONG']

  # Test very basic encoding / decoding of headers
  def test_conn_1p_0200
    @conn.disconnect
    #
    cha = get_conn_headers()    
    conn = Stomp::Connection.open(user, passcode, host, port, false, 5, cha)
    msg = "payload: #{Time.now.to_f}"
    dest = make_destination
    shdrs = { "ab:cd" => "ef:gh", "a\nb" => "c\nd", "x\\y" => "z\\s" }
    if conn.protocol >= Stomp::SPL_12
      shdrs["bb\rcc"] = "dd\ree"
    end
    conn.publish dest, msg, shdrs
    #
    sid = conn.uuid()
    conn.subscribe dest, :id => sid
    #
    received = conn.receive
    assert_equal msg, received.body
    #
    shdrs.each_pair {|k,v|
      assert received.headers.has_key?(k), "Key not found: #{k}"
      assert received.headers.has_value?(v), "Value not found: #{v}"
      assert received.headers[k] == v, "Mismatch: #{k},#{v}"
    }
    conn.disconnect
  end unless ENV['STOMP_RABBIT']

  # Test that 1.1+ connections do not break suppress_content_length
  # (Issue #52)
  def test_conn_1p_0210
    msg = "payload: #{Time.now.to_f}"
    dest = make_destination
    shdrs = { :suppress_content_length => true }
    @conn.publish dest, msg, shdrs
    #
    sid = @conn.uuid()
    @conn.subscribe dest, :id => sid
    #
    received = @conn.receive
    assert_equal msg, received.body
    assert_nil received.headers["content-length"], "No content length expected."
  end if ENV['STOMP_AMQ11']

private

  def hb_asserts_both(conn)
    assert conn.hbsend_interval > 0
    assert conn.hbrecv_interval > 0
    assert conn.hbsend_count > 0
    assert conn.hbrecv_count > 0
  end

  def hb_asserts_send(conn)
    assert conn.hbsend_interval > 0
    assert conn.hbrecv_interval == 0
    assert conn.hbsend_count > 0
    assert conn.hbrecv_count == 0
  end

  def hb_asserts_recv(conn)
    assert conn.hbsend_interval == 0
    assert conn.hbrecv_interval > 0
    assert conn.hbsend_count == 0
    assert conn.hbrecv_count > 0
  end

end if ENV['STOMP_TEST11p']

