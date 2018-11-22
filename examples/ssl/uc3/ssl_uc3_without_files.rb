# -*- encoding: utf-8 -*-

#
# Reference: https://github.com/stompgem/stomp/wiki/extended-ssl-overview
#
if Kernel.respond_to?(:require_relative)
  require_relative("../ssl_common")
  require_relative("../../stomp_common")
else
  $LOAD_PATH << File.dirname(__FILE__)
  require "../ssl_common"
  require("../../stomp_common")
end
include SSLCommon
include Stomp1xCommon
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
class ExampleSSL3woFiles
  # Initialize.
  def initialize
    # Change the following as needed.
    @host = host()
    # It is very likely that you will have to specify your specific port number.
    # 61612 is currently my AMQ local port number for ssl client auth is required.    
    @port = ENV['STOMP_PORT'] ? ENV['STOMP_PORT'].to_i : 61612
  end
  # Run example.
  def run
    puts "SSLUC3 Connect host: #{@host}, port: #{@port}"

    # Possibly change the cert file(s) name(s) here.    
    ssl_opts = Stomp::SSLParams.new(
      :key_text => cli_key_text().to_s,  # the client's private key, private data
      :cert_text => cli_cert_text().to_s      # the client's signed certificate 
    )
    puts "SSLOPTS: #{ssl_opts.inspect}"
    #
    hash = { :hosts => [
        {:login => login(), :passcode => passcode(), :host => @host, :port => @port, :ssl => ssl_opts},
      ],
      :reliable => false, # YMMV, to test this in a sane manner
    }
    #
    puts "Connect starts, SSL Use Case 3"
    c = Stomp::Connection.new(hash)
    puts "Connect completed"
    puts "SSL Verify Result: #{ssl_opts.verify_result}"
    puts "SSL Peer Certificate:\n#{ssl_opts.peer_cert}" if showPeerCert()
    c.disconnect()
  end

end
#
e = ExampleSSL3woFiles.new()
e.run

