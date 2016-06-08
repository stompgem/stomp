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
class FileSender
  # Initialize.
  def initialize
  end
  # Run example.
  def run
    p [ "pub001", Thread.current ]
    publogger = Slogger::new
    start_time = Time.now.to_f
    fname = ARGV[0]
    puts "PUBF: File Name: #{fname}"
    file = open(fname, "r")
    rs = Time.now.to_f
    buff = file.read
    re = Time.now.to_f
    ppt = sprintf("%20.6f", re - rs)
    puts "PUBF: File size: #{buff.respond_to?(:bytesize) ? buff.bytesize : buff.length}"
    puts "PUBF: File read: #{ppt} seconds"
    file.close
    #
    client_hdrs = {"accept-version" => "1.1",
      "host" => virt_host(),
    }
    client_hash = { :hosts => [
        {:login => login(), :passcode => passcode(),
          :host => host(), :port => port()},
      ],
      :connect_headers => client_hdrs,
      :logger => publogger,	
      :reliable => false, ### *NOTE*
    }
    #
    # p [ "ch", client_hash ]
    client = Stomp::Client.new(client_hash)
    qname = ENV['STOMP_DEST'] ? ENV['STOMP_DEST'] : "/queue/a.big.file"
    puts "PUBF: Qname is: #{qname}"
    # Try to gracefully handle files that exceed broker size limits.
    ph = {:presistent => true}
    ph['suppress_content_length'] = 'yes' if suppresscl()
    puts "PUBF: Headers are: #{ph.inspect}"
    begin
      client.publish(qname, buff, ph)
    rescue
      puts "PUBF: exception on publish: #{$!}"
    end
    sleep 0.1
    e = client.poll() # Check for unsolicited messages from broker
    puts "PUBF: unexpected broker message: #{e}" if e
    client.close
    end_time = Time.now.to_f
    ppt = sprintf("%20.6f", end_time - start_time)
    puts "PUBF: File published: #{ppt} seconds"
  end
end
#
e = FileSender.new
e.run

