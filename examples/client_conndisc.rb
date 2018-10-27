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
# == Stomp Client Example
#
# Purpose: to demonstrate a connect and disconnect sequence using Stomp 1.x
# with the Stomp#Client interface.
#
class Client1xExample
  # Initialize.
  def initialize
  end
  # Run example.
  def run
    #
    # Get a client
    # ============
    #
    client = get_client()
    #
    # Let's just do some sanity checks, and look around.
    #
    raise "Connection failed!!" unless client.open?()
    #
    # The broker _could_ have returned an ERROR frame (unlikely).
    #
    raise "Connect error: #{client.connection_frame().body}" if client.connection_frame().command == Stomp::CMD_ERROR
    #
    puts "Client Connect complete"
    #
    #  Show protocol level.
    #
    puts "Negotiated Protocol Level: #{client.protocol()}"
    #
    # Examine the CONNECT response (the connection_frame).
    #
    puts "\nActual Connected Headers depend on broker and protocol level:"
    puts "Connect version             - #{client.connection_frame().headers['version']}"
    puts "Connect server              - #{client.connection_frame().headers['server']}"
    puts "Session ID                  - #{client.connection_frame().headers['session']}"
    puts "Server requested heartbeats - #{client.connection_frame().headers['heart-beat']}"

    #
    # Finally close
    # =============
    #
    client.close()   # Business as usual
    puts "\nClient close complete"
  end
end
#
e = Client1xExample.new
e.run

