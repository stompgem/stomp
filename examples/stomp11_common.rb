# -*- encoding: utf-8 -*-

#
# Common Stomp 1.1 code.
#
require "rubygems" if RUBY_VERSION < "1.9"
require "stomp"
#
module Stomp11Common
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
    (ENV['STOMP_PORT'] || 61613).to_i # !! The author runs AMQ listening here
  end
  # Required vhost name
  def virt_host()
    ENV['STOMP_VHOST'] || "localhost" # The 1.1 virtual host name
  end
  # Create a 1.1 commection
  def get_connection()
    conn_hdrs = {"accept-version" => "1.1",    # 1.1 only
      "host" => virt_host,                     # the vhost
    }
    conn_hash = { :hosts => [
      {:login => login, :passcode => passcode, :host => host, :port => port},
      ],
      :connect_headers => conn_hdrs,
    }
    conn = Stomp::Connection.new(conn_hash)
  end

  # Number of messages
  def nmsgs()
    (ENV['STOMP_NMSGS'] || 1).to_i # Number of messages
  end

  # Include "suppress-content-length' header
  def suppresscl()
    ENV['STOMP_SUPPRESS_CL']
  end

end

