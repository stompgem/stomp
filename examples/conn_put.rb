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
class ConnectionPutExample
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
    #
    # Publish/put messages
    #
    puts "\nConnection start puts"
    nm = nmsgs()
    ph = {:persistent => true}
    ph['suppress_content_length'] = 'yes' if suppresscl()
    ph['K:A'] = 'V:A'
    ph['K\B'] = 'V\B'
    ph['K:C'] = 'V\C'
    puts "Put Headers: #{ph}"
    1.upto(nm) do |n|
      data = "message payload: #{n} #{Time.now.to_f}"
      conn.publish(qname, data, ph)
      puts "Sent: #{data}"
    end
    #
    # Finally disconnect
    # ==================
    #
    conn.disconnect()   # Business as usual
    puts "\nConnection disconnect complete"
  end
end
#
e = ConnectionPutExample.new()
e.run
