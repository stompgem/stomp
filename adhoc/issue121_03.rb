# -*- encoding: utf-8 -*-

require 'stomp'
require 'tmpdir'

# Focus on this gem's capabilities.
require 'memory_profiler'
# require 'memory-profiler'

if Kernel.respond_to?(:require_relative)
  require_relative("stomp_adhoc_common")
  require_relative("payload_generator")
else
  $LOAD_PATH << File.dirname(__FILE__)
  require "stomp_adhoc_common"
  require("payload_generator")
end
include Stomp11Common

# Round 3 of testing around issue #121.
# Different memory profiler gem.

class Issue121Examp03

  attr_reader :client, :session

  # Initialize.
  def initialize(topic = false)
    @client, @session, @topic = nil, nil, topic
    @nmsgs = nmsgs()
    @queue = make_destination("issue121/test_03")
    @id = "issue121_03"
    @block = cli_block()
    #
    @cmin, @cmax = 1292, 67782 # From the issue discussion
    PayloadGenerator::initialize(min= @cmin, max= @cmax)
    @ffmts = "%16.6f"
    #
    mps = 5.6 # see issue discussion
    @to, @nmts, @nts, @umps = 0.0, Time.now.to_f, @nmsgs, mps
    @tslt = 1.0 / @umps
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
    puts "START: Block: #{@block}"
    puts "START: Wanted Messages Per Second: #{@umps}"
    puts "START: Sleep Time: #{@tslt}"
    $stdout.flush
  end # start

  #
  def shutdown
    @client.close
    #
    te = Time.now.to_f
    et = te - @nmts
    avgsz = @to / @nts
    mps = @nts.to_f / et
    #
    fet = sprintf(@ffmts, et)
    favgsz = sprintf(@ffmts, avgsz)
    fmps = sprintf(@ffmts, mps)
    #
    sep = "=" * 72
    puts sep
    puts "\tNumber of payloads generated: #{@nts}"
    puts "\tMin Length: #{@cmin}, Max Length: #{@cmax}"
    puts "\tAVG_SIZE: #{favgsz}, ELAPS_SEC: #{fet}(seconds)"
    puts "\tNMSGS_PER_SEC: #{fmps}"
    puts sep
    #
    puts "SHUT: Shutdown complete"
    $stdout.flush
  end # shutdown

  # pub
  def publish
    m = "Message: "
    nm = 0

    @nmsgs.times do |n|
      nm += 1
      puts "PUB: NEXT MESSAGE NUMBER: #{nm}"; $stdout.flush
      mo = PayloadGenerator::payload()
      @to += mo.bytesize()
      hs = {:session => @session}

      if @block
        ip = false
        @client.publish(@queue,
          mo,
          hs) {|m|
            puts "PUB: HAVE_RECEIPT:\nID: #{m.headers['receipt-id']}"
            $stdout.flush
            ip = m
        }
        sleep 0.01 until ip
      else
        @client.publish(@queue, mo, hs)
      end # if @block

      if nm < @nmsgs
        puts "PUB: start user sleep"
        sleep @tslt # see issue discussion
        puts "PUB: end user sleep"
      end
      $stdout.flush
    end # @nmsgs.times do

    puts "PUB: end of publish"
    $stdout.flush
  end # publish

end # class

#
1.times do |i|
  rpt  = MemoryProfiler.report do
    e = Issue121Examp03.new
    e.start
    e.publish
    # No subscribes here, just publish
    # See discussion in issue #121
    e.shutdown
  end
  n = Time.now
  nf = "memory_profiler-ng"
  nf << n.strftime("%Y%m%dT%H%M%S.%N%Z")
  where_name = File::join(Dir::tmpdir(), nf)
  rpt.pretty_print(to_file: where_name  )
  # sleep 1
end
#

