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
# Used primarily for testing performance when receiving "large" messages.
# "large" => YMMV
#
class FileReader
  # Initialize.
  def initialize(pto)
    @parse_timeout = pto
  end
  # Run example.
  def run
    conlogger = Slogger::new
    start_time = Time.now.to_f
    #
    connection_hdrs = {"accept-version" => "1.1",
      "host" => virt_host(),
    }
    connection_hash = { :hosts => [
        {:login => login(), :passcode => passcode(),
          :host => host(), :port => port()},
      ],
      :connect_headers => connection_hdrs,
      :logger => conlogger,
      :reliable => false,
      :parse_timeout => @parse_timeout,
    }
    #
    # p [ "ch", connection_hash ]
    connection = Stomp::Connection.new(connection_hash)
    qname = ENV['STOMP_DEST'] ? ENV['STOMP_DEST'] : "/queue/a.big.file"
    puts "CONF: Qname is: #{qname}"
    ## connection.subscribe(qname, {:destination => qname}, "bigFileSubscriptionID")
    connection.subscribe(qname, {:destination => qname}, connection.uuid())
    ## connection.subscribe(qname, {:destination => qname}, "0")
    msg = connection.receive()
    puts "CONF: Message Command: #{msg.command}"
    puts "CONF: Message Headers: #{msg.headers}"
    body_length_bytes = msg.body.respond_to?(:bytesize) ? msg.body.bytesize : msg.body.length
    puts "CONF: Received: #{body_length_bytes} bytes"
    connection.disconnect
    end_time = Time.now.to_f
    ppt = sprintf("%20.6f", end_time - start_time)
    puts "CONF: File consumed: #{ppt} seconds"
  end
end
#
e = FileReader.new(60)
e.run

