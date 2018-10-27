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
  require "../../stomp_common"
end
include SSLCommon
include Stomp1xCommon
#
# == Demo override of SSLContext.new parameters.
#
# Based roughly on example ssl_uc1.rb.
#
#
class ExampleSSLNewParm
  # Initialize.
  def initialize
		@port = ENV['STOMP_PORT'] ? ENV['STOMP_PORT'].to_i : 61611
  end
  # Run example.
  def run
    ssl_opts = Stomp::SSLParams.new()
    hash = { :hosts => [
        {:login => login(), :passcode => passcode(), :host => host(), :port => @port, :ssl => ssl_opts},
      ],
      :reliable => false,         # YMMV, to test this in a sane manner
      # This parameter is passed by the gem to the new method for ssl context.
      :sslctx_newparm => :TLSv1,  # An example, try to force TLSv1
      # If your version of Ruby does not support what you ask for, Ruby openssl code will raise
      # an exception.  If Ruby accepts your parms, but your broker does not you will get
      # different errors (depending on broker).
    }
    #
    puts "Connect starts, Demo SSL context new parameters"
    c = Stomp::Connection.new(hash)
    puts "Connect completed"
    puts "SSL Verify Result: #{ssl_opts.verify_result}"
    puts "SSL Peer Certificate:\n#{ssl_opts.peer_cert}" if showPeerCert()
    #
    c.disconnect()
  end
end
#
e = ExampleSSLNewParm.new()
e.run()

