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
# == Stomp 1.1 Client Example 1
#
# Purpose: to demonstrate a connect and disconnect sequence using Stomp 1.1
# with the Stomp#Client interface.
#
class Client11Example1
  # Initialize.
  def initialize
  end
  # Run example.
  def run
    # Note: Stomp#Client does not provide a positional set of parameters that
    # contain a 'connect_headers' parameter.  To use the Stomp#Client interface
    # you _must_ use a 'hashed' set of parameters.
    #
    # Create connection headers
    # =========================
    #
    # The two headers used here are _required_ by the specification.
    #
    client_hdrs = {"accept-version" => "1.1",    # Demand a 1.1 connection (use a CSV list if you will consider multiple versions)
      "host" => virt_host,                   # The 1.1 vhost (could be different than connection host)
    }                                        # No heartbeats here:  there will be none for this connection
    #
    # Create the connect hash.
    # ========================
    #
    client_hash = { :hosts => [
        {:login => login, :passcode => passcode, :host => host, :port => port},
      ],
      :connect_headers => client_hdrs,
    }
    #
    # Get a connection
    # ================
    #
    client = Stomp::Client.new(client_hash)
    puts "Client Connect complete"
    #
    # Let's just do some sanity checks, and look around.
    #
    raise "Connection failed!!" unless client.open?
    #
    # Is this really a 1.1 conection? (For clients, 'protocol' is a public method.
    # The value will be '1.0' for those types of connections.)
    #
    raise "Unexpected protocol level" if client.protocol() != Stomp::SPL_11
    #
    # The broker _could_ have returned an ERROR frame (unlikely).
    # For clients, 'connection_frame' is a public method.
    #
    raise "Connect error: #{client.connection_frame().body}" if client.connection_frame().command == Stomp::CMD_ERROR
    #
    # Examine the CONNECT response (the connection_frame()).
    #
    puts "Connected Headers required to be present:"
    puts "Connect version - \t#{client.connection_frame().headers['version']}"
    puts
    puts "Connected Headers that are optional:"
    puts "Connect server - \t\t#{client.connection_frame().headers['server']}"
    puts "Session ID - \t\t\t#{client.connection_frame().headers['session']}"
    puts "Server requested heartbeats - \t#{client.connection_frame().headers['heart-beat']}"
    #
    # Finally close
    # =============
    #
    client.close   # Business as usual, just like 1.0
    puts "Client close complete"
  end
end
#
e = Client11Example1.new
e.run

