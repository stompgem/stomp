# -*- encoding: utf-8 -*-

require 'rubygems'
require 'stomp'

if Kernel.respond_to?(:require_relative)
  require_relative("./stomp11_common")
  require_relative("./lflogger")
else
  $LOAD_PATH << File.dirname(__FILE__)
  require "stomp11_common"
  require "./lflogger"
end
include Stomp11Common
#
# Used primarily for testing performance when sending "large" messages.
# "large" => YMMV
#
class FileSenderConn
  # Initialize.
  def initialize
  end
  # Run example.
  def run
    p [ "pubc001", Thread.current ]
    publogger = Slogger::new
    start_time = Time.now.to_f
    fname = ARGV[0]
    puts "PUBFC: File Name: #{fname}"
    file = open(fname, "r")
    rs = Time.now.to_f
    buff = file.read
    re = Time.now.to_f
    ppt = sprintf("%20.6f", re - rs)
    puts "PUBFC: File size: #{buff.respond_to?(:bytesize) ? buff.bytesize : buff.length}"
    puts "PUBFC: File read: #{ppt} seconds"
    file.close
    #
    connection_hdrs = {"accept-version" => "1.1",
      "host" => virt_host(),
    }
    connection_hash = { :hosts => [
        {:login => login(), :passcode => passcode(),
          :host => host(), :port => port()},
      ],
      :connect_headers => connection_hdrs,
      :logger => publogger,	
      :reliable => false, ### *NOTE*
    }
    #
    # p [ "ch", connection_hash ]
    connection = Stomp::Connection.new(connection_hash)
    qname = ENV['STOMP_DEST'] ? ENV['STOMP_DEST'] : "/queue/a.big.file"
    puts "PUBFC: Qname is: #{qname}"
    ph = {:presistent => true}
    ph['suppress_content_length'] = 'yes' if suppresscl()
    puts "PUBF: Headers are: #{ph.inspect}"
    # Try to gracefully handle files that exceed broker size limits.
    begin
      connection.publish(qname, buff, ph)
    rescue
      puts "PUBFC: exception on publish: #{$!}"
    end
    e = connection.poll() # Check for unsolicited messages from broker
    puts "PUBFC: unexpected broker message: #{e}" if e
    connection.disconnect
    end_time = Time.now.to_f
    ppt = sprintf("%20.6f", end_time - start_time)
    puts "PUBFC: File published: #{ppt} seconds"
  end
end
#
e = FileSenderConn.new
e.run

