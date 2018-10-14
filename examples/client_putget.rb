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
# Purpose: to demonstrate using a Stomp 1.x client to put and get messages.
#
class ClientPutGetExample
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
    # Get Destination
    #
    qname = dest()
    #
    # Publish/put messages
    #
    puts "Client start puts"
    nm = nmsgs()
    1.upto(nm) do |n|
      data = "message payload: #{n} #{Time.now.to_f}"
      client.publish(qname, data)
      puts "Sent: #{data}"
    end
    #
    # Receives
    #
    uuid = client.uuid() # uuid for Stomp::Client is a public method
    done = false         # done flag
    mc = 0               # running message count
    #
    # Clients must pass a receive block.  This is business as usual, required for 1.0.
    # For 1.1+, a unique subscription id is required.
    #
    puts "\nClient start receives"
    client.subscribe(qname, {'id' => uuid}) {|m|
      message = m
      puts "Received: #{message.body}"
      mc += 1
      if mc >= nm
        done = true
        Thread::exit
      end
    }
    #
    # Wait for done flag
    #
    sleep 0.1 until done
    #
    # And to be polite to the broker, we unsubscribe.
    #
    client.unsubscribe(qname, {'id' => uuid})
    #
    # Finally close
    # =============
    #
    client.close()   # Business as usual
    puts "\nClient close complete"
  end
end
#
e = ClientPutGetExample.new
e.run

