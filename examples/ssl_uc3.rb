# -*- encoding: utf-8 -*-

#
# Reference: https://github.com/stompgem/stomp/wiki/extended-ssl-overview
#
require "rubygems"
require "stomp"
#
# == SSL Use Case 3 - server *does* authenticate client, client does *not* authenticate server
#
# Subcase 3.A - Message broker configuration does *not* require client authentication
#
# - Expect connection success
# - Expect a verify result of 20 becuase the client did not authenticate the
#   server's certificate.
#
# Subcase 3.B - Message broker configuration *does* require client authentication
#
# - Expect connection success if the server can authenticate the client certificate
# - Expect a verify result of 20 because the client did not authenticate the
#   server's certificate.
#
class ExampleSSL3
  # Initialize.
  def initialize
		# Change the following to the location of the cert file(s).
		@cert_loc = "/ad3/gma/sslwork/2013"
		@host = ENV['STOMP_HOST'] ? ENV['STOMP_HOST'] : "localhost"
		@port = ENV['STOMP_PORT'] ? ENV['STOMP_PORT'].to_i : 61612
  end
  # Run example.
  def run
		puts "Connect host: #{@host}, port: #{@port}"

    # Possibly change the cert file(s) name(s) here.    
    ssl_opts = Stomp::SSLParams.new(
      :key_file => "#{@cert_loc}/client.key", # the client's private key
      :cert_file => "#{@cert_loc}/client.crt", # the client's signed certificate
      :fsck => true # Check that the files exist first
    )

    #
    hash = { :hosts => [
        {:login => 'guest', :passcode => 'guest', :host => @host, :port => @port, :ssl => ssl_opts},
      ],
      :reliable => false, # YMMV, to test this in a sane manner
    }
    #
    puts "Connect starts, SSL Use Case 3"
    c = Stomp::Connection.new(hash)
    puts "Connect completed"
    puts "SSL Verify Result: #{ssl_opts.verify_result}"
    # puts "SSL Peer Certificate:\n#{ssl_opts.peer_cert}"
    c.disconnect
  end
end
#
e = ExampleSSL3.new
e.run

