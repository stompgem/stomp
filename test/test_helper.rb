# -*- encoding: utf-8 -*-

require 'test/unit'
require 'timeout'

if Kernel.respond_to?(:require_relative)
  require_relative("../lib/stomp")
  require_relative("tlogger")
else
  $:.unshift(File.join(File.dirname(__FILE__), "..", "lib"))
  require 'stomp'
  require 'tlogger'
end

begin
  _ = RUBY_ENGINE
rescue NameError
  RUBY_ENGINE = "unknown"
end

=begin

  Test helper methods.

=end
module TestBase

  # Get user
  def user
    ENV['STOMP_USER'] || "guest"
  end

  # Gete passcode
  def passcode
    ENV['STOMP_PASSCODE'] || "guest"
  end

  # Get host
  def host
    ENV['STOMP_HOST'] || "localhost"
  end

  # Get port
  def port
    (ENV['STOMP_PORT'] || 61613).to_i
  end

  # Get SSL port
  def ssl_port
    (ENV['STOMP_SSLPORT'] || 61612).to_i
  end

  # Helper for minitest on 1.9
  def caller_method_name
    parse_caller(caller(2).first).last
  end

  # Helper for minitest on 1.9
  def parse_caller(at)
    if /^(.+?):(\d+)(?::in `(.*)')?/ =~ at
      file = Regexp.last_match[1]
      line = Regexp.last_match[2].to_i
      method = Regexp.last_match[3]
      method.gsub!(" ","_")
      [file, line, method]
    end
  end

  # Get a Stomp Connection.
  def get_connection()
    ch = get_conn_headers()
    hash = { :hosts => [ 
      {:login => user, :passcode => passcode, :host => host, :port => port, :ssl => nil},
      ],
      :reliable => false,
      :connect_headers => ch,
      :stompconn => get_stomp_conn(),
      :usecrlf => get_crlf(),
    }
    conn = Stomp::Connection.open(hash)
    conn
  end

  # Get a Stomp Anonymous Connection.
  def get_anonymous_connection()
    ch = get_conn_headers()
    hash = { :hosts => [
        {:host => host, :port => port, :ssl => nil},
    ],
             :reliable => false,
             :connect_headers => ch,
             :stompconn => get_stomp_conn(),
             :usecrlf => get_crlf(),
    }
    conn = Stomp::Connection.open(hash)
    conn
  end

  # Get a Stomp SSL Connection.
  def get_ssl_connection()
    ch = get_conn_headers()
    ssl_params = Stomp::SSLParams.new(:use_ruby_ciphers => jruby?())
    hash = { :hosts => [ 
      {:login => user, :passcode => passcode, :host => host, :port => ssl_port, :ssl => ssl_params},
      ],
      :connect_headers => ch,
      :stompconn => get_stomp_conn(),
      :usecrlf => get_crlf(),
    }
    conn = Stomp::Connection.new(hash)
    conn
  end

  # Get a Stomp Client.
  def get_client()
    hash = { :hosts => [ 
          {:login => user, :passcode => passcode, :host => host, :port => port},
          ],
          :connect_headers => get_conn_headers(),
          :stompconn => get_stomp_conn(),
          :usecrlf => get_crlf(),
        }

    client = Stomp::Client.new(hash)
    client
  end

  # Get a connection headers hash.
  def get_conn_headers()
    ch = {}
    if ENV['STOMP_TEST11p']
      #
      raise "Invalid 1.1 plus test protocol" if ENV['STOMP_TEST11p'] == Stomp::SPL_10
      #
      if Stomp::SUPPORTED.index(ENV['STOMP_TEST11p'])
        ch['accept-version'] = ENV['STOMP_TEST11p']
      else
        ch['accept-version'] = Stomp::SPL_11 # Just use 1.1
      end
      #
      ch['host'] = ENV['STOMP_RABBIT'] ? "/" : host
    end
    ch
  end

  # Determine if tests should use STOMP instead of CONNECT
  def get_stomp_conn()
    usc = false
    usc = true if ENV['STOMP_TEST11p'] && Stomp::SUPPORTED.index(ENV['STOMP_TEST11p']) && ENV['STOMP_TEST11p'] >= Stomp::SPL_11 && ENV['STOMP_CONN']
    usc
  end

  # Determine if tests should \r\n as line ends
  def get_crlf()
    ucr = false
    ucr = true if ENV['STOMP_TEST11p'] && Stomp::SUPPORTED.index(ENV['STOMP_TEST11p']) && ENV['STOMP_TEST11p'] >= Stomp::SPL_12 && ENV['STOMP_CRLF']
    ucr
  end

  # Subscribe to a destination.
  def conn_subscribe(dest, headers = {})
    if @conn.protocol >= Stomp::SPL_11
      headers[:id] = @conn.uuid() unless headers[:id]
    end
    @conn.subscribe dest, headers
  end

  # Get a dynamic destination name.
  def make_destination
    name = caller_method_name unless name
    case
      when ENV['STOMP_DOTQUEUE']
        qname = "/queue/test.ruby.stomp." + name
      when ENV['STOMP_ARTEMIS']
        qname = "jms.queue.queue.test.ruby.stomp." + name
      else
        qname = "/queue/test/ruby/stomp/" + name
    end
    return qname
  end

  # get DLQ name
  def make_dlq
    return "jms.queue.DLQ" if ENV['STOMP_ARTEMIS']
    "/queue/DLQ"
  end

  #
  def checkEmsg(cc)
    m = cc.poll
    if m
      assert m.command != Stomp::CMD_ERROR, "checkEmsg"
    end
  end

  # Check for JRuby before a connection exists
  def jruby?()
    jr = defined?(RUBY_ENGINE) && RUBY_ENGINE =~ /jruby/ ? true : false
    return jr
  end

  # OK Data For Default Tests
  def dflt_data_ok()
    [
       #
       {  :hosts => [
          {:login => 'guest', :passcode => 'guest', :host => "localhost", :port => 61613, :ssl => false},
          ],
       :reliable => false,
       },
       #
       {  :hosts => [
          {:login => 'guest', :passcode => 'guest', :ssl => false},
          ],
       :reliable => false,
       },
       #
       {  :hosts => [
          {:login => 'guest', :passcode => 'guest', :port => 61613, :ssl => false},
          ],
       :reliable => false,
       },
       #
       {  :hosts => [
          {:login => 'guest', :passcode => 'guest', :host => "localhost" , :ssl => false},
          ],
       :reliable => false,
       },
       #
       {  :hosts => [
          {:login => 'guest', :passcode => 'guest', :host => '' , :ssl => false},
          ],
       :reliable => false,
       },
    ]
  end

  # Exception Data For Default Tests
  def dflt_data_ex()
    [
      {},
      {:hosts => 123},
      {  :hosts => [
        {:login => 'guest', :passcode => 'guest', :host => "localhost", :port => '' , :ssl => false},
        ],
      :reliable => false,
      },
      {  :hosts => [
        {:login => 'guest', :passcode => 'guest', :host => "localhost", :port => -1 , :ssl => false},
        ],
      :reliable => false,
      },
    ]
  end
end

