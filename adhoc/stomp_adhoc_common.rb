# -*- encoding: utf-8 -*-

#
# Common Stomp 1.1 code.
#
require "rubygems" if RUBY_VERSION < "1.9"
require "stomp"
#
module Stomp11Common
  # Port Constants locally
  STOMP_AMQ_PORT = ENV['STOMP_AMQ_PORT'] ? ENV['STOMP_AMQ_PORT'].to_i : 61613
  STOMP_APOLLO_PORT = ENV['STOMP_APOLLO_PORT'] ? ENV['STOMP_APOLLO_PORT'].to_i : 62613
  STOMP_ARTEMIS_PORT = ENV['STOMP_ARTEMIS_PORT'] ? ENV['STOMP_ARTEMIS_PORT'].to_i : 31613
  STOMP_SSNG_PORT = ENV['STOMP_SSNG_PORT'] ? ENV['STOMP_SSNG_PORT'].to_i : 51613
  STOMP_RMQ_PORT = ENV['STOMP_RMQ_PORT'] ? ENV['STOMP_RMQ_PORT'].to_i : 41613

  # Vhost Constants
  STOMP_RMQ_VHOST = ENV['STOMP_RMQ_VHOST'] || '/'
  STOMP_VHOST = ENV['STOMP_VHOST'] || 'localhost'

  # Client Protocol List
  STOMP_PROTOCOL = ENV['STOMP_PROTOCOL'] || "1.2"

  # User id
  def login()
    ENV['STOMP_USER'] || 'guest'
  end
  # Password
  def passcode()
    ENV['STOMP_PASSCODE'] || 'guest'
  end
  # Server host
  def host()
    ENV['STOMP_HOST'] || "localhost" # The connect host name
  end
  # Server port
  def port()
    if ENV['STOMP_AMQ']
      STOMP_AMQ_PORT
    elsif ENV['STOMP_APOLLO']
      STOMP_APOLLO_PORT
    elsif ENV['STOMP_RMQ']
      STOMP_RMQ_PORT
    elsif ENV['STOMP_SSNG']
      STOMP_SSNG_PORT
    elsif ENV['STOMP_PORT']
      ENV['STOMP_PORT'].to_i
    else
      61613 # The default ActiveMQ stomp listener port
    end
  end
  # Required vhost name
  def virt_host()
    if ENV['STOMP_RMQ']
      STOMP_RMQ_VHOST
    else
      STOMP_VHOST
    end
  end
  # Create a 1.1 commection
  def get_connection()
    conn_hdrs = {"accept-version" => STOMP_PROTOCOL,
      "host" => virt_host(),                     # the vhost
    }
    conn_hash = { :hosts => [
      {:login => login(), :passcode => passcode(), :host => host(), :port => port()},
      ],
      :connect_headers => conn_hdrs,
    }
    conn = Stomp::Connection.new(conn_hash)
  end

  # Number of messages
  def nmsgs()
    (ENV['STOMP_NMSGS'] || 1).to_i # Number of messages
  end

  # Queue / Topic Name
  def make_destination(right_part = nil, topic = false)
    if ENV['STOMP_DOTQUEUE']
      right_part.gsub!('/', '.')
    end
    if topic
      "/topic/#{right_part}"
    else
      "/queue/#{right_part}"
    end
  end

  # True if client should supply a receipt block on 'publish'
  def cli_block()
    ENV['STOMP_CLI_BLOCK']
  end

  # True if connection should ask for a receipt
  def conn_receipt()
    ENV['STOMP_RECEIPT']
  end
end # module
