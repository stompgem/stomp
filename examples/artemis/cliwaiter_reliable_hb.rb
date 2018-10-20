# -*- encoding: utf-8 -*-
#
require 'stomp'
if Kernel.respond_to?(:require_relative)
	require_relative("../examplogger")
  else
	$LOAD_PATH << File.dirname(__FILE__)
	require "../examplogger"
  end
#
# Artemis will summarily close down connections if there is no traffic for some
# time.  This code demonstrates running with a gem connetion parameter using
# heartbeats to totally avoid this Artemis behavior.
#
class CliWaiter

  # Initialize.
  def initialize        # Change the following as needed.
	@gem_retries = true
	@host = ENV['STOMP_HOST'] ? ENV['STOMP_HOST'] : "localhost"
	@port = ENV['STOMP_PORT'] ? ENV['STOMP_PORT'].to_i : 31613 # Artemis here
	@slt = 75
	@ver = ENV['STOMP_PROTOCOL'] ? ENV['STOMP_PROTOCOL'] : "1.2"
	# The Artemis artificial default is to sever after 1 minute of inactivity.
	# The default heart-beat parameters here are chosen just to avoid this
	# Artemis specific behavior.  YMMV.
	@hbdata = ENV['STOMP_HEARTBEATS'] ? ENV['STOMP_HEARTBEATS'] : "59000,59000"
	@conn_hdrs = {"accept-version" => @ver, # version
		"host" => "localhost",              # vhost
		"heart-beat" => @hbdata,            # heartbeats
	}
	mylog = Slogger::new()  # The client provided STOMP callback logger
	@hash = { :hosts => [
				{:login => 'guest', :passcode => 'guest', :host => @host, :port => @port},
		],
		:reliable => @gem_retries, # reliable controls retries by the gem
		:autoflush => true,
		:connect_headers => @conn_hdrs,
		:logger => mylog,	# This enables callback logging!
	}
  end
  # Run example.
  def run()
	puts "CliWaiter Starts"
	puts "Connect Hash is: #{@hash}"
	c = Stomp::Client.new(@hash)
	#
	while true
		# This should run forever.
		puts "CliWaiter Sleeps: #{@slt} seconds"
		sleep @slt
	end
	#
	c.close()
	puts "CliWaiter Ends"
  end
end
#

#
e = CliWaiter.new()
e.run()
