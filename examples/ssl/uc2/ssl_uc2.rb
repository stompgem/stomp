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
# == SSL Use Case 2 - server does *not* authenticate client, client *does* authenticate server
#
# Subcase 2.A - Message broker configuration does *not* require client authentication
#
# - Expect connection success
# - Expect a verify result of 0 becuase the client did authenticate the
#   server's certificate.
#
# Subcase 2.B - Message broker configuration *does* require client authentication
#
# - Expect connection failure (broker must be sent a valid client certificate)
#
class ExampleSSL2
  # Initialize.
  def initialize
		# Change the following as needed.
    @host = host()
    # It is very likely that you will have to specify your specific port number.
    # 61611 is currently my AMQ local port number for ssl client auth is not required.    
		@port = ENV['STOMP_PORT'] ? ENV['STOMP_PORT'].to_i : 61611
  end
  # Run example.
  def run
		puts "SSLUC2 Connect host: #{@host}, port: #{@port}"

    ts_flist = []

    # Possibly change/override the cert data here.
    ts_flist << "#{ca_loc()}/#{ca_cert()}"
    puts "TSFLIST: #{ts_flist.inspect}"

    ssl_opts = Stomp::SSLParams.new(:ts_files => ts_flist.join(","), 
      :fsck => true)
    puts "SSLOPTS: #{ssl_opts.inspect}"
    #
    hash = { :hosts => [
        {:login => login(), :passcode => passcode(), :host => @host, :port => @port, :ssl => ssl_opts},
      ],
      :reliable => false, # YMMV, to test this in a sane manner
    }
    #
    puts "Connect starts, SSL Use Case 2"
    c = Stomp::Connection.new(hash)
    puts "Connect completed"
    puts "SSL Verify Result: #{ssl_opts.verify_result}"
    puts "SSL Peer Certificate:\n#{ssl_opts.peer_cert}" if showPeerCert()
    c.disconnect()
  end
end
#
e = ExampleSSL2.new()
e.run

