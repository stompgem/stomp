# -*- encoding: utf-8 -*-

require 'rubygems' if RUBY_VERSION < "1.9"
require 'stomp'

# Focus on this gem's capabilities.
# require 'memory_profiler'
require 'memory-profiler'

if Kernel.respond_to?(:require_relative)
  require_relative("stomp_adhoc_common")
  require_relative("payload_generator")
else
  $LOAD_PATH << File.dirname(__FILE__)
  require "stomp_adhoc_common"
  require("payload_generator")
end
include Stomp11Common

# Round 2 of testing around issue #121.

class Issue121Examp02

  attr_reader :client, :session

  # Initialize.
  def initialize(topic = false)
    @client, @session, @topic = nil, nil, topic
    @nmsgs = nmsgs()
    @queue = make_destination("issue121/test_02")
    @id = "issue121_02"
    @block = cli_block()
    #
    cmin, cmax = 1292, 67782 # From the issue discussion
    PayloadGenerator::initialize(min= cmin, max= cmax)
  end # initialize

  # Startup
  def start
    #
    client_hdrs = {"accept-version" => "1.1,1.2",
      "host" => virt_host,
    }
    #
    client_hash = { :hosts => [
        {:login => login(), :passcode => passcode(), :host => host(), :port => port()},
      ],
      :connect_headers => client_hdrs,
    }
    #
    @client = Stomp::Client.new(client_hash)
    puts "START: Client Connect complete"
    raise "START: Connection failed!!" unless @client.open?
    raise "START: Unexpected protocol level!!" if @client.protocol() == Stomp::SPL_10
    cf = @client.connection_frame()
    puts "START: Connection frame\n#{cf}"
    raise "START: Connect error!!: #{cf.body}" if @client.connection_frame().command == Stomp::CMD_ERROR
    @session = @client.connection_frame().headers['session']
    puts "START: Queue/Topic Name: #{@queue}"
    puts "START: Session: #{@session}"
    puts "START: NMSGS: #{@nmsgs}"
    puts "START: BLOCK: #{@block}"
  end # start

  #
  def shutdown
    @client.close
    puts "SHUT: Shutdown complete"
  end # shutdown

  # pub
  def publish
    m = "Message: "
    nm = 0
    @nmsgs.times do |n|
      nm += 1
      puts "PUB: NEXT MESSAGE NUMBER: #{nm}"
      p [ "nilcheck1", !@block.nil?, @block ]
      mo = PayloadGenerator::payload()
      p [ "nilcheck2", !@block.nil?, @block ]
      hs = {:session => @session}
      p [ "nilcheck3", !@block.nil?, @block ]
      if !@block.nil?
        p [ "good" ]
        @client.publish(@queue,
          mo,
          hs) {|m|
            ip = m
            puts "PUB: HAVE_RECEIPT:\n#{ip}"
        }
      else
        p [ "bad" ]
        @client.publish(@queue, mo, hs)
      end
    end # do @nmsgs
  end # publish

end # class

#
# :limit => is max number of classes to report on
MemoryProfiler::start_daemon( :limit=>10, :delay=>10, :marshal_size=>true, :sort_by=>:absdelta )
#
e = Issue121Examp02.new
1.times do |i|
  rpt  = MemoryProfiler.start( :limit=> 10 ) do
    # e = Issue121Examp02.new
    e.start
    e.publish
    # No subscribes here, just publish
    # See discussion in issue #121
    e.shutdown
  end
  puts MemoryProfiler.format(rpt)
  sleep 1
end
#
MemoryProfiler::stop_daemon
