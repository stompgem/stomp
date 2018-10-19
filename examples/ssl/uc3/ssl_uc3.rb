# -*- encoding: utf-8 -*-

#
# Reference: https://github.com/stompgem/stomp/wiki/extended-ssl-overview
#
if Kernel.respond_to?(:require_relative)
  require_relative("./ssl_common")
else
  $LOAD_PATH << File.dirname(__FILE__)
  require "ssl_common"
end
include SSLCommon
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
		# Change the following as needed.
		@host = ENV['STOMP_HOST'] ? ENV['STOMP_HOST'] : "localhost"
		@port = ENV['STOMP_PORT'] ? ENV['STOMP_PORT'].to_i : 61612
  end
  # Run example.
  def run
		puts "Connect host: #{@host}, port: #{@port}"

    # Possibly change the cert file(s) name(s) here.    
    ssl_opts = Stomp::SSLParams.new(
      :key_file => "#{cli_loc()}/#{pck()}", # the client's private key, private data
      :cert_file => "#{cli_loc()}/#{cli_cert()}", # the client's signed certificate
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

	private

	def pck()
		"client.key"
	end

end
#
e = ExampleSSL3.new
e.run

