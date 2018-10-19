# -*- encoding: utf-8 -*-

#
# Reference: https://github.com/stompgem/stomp/wiki/extended-ssl-overview
#
require "rubygems"
require "stomp"
#
# == Demo override of SSLContext.new parameters.
#
# Based roughly on example ssl_uc1.rb.
#
#
class ExampleSSLNewParm
  # Initialize.
  def initialize
  end
  # Run example.
  def run
    ssl_opts = Stomp::SSLParams.new
    hash = { :hosts => [
        {:login => 'guest', :passcode => 'guest', :host => 'localhost', :port => 61612, :ssl => ssl_opts},
      ],
      :reliable => false, # YMMV, to test this in a sane manner
      :sslctx_newparm => :SSLv2,  # An example should you:
      # a) Actually want SSLv2 *AND*
      # b) Your Ruby version supports SSLv2 *AND*
      # c) Your broker supports and allows SSLv2
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
e = ExampleSSLNewParm.new
e.run

