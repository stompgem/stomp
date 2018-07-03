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
# == Stomp 1.2 Publish Example
#
# Purpose: to demonstrate sending messages using Stomp 1.2.
#
class Publish12Example1
  # Initialize.
  def initialize
  end
  # Run example.
  def run
    conn = get_connection() # Use helper method to obtain a Stomp#connection
    raise "Unexpected protocol level" if conn.protocol != Stomp::SPL_12
    #
    # Publishing simple data is as it was with Stomp 1.0.
    #
    # Note: Stomp 1.2 brokers seem to prefer using '.' as delimiters in queue
    # name spaces. Hence, the queue name used here.
    #
    qname = "/queue/nodea.nodeb.nodec"
    data = "message payload"

    headers = {"kcr" => "\r",
       "kcl" => ":", "klf" => "\n"}
    #headers = {"kcr" => Stomp::CR_ASCII,
    #  "kcl" => Stomp::COLON_ASCII, "klf" => Stomp::LF_ASCII}
    #headers = {"kcr" => "\\r",
    #  "kcl" => "\\c", "klf" => "\\n"}
    
    #
    # The 'data' and 'headers' may be omitted, as with Stomp 1.0
    #
    puts "Writing #{nmsgs()} messages."
    1.upto(nmsgs()) do |i|
      msg = "#{data}: #{i}"
      conn.publish qname, msg , headers
      puts "Sent data: #{msg}"
    end
    #
    # And finally, disconnect.
    #
    conn.disconnect
  end
end
#
e = Publish12Example1.new
e.run


