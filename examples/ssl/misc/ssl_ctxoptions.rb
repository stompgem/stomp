# -*- encoding: utf-8 -*-

#
require "rubygems"
require "stomp"
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
  end

  # Run example 1
  def run1
    require 'openssl' unless defined?(OpenSSL)
    puts "run method ...."
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
    sport = ENV["STOMP_PORT"].to_i
    hash = { :hosts => [
        {:login => 'guest', :passcode => 'guest', :host => 'localhost', :port => sport, :ssl => ssl_opts},
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
    c.disconnect
  end
  
  # Run example 2
  def run2
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
    sport = ENV["STOMP_PORT"].to_i
    hash = { :hosts => [
        {:login => 'guest', :passcode => 'guest', :host => 'localhost', :port => sport, :ssl => ssl_opts},
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
    c.disconnect
  end
end
#
e = ExampleSSLCtxOptions.new
e.run1
e.run2

