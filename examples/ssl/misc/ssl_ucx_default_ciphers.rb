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
# == Example: Use Ruby Supplied Ciphers
#
# If you use SSLParams, and need the _default_ Ruby ciphers, this is how.
#
# NOTE: JRuby users may find that this is a *required* action. YMMV.
#
class ExampleRubyCiphers
  # Initialize.
  def initialize
    # It is very likely that you will have to specify your specific port number.
    # 61611 is currently my AMQ local port number for ssl client auth not required.
		@port = ENV['STOMP_PORT'] ? ENV['STOMP_PORT'].to_i : 61611
  end
  # Run example.
  def run()
		puts "SSLUCXRDF Connect host: #{host()}, port: #{@port}"
    ssl_opts = Stomp::SSLParams.new(:use_ruby_ciphers => true) # Plus other parameters as needed
    puts "SSLOPTS: #{ssl_opts.inspect}"
    #
    # SSL Use Case: Using default Ruby ciphers
    #
    hash = { :hosts => [
        {:login => login(), :passcode => passcode(), :host => host(),
        :port => @port, :ssl => ssl_opts},
      ]
    }
    #
    puts "Connect starts, SSL , Use Default Ruby Ciphers"
    c = Stomp::Connection.new(hash)
    puts "Connect completed"
    #
    c.disconnect()
  end
end
#
e = ExampleRubyCiphers.new()
e.run()

