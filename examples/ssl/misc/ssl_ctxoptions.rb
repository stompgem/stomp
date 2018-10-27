# -*- encoding: utf-8 -*-

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
# == Demo User Control of SSLContext options contents
#
# Roughly based on example ssl_uc1.rb.  
# See comments in that example for more detail.
#
# Not tested with jruby. YMMV.
#
class ExampleSSLCtxOptions
  # Initialize.
  def initialize
    # It is very likely that you will have to specify your specific port number.
    # 61611 is currently my AMQ local port number for ssl client auth not required.
		@port = ENV['STOMP_PORT'] ? ENV['STOMP_PORT'].to_i : 61611
  end

  # Run example 1
  def run1()
    require 'openssl' unless defined?(OpenSSL)
    puts "run1 method ...."
		# Define SSL Options to be used.  This code is copied from the defaults
    # in later versions of Ruby V2.x (which has been backported to 1.9.3).
    #
    # Connection / Example 1 of 2, user supplied options.
    #

    # Build SSL Options per user requirements: this is just one
    # particular/possible example of setting SSL context options.
    opts = OpenSSL::SSL::OP_ALL
    # Perhaps. If you need/want any of these you will know it.
    # This is exactly what is done in later versions of Ruby 2.x (also has
    # been backported by Ruby team to later versions of 1.9.3).
    opts &= ~OpenSSL::SSL::OP_DONT_INSERT_EMPTY_FRAGMENTS if defined?(OpenSSL::SSL::OP_DONT_INSERT_EMPTY_FRAGMENTS)
    opts |= OpenSSL::SSL::OP_NO_COMPRESSION if defined?(OpenSSL::SSL::OP_NO_COMPRESSION)
    opts |= OpenSSL::SSL::OP_NO_SSLv2 if defined?(OpenSSL::SSL::OP_NO_SSLv2)
    opts |= OpenSSL::SSL::OP_NO_SSLv3 if defined?(OpenSSL::SSL::OP_NO_SSLv3)

    urc = defined?(RUBY_ENGINE) && RUBY_ENGINE =~ /jruby/ ? true : false

		# Pass options to SSLParams constructor.
    ssl_opts = Stomp::SSLParams.new(:ssl_ctxopts => opts, # SSLContext options to set
      :use_ruby_ciphers => urc,
      :fsck => true)
    hash = { :hosts => [
        {:login => login(), :passcode => passcode(), :host => host(), :port => @port, :ssl => ssl_opts},
      ],
      :reliable => false, # YMMV, to test this in a sane manner
    }
    #
    puts "Connect starts, SSLContext Options Set: #{opts}"
    c = Stomp::Connection.new(hash)
    puts "Connect completed"
    puts "SSL Verify Result: #{ssl_opts.verify_result}"
    # puts "SSL Peer Certificate:\n#{ssl_opts.peer_cert}"
    #
    c.disconnect()
  end
  
  # Run example 2
  def run2()
    puts "run2 method ...."
    #
    # Connection / Example 2 of 2, gem supplied options.
    #

    urc = defined?(RUBY_ENGINE) && RUBY_ENGINE =~ /jruby/ ? true : false

    # Use gem method to define SSL options.  Exactly the same as the
    # options used in Example 1 above.
    ssl_opts = Stomp::SSLParams.new(:ssl_ctxopts => Stomp::Connection::ssl_v2xoptions(),
       :use_ruby_ciphers => urc,
       :fsck => true)
    hash = { :hosts => [
        {:login => login(), :passcode => passcode(), :host => host(), :port => @port, :ssl => ssl_opts},
      ],
      :reliable => false, # YMMV, to test this in a sane manner
    }
    #
    puts "Connect starts, SSLContext Options Set: #{Stomp::Connection::ssl_v2xoptions()}"
    c = Stomp::Connection.new(hash)
    puts "Connect completed"
    puts "SSL Verify Result: #{ssl_opts.verify_result}"
    # puts "SSL Peer Certificate:\n#{ssl_opts.peer_cert}"
    #
    c.disconnect()
  end
end
#
e = ExampleSSLCtxOptions.new()
e.run1()
e.run2()

