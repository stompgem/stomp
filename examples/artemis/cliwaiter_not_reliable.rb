# -*- encoding: utf-8 -*-
#
require 'stomp'
#
class CliWaiter

  @@retry_num = 0
  @@max_retries = 3

  # Initialize.
  def initialize        # Change the following as needed.
	@gem_retries = false
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
		:autoflush => true,
		:connect_headers => @conn_hdrs,
	}
	p [ "DB1", @hash ]
	@do_retry=true    # Retry ourself, gem code will not because of :reliable =>
  end
  # Run example.
  def run
	begin
		@@retry_num += 1
		puts "Try Number: #{@@retry_num}"
		puts "Connect host: #{@host}, port: #{@port}"
		puts "Connect hash: #{@hash.inspect}"
		#
		puts "CliWaiter Starts"
		c = Stomp::Client.new(@hash)
		#
		puts "CliWaiter Sleeps: #{@slt} seconds"
		sleep @slt
		#
		c.close
		puts "CliWaiter Ends"
	rescue Exception => ex
		puts "Kaboom, we are in trouble"
		puts "Exception Message: #{ex.message}"
		puts "Exception Class: #{ex.class}"
		puts "The gory details:"
		print ex.backtrace.join("\n")
		if @do_retry && @@retry_num < @@max_retries
			retry
		else
			raise
		end
	end            
  end
end
#

#
e = CliWaiter.new
e.run
