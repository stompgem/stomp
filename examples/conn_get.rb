# -*- encoding: utf-8 -*-

#
# The current require dance for different Ruby versions.
# Change this to suit your requirements.
#
if Kernel.respond_to?(:require_relative)
  require_relative("./stomp_common")
else
  $LOAD_PATH << File.dirname(__FILE__)
  require "stomp_common"
end
include Stomp1xCommon

#
# == Stomp 1.x Putt / Get Example
#
# Purpose: to demonstrate producing and consuming messages using a
# Stomp#Connection instance.
#
# Note: this example assumes that you have at least the 1.2.0 gem release
# installed.
#
# When you:
#
# * Use a Stomp compliant broker
# * Want a Stomp 1.1+ connection and functionality
#
# then your code *must* specifically request that environment.
#
# You need to supply all of the normal values expected of course:
#
# * login - the user name
# * passcode - the password
# * host - the host to connect to
# * port - the port to connect to
#
# Additionaly you are required to supply the 1.1+ connection data as documented
# in the Stomp 1.1+ specifications:
#
# http://stomp.github.com/stomp-specification-1.0.html
# http://stomp.github.com/stomp-specification-1.1.html
# http://stomp.github.com/stomp-specification-1.2.html
#
# You are urged to become familiar with the specs.  They are short documents.
#
# This includes:
#
# * The Stomp version(s) you wish the broker to consider
# * The broker vhost to connect to
#
# You may optionally specify other 1.1+ data:
#
# * heartbeat request
#
# Using the stomp gem, you should specify this data in the "connect_headers" Hash
# parameter. This example uses the common get_connection() method to 
# get a connection.
#
class ConnectionGetExample
  # Initialize
  def initialize
  end
  # Run example
  def run
    #
    # Get a connection
    # ================
    #
    conn = get_connection()
    #
    # Let's just do some sanity checks, and look around.
    #
    raise "Connection failed!!" unless conn.open?()
    #
    # The broker _could_ have returned an ERROR frame (unlikely).
    #
    raise "Connect error: #{conn.connection_frame.body}" if conn.connection_frame.command == Stomp::CMD_ERROR
    #
    puts "Connection complete."
     #
    # Get Destination
    #
    qname = dest()
    nm = nmsgs()
    puts
    puts "Connection start receives"
    #
    # Receives
    #
    # Subscribe
    #
    uuid = conn.uuid() # uuid for Stomp::Connection is a public method
    conn.subscribe(qname, {'id' => uuid}) # Subscribe
    #
    # Run gets
    #
    received = ""
    1.upto(nm) do
      received = conn.receive()
      puts "Received headers: #{received.headers}"
      puts "Received body: #{received.body}"
    end
    puts
    received.headers.each do |h|
      puts h
    end
    #
    # And be polite, unsubscribe.
    #
    conn.unsubscribe(qname, {'id' => uuid})
    #
    # Finally disconnect
    # ==================
    #
    conn.disconnect()   # Business as usual
    puts "\nConnection disconnect complete"
  end
end
#
e = ConnectionGetExample.new()
e.run
