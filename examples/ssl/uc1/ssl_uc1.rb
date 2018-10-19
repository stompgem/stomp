# -*- encoding: utf-8 -*-

#
# Reference: https://github.com/stompgem/stomp/wiki/extended-ssl-overview
#
#
if Kernel.respond_to?(:require_relative)
  require_relative("./ssl_common")
else
  $LOAD_PATH << File.dirname(__FILE__)
  require "ssl_common"
end
include SSLCommon
#
# == SSL Use Case 1 - server does *not* authenticate client, client does *not* authenticate server
#
# Subcase 1.A - Message broker configuration does *not* require client authentication
#
# - Expect connection success
# - Expect a verify result of 20 becuase the client did not authenticate the
#   server's certificate.
#
# Subcase 1.B - Message broker configuration *does* require client authentication
#
# - Expect connection failure (broker must be sent a valid client certificate)
#
class ExampleSSL1
  # Initialize.
  def initialize		# Change the following as needed.
		@host = ENV['STOMP_HOST'] ? ENV['STOMP_HOST'] : "localhost"
		@port = ENV['STOMP_PORT'] ? ENV['STOMP_PORT'].to_i : 61612
  end
  # Run example.
  def run
		puts "Connect host: #{@host}, port: #{@port}"

    ssl_opts = Stomp::SSLParams.new # or ssl_opts = true (for this use case)
    #### ssl_opts = false # for testing HandShakeDetectedError exception
    
    hash = { :hosts => [
        {:login => 'guest', :passcode => 'guest', :host => @host, :port => @port, :ssl => ssl_opts},
      ],
      :reliable => false, # YMMV, to test this in a sane manner
    }
    #
    puts "Connect starts, SSL Use Case 1"
    c = Stomp::Connection.new(hash)
    puts "Connect completed"
    puts "SSL Verify Result: #{ssl_opts.verify_result}"
    # puts "SSL Peer Certificate:\n#{ssl_opts.peer_cert}"
    #
    c.disconnect
  end
end
#
e = ExampleSSL1.new
e.run
