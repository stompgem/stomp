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

# Next of testing around issue #121.
# Different memory profiler gem.
# Use Stomp#connection to merely send

class Issue121Examp01Conn

  attr_reader :connection, :session

  # Initialize.
  def initialize(topic = false)
    @connection, @session, @topic = nil, nil, topic
    @nmsgs = nmsgs()
    @queue = make_destination("issue121/test_01_conn")
    @id = "issue121_01_conn"
    @getreceipt = conn_receipt()
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
    connect_hdrs = {"accept-version" => "1.1,1.2",
      "host" => virt_host,
    }
    #
    connect_hash = { :hosts => [
        {:login => login(), :passcode => passcode(), :host => host(), :port => port()},
      ],
      :connect_headers => connect_hdrs,
    }
    #
    @connection = Stomp::Connection.new(connect_hash)
    puts "START: Connection Connect complete"
    raise "START: Connection failed!!" unless @connection.open?
    raise "START: Unexpected protocol level!!" if @connection.protocol == Stomp::SPL_10
    cf = @connection.connection_frame
    puts "START: Connection frame\n#{cf}"
    raise "START: Connect error!!: #{cf.body}" if @connection.connection_frame.command == Stomp::CMD_ERROR
    @session = @connection.connection_frame.headers['session']
    puts "START: Queue/Topic Name: #{@queue}"
    puts "START: Session: #{@session}"
    puts "START: NMSGS: #{@nmsgs}"
    puts "START: Receipt: #{@getreceipt}"
    puts "START: Wanted Messages Per Second: #{@umps}"
    puts "START: Sleep Time: #{@tslt}"
    $stdout.flush
  end # start

  #
  def shutdown
    @connection.disconnect()
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

  #
  def msg_handler
    m = "Message: "
    nm = 0

    @nmsgs.times do |n|
      nm += 1
      puts "MSH: NEXT MESSAGE NUMBER: #{nm}"; $stdout.flush
      mo = PayloadGenerator::payload()
      @to += mo.bytesize()

      if @getreceipt
        uuid = @connection.uuid()
        puts "MSH: Receipt id wanted is #{uuid}"
        hs = {:session => @session, :receipt => uuid}
      else
        hs = {:session => @session}
      end

      # Move data out the door
      @connection.publish(@queue, mo, hs)

      if @getreceipt
        r = @connection.receive()
        puts "MSH: received receipt, id is #{r.headers['receipt-id']}"
        raise if uuid != r.headers['receipt-id']
      end
      #
      puts "MSH: start user sleep"
      sleep @tslt # see issue discussion
      puts "MSH: end user sleep"
      $stdout.flush
    end # @nmsgs.times do

    puts "MSH: end of msg_handler"
    $stdout.flush
  end # msg_handler

end # class

#
1.times do |i|
  rpt  = MemoryProfiler.report do
    e = Issue121Examp01Conn.new
    e.start
    e.msg_handler
    # No subscribes here, just msg_handler
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

