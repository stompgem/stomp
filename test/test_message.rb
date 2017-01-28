# -*- encoding: us-ascii -*-

#
# !!!!
#
# This can *NOT* currently be marked as UTF-8 encoded. It uses invalid UTF-8
# sequences for testing.  Tests will fail under 1.9.x+ if this file is marked
# as UTF-8 encoded.  Tests will fail under 2.0.0 if this file is *NOT* marked 
# as US-ASCII.
#

if Kernel.respond_to?(:require_relative)
  require_relative("test_helper")
else
  $:.unshift(File.dirname(__FILE__))
  require 'test_helper'
end

#
# Test Ruby 1.8 with $KCODE='U'
#

=begin

  Main class for testing Stomp::Message.

=end
class TestMessage < Test::Unit::TestCase
  include TestBase
  #
  def setup
		$KCODE = 'U' if RUBY_VERSION =~ /1\.8/
    @conn = get_connection()
    # Message body data
		@messages = [
			"normal text message",
			"bad byte: \372",
			"\004\b{\f:\tbody\"\001\207\004\b{\b:\016statusmsg\"\aOK:\017statuscodei\000:\tdata{\t:\voutput\"3Enabled, not running, last run 693 seconds ago:\frunningi\000:\fenabledi\006:\flastrunl+\aE\021\022M:\rsenderid\"\032xx.xx.xx.xx:\016requestid\"%849d647bbe3e421ea19ac9f947bbdde4:\020senderagent\"\fpuppetd:\016msgtarget\"%/topic/mcollective.puppetd.reply:\thash\"\001\257ZdQqtaDmmdD0jZinnEcpN+YbkxQDn8uuCnwsQdvGHau6d+gxnnfPLUddWRSb\nZNMs+sQUXgJNfcV1eVBn1H+Z8QQmzYXVDMqz7J43jmgloz5PsLVbN9K3PmX/\ngszqV/WpvIyAqm98ennWqSzpwMuiCC4q2Jr3s3Gm6bUJ6UkKXnY=\n:\fmsgtimel+\a\372\023\022M"
		]
		#
  end

  def teardown
    @conn.disconnect if @conn # allow tests to disconnect
  end

	# Various message bodies, including the failing test case reported
  def test_0010_kcode
		#
		dest = make_destination
    if @conn.protocol == Stomp::SPL_10
      @conn.subscribe dest
    else
      sh = {}
      @conn.subscribe dest, sh, @conn.uuid()
    end
		@messages.each do |abody|
		  @conn.publish dest, abody
			msg = @conn.receive
			assert_instance_of Stomp::Message , msg, "type check for #{abody}"
			assert_equal abody, msg.body, "equal check for #{abody}"
		end
  end

	# All possible byte values
  def test_0020_kcode
		#
		abody = ""
		"\000".upto("\377") {|abyte| abody << abyte } 
		#
		dest = make_destination
    if @conn.protocol == Stomp::SPL_10
      @conn.subscribe dest
    else
      sh = {}
      @conn.subscribe dest, sh, @conn.uuid()
    end
	  @conn.publish dest, abody
		msg = @conn.receive
		assert_instance_of Stomp::Message , msg, "type check for #{abody}"
		assert_equal abody, msg.body, "equal check for #{abody}"
  end

	# A single byte at a time
  def test_0030_kcode
		#
		dest = make_destination
    if @conn.protocol == Stomp::SPL_10
      @conn.subscribe dest
    else
      sh = {:id => @conn.uuid()}
      @conn.subscribe dest, sh
    end
		#
		"\000".upto("\377") do |abody|
			@conn.publish dest, abody
			msg = @conn.receive
			assert_instance_of Stomp::Message , msg, "type check for #{abody}"
			assert_equal abody, msg.body, "equal check for #{abody}"
		end
  end

	# Test various valid and invalid frames.
	def test_0040_msg_create
		#
		assert_raise(Stomp::Error::InvalidFormat) {
			_ = Stomp::Message.new("junk", false)
		}
		#
		assert_raise(Stomp::Error::InvalidFormat) {
			_ = Stomp::Message.new("command\njunk", false)
		}
		#
		assert_raise(Stomp::Error::InvalidFormat) {
			_ = Stomp::Message.new("command\nheaders\n\njunk", false)
		}
		#
		assert_raise(Stomp::Error::InvalidServerCommand) {
			_ = Stomp::Message.new("junkcommand\nheaders\n\njunk\0\n\n", false)
		}
		#
		assert_raise(Stomp::Error::InvalidFormat) {
			_ = Stomp::Message.new("ERROR\nbadheaders\n\njunk\0\n\n", false)
		}
		#

    _ = Stomp::Message.new("CONNECTED\nh1:val1\n\njunk\0\n", false)
    _ = Stomp::Message.new("MESSAGE\nh1:val1\n\njunk\0\n", false)
    _ = Stomp::Message.new("MESSAGE\nh2:val2\n\n\0", false)
    _ = Stomp::Message.new("RECEIPT\nh1:val1\n\njunk\0\n", false)
    _ = Stomp::Message.new("ERROR\nh1:val1\n\njunk\0\n", false)

	end

	# Test multiple headers with the same key
  def test_0050_mh_msg_create
    aframe = bframe = nil
    amsg = "MESSAGE\n" +
      "h1:val1\n" + 
      "h2:val3\n" + 
      "h2:val2\n" + 
      "h2:val1\n" + 
      "h3:val1\n" + 
      "\n" +
      "payload" +
      "\0\n"
    aframe = Stomp::Message.new(amsg, false)
    bframe = Stomp::Message.new(amsg, true)
    #
    assert aframe.headers["h2"].is_a?(String), "Expected a String"
    assert_equal "val3", aframe.headers["h2"], "Expected 1st value"
    #
    assert bframe.headers["h2"].is_a?(Array), "Expected an Array"
    assert_equal 3, bframe.headers["h2"].length, "Expected 3 values"
    assert_equal "val3", bframe.headers["h2"][0], "Expected val3"
    assert_equal "val2", bframe.headers["h2"][1], "Expected val2"
    assert_equal "val1", bframe.headers["h2"][2], "Expected val1"
  end

	# Test headers with empty key / value
  def test_0060_hdr_ekv
    #
    amsg = "MESSAGE\n" +
      "h1:val1\n" +
      ":val3\n" +
      "h2:val2\n" +
      "\n" +
      "payload" +
      "\0\n"
    assert_raise Stomp::Error::ProtocolErrorEmptyHeaderKey do
      _ = Stomp::Message.new(amsg, false)
    end
    assert_raise Stomp::Error::ProtocolErrorEmptyHeaderKey do
      _ = Stomp::Message.new(amsg, true)
    end
    #
    amsg = "MESSAGE\n" +
      "h1:val1\n" +
      "h2:val3\n" +
      "h3:\n" +
      "\n" +
      "payload" +
      "\0\n"
    assert_raise Stomp::Error::ProtocolErrorEmptyHeaderValue do
      _ = Stomp::Message.new(amsg, false)
    end
    _ = Stomp::Message.new(amsg, true)
  end

end

