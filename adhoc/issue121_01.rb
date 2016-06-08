# -*- encoding: utf-8 -*-

require 'stomp'

# Focus on this gem's capabilities.
# require 'memory_profiler'
require 'memory-profiler'

if Kernel.respond_to?(:require_relative)
  require_relative("stomp_adhoc_common")
else
  $LOAD_PATH << File.dirname(__FILE__)
  require "stomp_adhoc_common"
end
include Stomp11Common

# Initial testing around issue #121.

class Issue121Examp01

  attr_reader :client, :session

  # Initialize.
  def initialize(topic = false)
    @client, @session, @topic = nil, nil, topic
    @nmsgs = nmsgs()
    @queue = make_destination("issue121/test_01")
    @id = "issue121_01"
    @block = cli_block()
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
    puts "START: Block: #{@block}"
    $stdout.flush
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
      mo = "#{m} #{n}"
      puts "PUB: PAYLOAD: #{mo}"
      hs = {:session => @session}
     if @block
        ip = false
        @client.publish(@queue,
          mo,
          hs) {|m|
            puts "PUB: HAVE_RECEIPT:\nID: #{m.headers['receipt-id']}"
            ip = m
        }
        sleep 0.01 until ip
      else
        @client.publish(@queue, mo, hs)
      end # if @block

    end # @nmsgs.times do

  end # publish

  # sub
  def subscribe
    puts "SUB: Subscribe starts For: #{@queue}"
    rmc, done = 0, false
    sh = {:id => "#{@id}", :ack => "auto"}
    @client.subscribe(@queue, sh) {|m|
      rmc += 1
      rm = m
      puts "SUB: HAVE_MESSAGE:\n#{rm}"
      if rmc >= @nmsgs
        puts "SUB: Subscribe is ending for #{@queue}"
        done = true
        Thread.done
      end
    }
    sleep 0.01 until done
    puts "SUB: Receives Done For: #{@queue}"
  end # subscribe

end # class

#
# puts "BEG: Memory Profiler Version is: #{MemoryProfiler::VERSION}"
MemoryProfiler::start_daemon( :limit=>5, :delay=>10, :marshal_size=>true, :sort_by=>:absdelta )
#
5.times do |i|
  rpt  = MemoryProfiler.start( :limit=>10 ) do
    e = Issue121Examp01.new
    e.start
    e.publish
    e.subscribe
    e.shutdown
  end
  puts MemoryProfiler.format(rpt)
  sleep 1
end
#
MemoryProfiler::stop_daemon
