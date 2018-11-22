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
# == SSL Use Case 3 - User Supplied Ciphers not from files
#
# If you need your own ciphers list, this is how.
# Stomp's default list will work in many cases.  If you need to use this, you
# will know it because SSL connect will fail.  In that case, determining
# _what_ should be in the list is your responsibility.
#
class ExampleSSLwoFiles3C
  # Initialize.
  def initialize    # Change the following as needed.
    @host = host()
    # It is very likely that you will have to specify your specific port number.
    # 61612 is currently my AMQ local port number for ssl client auth is required.    
    @port = ENV['STOMP_PORT'] ? ENV['STOMP_PORT'].to_i : 61612
  end
  # Run example.
  def run
    puts "SSLUC3C Connect host: #{@host}, port: #{@port}"
    #
    # SSL Use Case 3 without files
    # certificate information will typically be stored in environmental variables
    #
    # Possibly change the cert file(s) name(s) here.    
    ssl_opts = Stomp::SSLParams.new(
      :key_text => cli_key_text().to_s,         # the client's private key, private data
      :cert_text => cli_cert_text().to_s,       # the client's signed certificate
      :ciphers => ciphers_list()                # The cipher list
    )
    #
    puts "SSLOPTS: #{ssl_opts.inspect}"
    hash = { :hosts => [
        {:login => login(), :passcode => passcode(), :host => @host, :port => @port, :ssl => ssl_opts},
      ],
      :reliable => false, # YMMV, to test this in a sane manner
    }
    #
    puts "Connect starts, SSL Use Case 3 without files"
    c = Stomp::Connection.new(hash)
    puts "Connect completed"
    puts "SSL Verify Result: #{ssl_opts.verify_result}"
    puts "SSL Peer Certificate:\n#{ssl_opts.peer_cert}" if showPeerCert()
    c.disconnect()
  end

end
#
e = ExampleSSLwoFiles3C.new()
e.run

