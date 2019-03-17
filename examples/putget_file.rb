# -*- encoding: utf-8 -*-

require 'rubygems'
require 'stomp'

if Kernel.respond_to?(:require_relative)
  require_relative("./stomp_common")
else
  $LOAD_PATH << File.dirname(__FILE__)
  require "stomp_common"
end
include Stomp1xCommon
#
# Used primarily for testing performance when sending/receiving "large" messages.
# "large" => YMMV
#
class FilePutGet
  # Initialize.
  def initialize
    @qname = dest()
  end
  # Run put part of example.
  def doput()
    puts
    puts "pgf001 - put starts"
    start_time = Time.now.to_f
    fname = ARGV[0]
    puts "pgf002: File Name: #{fname}"
    file = open(fname, "r")
    rs = Time.now.to_f
    buff = file.read
    re = Time.now.to_f
    ppt = sprintf("%22.8f", re - rs)
    puts "pgf003: File size: #{buff.respond_to?(:bytesize) ? buff.bytesize : buff.length} bytes"
    puts "pgf004: File read time: #{ppt} seconds"
    file.close
    #
    conn = get_connection()
    puts "pgf005: Qname is: #{@qname}"
    # Try to gracefully handle files that exceed broker size limits.
    ph = {:persistent => true}
    ph['suppress_content_length'] = 'yes' if suppresscl()
    puts "pgf006: Headers are: #{ph.inspect}"
    begin
      conn.publish(@qname, buff, ph)
    rescue
      puts "pgf900: exception on publish: #{$!}"
      raise
    end
    conn.disconnect()
    end_time = Time.now.to_f
    ppt = sprintf("%22.8f", end_time - start_time)
    puts "pgf007: File publish time: #{ppt} seconds"
  end
  # Run get part of example.
  def doget()
    puts
    puts "pgf101 - get starts"
    start_time = Time.now.to_f
    conn = get_connection()
    uuid = conn.uuid() # uuid for Stomp::Connection is a public method
    conn.subscribe(@qname, {'id' => uuid}) # Subscribe
    msg = conn.receive()
    puts "pgf102: Message Command: #{msg.command}"
    puts "pgf103: Message Headers: #{msg.headers}"
    body_length_bytes = msg.body.respond_to?(:bytesize) ? msg.body.bytesize : msg.body.length
    puts "pgf104: Received: #{body_length_bytes} bytes"
    #
    end_time = Time.now.to_f
    ppt = sprintf("%22.8f", end_time - start_time)
    puts "pgf105: File receive time: #{ppt} seconds"
    conn.disconnect()
  end

end
#
e = FilePutGet.new()
e.doput()
# e.doget()
