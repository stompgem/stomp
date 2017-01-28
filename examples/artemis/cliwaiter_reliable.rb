# -*- encoding: utf-8 -*-
#
require 'stomp'
#
if Kernel.respond_to?(:require_relative)
  require_relative("artlogger")
else
  $LOAD_PATH << File.dirname(__FILE__)
  require "artlogger"
end
#
class CliWaiter

  # Initialize.
  def initialize        # Change the following as needed.
	#
	mylog = Slogger::new  # a stomp callback logger
	#
	@gem_retries = true
	@host = ENV['STOMP_HOST'] ? ENV['STOMP_HOST'] : "localhost"
	@port = ENV['STOMP_PORT'] ? ENV['STOMP_PORT'].to_i : 31613 # Artemis here
	@slt = 75
	@ver = ENV['STOMP_PROTOCOL'] ? ENV['STOMP_PROTOCOL'] : "1.2"
	@hbdata = ENV['STOMP_HEARTBEATS'] ? ENV['STOMP_HEARTBEATS'] : "0,0"
	@conn_hdrs = {"accept-version" => @ver, # version
		"host" => "localhost",              # vhost
		"heart-beat" => @hbdata,            # heartbeats		
	}
	@hash = { :hosts => [
				{:login => 'guest', :passcode => 'guest', :host => @host, :port => @port},
		],
		:reliable => @gem_retries, # reliable controls retries by the gem
	    :logger => mylog,	# This enables callback logging!
		:autoflush => true,
		:connect_headers => @conn_hdrs,
		:initial_reconnect_delay => 1.0,    # initial delay before reconnect (secs)
		:use_exponential_back_off => false, # don't backoff
		:max_reconnect_attempts => 3,       # retry 3 times
	}
  end
  # Run example.
  def run
	puts "Connect host: #{@host}, port: #{@port}"
	puts "Connect hash: #{@hash}"
	#
	puts "CliWaiter Starts"
	c = Stomp::Client.new(@hash)
	#
	while true 
		puts "CliWaiter Sleeps: #{@slt} seconds"
		sleep @slt
	end
	#
	c.close
  end
end
#

#
e = CliWaiter.new
e.run
