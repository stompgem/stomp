# -*- encoding: utf-8 -*-

require 'rubygems'
require 'stomp'
require 'logger'  # for the 'local' logger
#
if Kernel.respond_to?(:require_relative)
  require_relative("./stomp_common")  
  require_relative("./examplogger")
else
  $LOAD_PATH << File.dirname(__FILE__)
  require "examplogger"
  require("stomp_common")  
end
include Stomp1xCommon
#
# == A program which demonstrates the callback logging facility.
#
# With appropriate specification of STOMP_PORT, this code should also
# demonstrate failover.
#
class LoggerExample
  # Initialize.
  def initialize
  end
  # Run example.
  def run
    llog =        Logger::new(STDOUT)
    llog.level =  Logger::DEBUG
    llog.debug "LE Starting"

    # //////////////////////////////////////////////////////////////////////////////
    mylog = Slogger::new  # The client provided STOMP callback logger
    # //////////////////////////////////////////////////////////////////////////////
    user =      ENV['STOMP_USER'] ? ENV['STOMP_USER'] : 'guest'
    password =  ENV['STOMP_PASSWORD'] ? ENV['STOMP_PASSWORD'] : 'guest'
    host =      ENV['STOMP_HOST'] ? ENV['STOMP_HOST'] : 'localhost'
    port =      ENV['STOMP_PORT'] ? ENV['STOMP_PORT'].to_i : 61613
    so =        usessl()
    # //////////////////////////////////////////////////////////////////////////////
    # A hash type connect *MUST* be used to enable callback logging.
    # //////////////////////////////////////////////////////////////////////////////
    # Note:  running this example will generate a number of connect failures,
    # because of the fake host in this connect hash.
    # //////////////////////////////////////////////////////////////////////////////
    hash = { :hosts => [
        {:login => user, :passcode => password, :host => 'noonehome', :port => 2525,
          :ssl => so},
        {:login => user, :passcode => password, :host => host, :port => port,
          :ssl => so},
      ],
      :logger => mylog,	# This enables callback logging!
      :max_reconnect_attempts => 5,
    }

    # //////////////////////////////////////////////////////////////////////////////
    # For a Connection:
    llog.debug "LE Connection processing starts"
    conn = Stomp::Connection.new(hash)
    conn.disconnect()

    # //////////////////////////////////////////////////////////////////////////////
    llog.debug "LE Connection processing complete"

    # //////////////////////////////////////////////////////////////////////////////
    # For a Client:
    llog.debug "LE Client processing starts"
    client = Stomp::Client.new(hash)
    client.close()

    # //////////////////////////////////////////////////////////////////////////////
    llog.debug "LE Client processing complete"

    # //////////////////////////////////////////////////////////////////////////////
    # For a Connection with other calls:
    llog.debug "LE Connection Enhanced processing starts"
    conn = Stomp::Connection.new(hash)
    #
    dest = "/queue/loggerq1"
    conn.publish dest, "a logger message"
    conn.subscribe(dest)
    msg = conn.receive()
    conn.disconnect()

    # //////////////////////////////////////////////////////////////////////////////
    llog.debug "LE Connection Enhanced processing complete"

    # //////////////////////////////////////////////////////////////////////////////
    llog.debug "LE Ending"
  end
end
e = LoggerExample.new()
e.run()
