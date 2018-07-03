# -*- encoding: utf-8 -*-

#
# The current require dance for different Ruby versions.
# Change this to suit your requirements.
#
if Kernel.respond_to?(:require_relative)
  require_relative("./stomp12_common")
else
  $LOAD_PATH << File.dirname(__FILE__)
  require "stomp12_common"
end
include Stomp12Common
#
# == Stomp 1.2 Receive Example 1
#
# Purpose: to demonstrate receiving messages using Stomp 1.2.
#
class Receive12Example1
  # Initialize.
  def initialize
  end
  # Run example.
  def run
    conn = get_connection() # Use helper method to obtain a Stomp#connection
    raise "Unexpected protocol level" if conn.protocol != Stomp::SPL_12
    #
    # To start receiving messages, you must first subscribe.  This is similar
    # to using Stomp 1.0.
    #
    # However, with Stomp 1.2:
    #
    # * for subscribe, the 'id' header is now _required_
    # * for unsubscribe, the 'id' header is now _required_
    #
    # The 'id' header specifies a 'subscription id' that _must_ be unique for
    # the current session.
    #
    qname = "/queue/nodea.nodeb.nodec"
    #
    # Here is an example of allowed functionality in 1.0 that is not allowed in 1.1:
    #
    begin
      conn.subscribe qname
    rescue RuntimeError => sre
      puts "Rescue: #{sre}, #{sre.message}"
    end
    #
    # So, you must specify an 'id' header.  And it must be unique within the
    # current session.
    #
    # You can build your own unique ids of course.  That is a valid option.
    # In order to provide you with some assistance in generating unique ids,
    # two convenience methods are provided with the connection:
    #
    # * sha1 - generate a sha1 hash of some data you supply.  This may be sufficient for many purposes.
    # * uuid - generate a type 4 UUID.  This would be sufficient in all cases.
    #
    # Get a sha1:
    #
    sha1 = conn.sha1(qname) # sha1 of the queue name perhaps
    puts "Queue name: #{qname}, sha1: #{sha1}"
    #
    # Or perhaps a different sha1:
    #
    tn = Time.now.to_f.to_s # Maybe unique itself.
    sha1 = conn.sha1(tn)
    puts "Time now: #{tn}, sha1: #{sha1}"
    #
    # Or a Type 4 UUID:
    #
    uuid = conn.uuid()
    puts "Type 4 UUID: #{uuid}"
    #
    # You can specify the 'id' in the subscribe call in one of two ways:
    #
    # a) In the headers parameter
    # b) In the third positional parameter, the subId
    #
    # So, using the 'uuid', either:
    #
    # a) conn.subscribe qname, {'id' => uuid}
    # b) conn.subscribe qname, {}, uuid
    #
    conn.subscribe qname, {'id' => uuid} # First style
    #
    # Within a session, you may not subscribe to the same subscription id.
    #
    begin
      conn.subscribe qname, {'id' => uuid} # Second time
    rescue RuntimeError => sre
      puts "Rescue (expected error): #{sre}, #{sre.message}"
    end
    #
    # Once you have subscribed, you may receive as usual
    #
    1.upto(nmsgs()) do
      received = conn.receive
      puts "Received data: #{received.body}"
      puts "Received headers: #{received.headers}"
      received.headers.each_pair do |k, v|
        vs = v.unpack("H2" * v.length)
        puts "Key #{k}:\n\tValue #{v}-\n\tValueHex #{vs}"
      end
    end
    #
    # For unsubscribe, you must use the 'id' you used on subscribe.
    #
    # You have the same options for placing this id in the headers or in the 3rd
    # positional parameter.
    #
    conn.unsubscribe qname, {}, uuid # Second style
    #
    # And finally, disconnect.
    #
    conn.disconnect
  end
end
#
e = Receive12Example1.new
e.run

