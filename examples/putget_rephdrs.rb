# -*- encoding: utf-8 -*-

#
# The current require dance for different Ruby versions.
# Change this to suit your requirements.
#
if Kernel.respond_to?(:require_relative)
  require_relative("./stomp11_common")
else
  $LOAD_PATH << File.dirname(__FILE__)
  require "stomp11_common"
end
include Stomp11Common
#
# == Stomp 1.1 Send/Receive Example - Repeated Headers
#
# Purpose: to demonstrate sending and receiving using Stomp 1.1, and an unusual
# aspect of the specification.  What is demonstrated here is the use of
# 'repeated headers'. Note that brokers MAY support repeated headers as
# demonstrated, but are not required to provide this support. This example
# should run against the Apollo broker.  It will *not* currently run against
# RabbitMQ.  YMMV depending on your broker.
#
# See: http://stomp.github.com/stomp-specification-1.1.html#Repeated_Header_Entries
#
class RepeatedHeadersExample
  # Initialize.
  def initialize
  end
  # Run example.
  def run
    conn = get_connection() # Use helper method to obtain a Stomp#connection
    raise "Unexpected protocol level" if conn.protocol != Stomp::SPL_11
    #
    # The gem supports repeated headers by allowing the 'value' part of a header
    # to be an Array instance.
    #
    # On 'publish', all values in the Array are placed on the wire and sent to the
    # broker in order.
    #
    # On 'receive', if repeated headers are detected, an Array instance is created
    # to hold the repeated values.  This is presented the the calling client to
    # be processed per client requirements.
    #
    qname = "/queue/nodea.nodeb.nodec"
    data = "message payload: #{Time.now.to_f}"
    key2_repeats = ["key2val3", "key2val2", "key2val1" ]
    headers = {"key1" => "value1",  # A normal header
      "key2" => key2_repeats,       # A repeated header
      "key3" => "value3",           # Another normal header
    }
    #
    # Ship it.
    #
    conn.publish qname, data , headers
    puts "Sent data: #{data}"
    #
    # Receive phase.
    #
    uuid = conn.uuid()
    conn.subscribe qname, {"id" => uuid}
    received = conn.receive
    conn.unsubscribe qname, {"id" => uuid}
    #
    # Check that we received what we sent.
    #
    raise "Unexpected payload" unless data == received.body
    raise "Missing key" unless received.headers["key2"]
    raise "Repeats not present" unless received.headers.has_value?(key2_repeats)
    raise "Unexpected repeat values" unless key2_repeats == received.headers["key2"]
    #
    # Demonstrate how to process repeated headers received by display of those
    # received headers for a visual check.
    #
    received.headers.each_pair do |k,v|
      if v.is_a?(Array)
        v.each do |e|
          puts "#{k}:#{e}"
        end
      else
        puts "#{k}:#{v}"
      end
    end
    #
    # And finally, disconnect.
    #
    conn.disconnect
  end
end
#
e = RepeatedHeadersExample.new
e.run

