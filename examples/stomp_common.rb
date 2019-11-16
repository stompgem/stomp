# -*- encoding: utf-8 -*-

#
# Common Stomp 1.x code.
#
require "rubygems" if RUBY_VERSION < "1.9"
require "stomp"
#
module Stomp1xCommon
  # User id
  def login()
    ENV['STOMP_LOGIN'] || 'guest'
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
    (ENV['STOMP_PORT'] || 61613).to_i # !! The author runs AMQ listening here
  end
  # Required vhost name
  def virt_host()
    ENV['STOMP_VHOST'] || "localhost" # The 1.1 virtual host name
  end
  # Protocol level
  def protocol()
    ENV['STOMP_PROTOCOL'] || "1.2" # The default protocol level
  end
  # Heartbeats
  def heartbeats()
    ENV['STOMP_HEARTBEATS'] || nil
  end
  # Destination
  def dest()
    ENV['STOMP_DEST'] || "/queue/#{Time.now.to_f}"
  end

  # Create a 1.x commection
  def get_connection()
    conn_hdrs = {"accept-version" => protocol(),
      "host" => virt_host(),                     # the vhost
    }
    if heartbeats()
      conn_hdrs['heart-beat'] = heartbeats()
    end

    conn_hash = { :hosts => [
      {:login => login(), :passcode => passcode(), :host => host(), :port => port(),
        :ssl => usessl()},
      ],
      :connect_headers => conn_hdrs,
    }
    conn_hash[:stompconn] = ENV["STOMP_USESTOMP"] ? true : false
    conn = Stomp::Connection.new(conn_hash)
  end

  # Create a 1.x client
  def get_client()
    conn_hdrs = {"accept-version" => protocol(),
      "host" => virt_host(),                     # the vhost
    }
    if heartbeats()
      conn_hdrs['heart-beat'] = heartbeats()
    end

    conn_hash = { :hosts => [
      {:login => login(), :passcode => passcode(), :host => host(), :port => port(),
        :ssl => usessl()},
      ],
      :connect_headers => conn_hdrs,
    }
    conn = Stomp::Client.new(conn_hash)
  end

  # Number of messages
  def nmsgs()
    (ENV['STOMP_NMSGS'] || 1).to_i # Number of messages
  end

  # Include "suppress-content-length' header
  def suppresscl()
    ENV['STOMP_SUPPRESS_CL']
  end

  # Use SSL or not
  def usessl()
    if ENV['STOMP_SSL']
      return true
    end
    return false
  end
end

