# -*- encoding: utf-8 -*-

if Kernel.respond_to?(:require_relative)
  require_relative("test_helper")
else
  $:.unshift(File.dirname(__FILE__))
  require 'test_helper'
end

=begin

  Main class for testing Stomp::Client URL based Logins.

=end
class TestURLLogins < Test::Unit::TestCase
  include TestBase

  def setup
    hostname = host()
    portnum = port()
    sslpn = ssl_port()
    @tdstomp = [
          "stomp://guestl:guestp@#{hostname}:#{portnum}",
          "stomp://#{hostname}:#{portnum}",
          "stomp://@#{hostname}:#{portnum}",
          "stomp://f@#$$%^&*()_+=o.o:@#{hostname}:#{portnum}",
          'stomp://f@#$$%^&*()_+=o.o::b~!@#$%^&*()+-_=?:<>,.@@' + hostname + ":#{portnum}",
    ]
    @tdfailover = [
      "failover://(stomp://#{hostname}:#{portnum})",
      "failover://(stomp://#{hostname}:#{portnum})",
      "failover://(stomp://#{hostname}:#{portnum})?whatup=doc&coyote=kaboom",
      "failover://(stomp://#{hostname}:#{portnum})?whatup=doc",
      "failover://(stomp://#{hostname}:#{portnum})?whatup=doc&coyote=kaboom&randomize=true",
      'failover://(stomp://f@#$$%^&*()_+=o.o::b~!@#$%^&*()+-_=?:<>,.@@' + "#{hostname}" + ":#{portnum}" + ")",
      'failover://(stomp://f@#$$%^&*()_+=o.o::b~!@#$%^&*()+-_=:<>,.@@' + "#{hostname}" + ":#{portnum}" + ")",
      'failover://(stomp://f@#$$%^&*()_+=o.o::b~!@#$%^&*()+-_=?:<>,.@@' + "#{hostname}" + ":#{portnum}" + ")?a=b",
      'failover://(stomp://f@#$$%^&*()_+=o.o::b~!@#$%^&*()+-_=:<>,.@@' + "#{hostname}" + ":#{portnum}" + ")?c=d&e=f",
      "failover://(stomp://usera:passa@#{hostname}:#{portnum})",
      "failover://(stomp://usera:@#{hostname}:#{portnum})",
      "failover://(stomp://#{hostname}:#{portnum},stomp://#{hostname}:#{portnum})",
      "failover://(stomp://usera:passa@#{hostname}:#{portnum},stomp://#{hostname}:#{portnum})",
      "failover://(stomp://usera:@#{hostname}:#{portnum},stomp://#{hostname}:#{portnum})",
      "failover://(stomp://#{hostname}:#{portnum},stomp://#{hostname}:#{portnum})?a=b&c=d",
      "failover://(stomp://#{hostname}:#{portnum},stomp://#{hostname}:#{portnum})?a=b&c=d&connect_timeout=2020",
    ]

    @sslfailover = [
      "failover://(stomp+ssl://#{hostname}:#{sslpn})",
      "failover://(stomp+ssl://usera:passa@#{hostname}:#{sslpn})",
      "failover://(stomp://usera:@#{hostname}:#{portnum},stomp+ssl://#{hostname}:#{sslpn})",
    ]

    @badparms = "failover://(stomp://#{hostname}:#{portnum})?a=b&noequal"

    @client = nil
  end

  def teardown
    @client.close if @client && @client.open? # allow tests to close
  end

  # test stomp:// URLs
  def test_0010_stomp_urls()
    @tdstomp.each_with_index do |url, ndx|
      c = Stomp::Client.new(url)
      assert !c.nil?, url
      assert c.open?, url
      c.close
    end
  end

  # test failover:// urls - tcp
  def test_0020_failover_urls_tcp()
    @tdfailover.each_with_index do |url, ndx|
      # p [ "xurl", url, "xndx", ndx ]
      c = Stomp::Client.new(url)
      assert !c.nil?, url
      assert c.open?, url
      c.close
    end
  end

  # test failover:// urls - ssl
  def test_0020_failover_urls_ssl()
    @sslfailover.each_with_index do |url, ndx|
      # p [ "sslxurl", url, "sslxndx", ndx ]
      c = Stomp::Client.new(url)
      assert !c.nil?, url
      assert c.open?, url
      c.close
    end
  end if ENV['STOMP_TESTSSL']

  # test failover:// with bad parameters
  def test_0020_failover_badparms()
    assert_raise(Stomp::Error::MalformedFailoverOptionsError) {
      _ = Stomp::Client.new(@badparms)
    }
  end

end unless ENV['STOMP_RABBIT']
