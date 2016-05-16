# -*- encoding: utf-8 -*-

require 'rubygems' if RUBY_VERSION < "1.9"
require 'stomp'

# Focus on this gem's capabilities.
require 'memory_profiler'

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
    puts "START: Connection frame: #{cf}"
    raise "START: Connect error!!: #{cf.body}" if @client.connection_frame().command == Stomp::CMD_ERROR
    @session = @client.connection_frame().headers['session']
    puts "START: Queue/Topic Name: #{@queue}"
    puts "START: Session: #{@session}"
  end # start

  #
  def shutdown
    @client.close
    puts "SHUT: Shutdown complete"
  end # shutdown

  def publish
    m = "Message: "
    @nmsgs.times do |n|
      mo = "#{m} #{n}"
      puts mo
      hs = {:session => @session}
      if @block
        @client.publish(@queue,
          mo,
          hs) {|m|
            ip = m
            puts "PUB: HAVE_RECEIPT: #{ip}"
        }
      else
        @client.publish(@queue, mo, hs)
      end
    end # do @nmsgs
  end # publish

  def subscribe
    puts "SUB: Subscribe starts For: #{@queue}"
    rmc, done = 0, false
    sh = {:id => "#{@id}", :ack => "auto"}
    @client.subscribe(@queue, sh) {|m|
      rmc += 1
      rm = m
      puts "SUB: HAVE_MESSAGE: #{rm}"
      if rmc >= @nmsgs
        done = true
        Thread.done
        puts "SUB: Subscribe is ending for #{@queue}"
      end
    }
    while !done do
      ts = rand(6)
      ts = 1 if ts == 0
      break if done
    end
    puts "SUB: Receives Done For: #{@queue}"
  end # subscribe

end # class

#
puts "BEG: Memory Profiler Version is: #{MemoryProfiler::VERSION}"
#
e = Issue121Examp01.new
e.start
e.publish
e.subscribe
e.shutdown
