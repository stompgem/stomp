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
# == Stomp 1.1 Client Putter/Getter Example 1
#
# This is much like sending and receiving with a Stomp::Connection.
#
class Client11PutGet1
  # Initialize.
  def initialize
  end
  # Run example.
  def run
    #
    client_hdrs = {"accept-version" => "1.1",    # Demand a 1.1 connection (use a CSV list if you will consider multiple versions)
      "host" => virt_host,                 # The 1.1 vhost (could be different than connection host)
    }                                      # No heartbeats here:  there will be none for this connection
    #
    client_hash = { :hosts => [
        {:login => login, :passcode => passcode, :host => host, :port => port},
      ],
      :connect_headers => client_hdrs,
    }
    #
    client = Stomp::Client.new(client_hash)
    puts "Client Connect complete"
    #
    raise "Unexpected protocol level" if client.protocol() != Stomp::SPL_11
    #
    qname = "/queue/client.nodea.nodeb.nodec"
    data = "message payload: #{Time.now.to_f}"
    headers = {}
    # Send it
    client.publish qname, data
    puts "Publish complete"
    # Receive
    uuid = client.uuid() # uuid for Stomp::Client is a public method
    message = nil
    # Clients must pass a receive block.  This is business as usual, required for 1.0.
    # For 1.1, a unique subscription id is required.
    client.subscribe(qname, {'id' => uuid}) {|m|
    message = m
    }
    sleep 0.1 until message # Wait for completion
    puts "Subscribe and receive complete"
    # Unsubscribe, with the unique id
    client.unsubscribe qname,  {'id' => uuid}
    # Sanity checks for this example ....
    raise "Unexpected data" if data != message.body
    raise "Bad subscription header" if uuid != message.headers['subscription']
    #
    client.close   # Business as usual, just like 1.0
    puts "Client close complete"
  end
end
#
e = Client11PutGet1.new
e.run

