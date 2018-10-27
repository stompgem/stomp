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
# == SSL Use Case 2 - User Supplied Ciphers
#
# If you need your own ciphers list, this is how.
# Stomp's default list will work in many cases.  If you need to use this, you
# will know it because SSL connect will fail.  In that case, determining
# _what_ should be in the list is your responsibility.
#
class ExampleSSL2C
  # Initialize.
  def initialize		# Change the following as needed.
    @host = host()
   # It is very likely that you will have to specify your specific port number.
  # 61611 is currently my AMQ local port number for ssl client auth is not required.        
		@port = ENV['STOMP_PORT'] ? ENV['STOMP_PORT'].to_i : 61611
  end
  # Run example.
  def run
    puts "SSLUC2C Connect host: #{@host}, port: #{@port}"
    #
    # SSL Use Case 2
    #
    ts_flist = []

    # Possibly change/override the cert data here.
    ts_flist << "#{ca_loc()}/#{ca_cert()}"
    puts "TSFLIST: #{ts_flist.inspect}"    

    ssl_opts = Stomp::SSLParams.new(:ts_files => ts_flist.join(","), 
      :ciphers => ciphers_list(), # The cipher list
      :fsck => true
    )
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
e = ExampleSSL2C.new()
e.run

