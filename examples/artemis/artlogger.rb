# -*- encoding: utf-8 -*-

require 'logger'	# use the standard Ruby logger .....
#
class Slogger

  # Initialize a new callback logger instance.
  def initialize(init_parms = nil)
    _init
    @log.info("Logger initialization complete.")
  end

  def _init
    @log = Logger::new(STDERR)		# User preference
    @log.level = Logger::DEBUG		# User preference
  end

  # Log connecting events
  def on_connecting(parms)
    begin
      @log.debug "Connecting: #{parms}"
    rescue Exception => ex
      @log.debug "Connecting oops"
      print ex.backtrace.join("\n")
    end
  end

  # Log connected events
  def on_connected(parms)
    begin
      @log.debug "Connected: #{parms}"
    rescue Exception => ex
      @log.debug "Connected oops"
      print ex.backtrace.join("\n")
    end
  end

  private

end # of class

