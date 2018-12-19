# -*- encoding: utf-8 -*-

if Kernel.respond_to?(:require_relative)
  require_relative("test_helper")
else
  $:.unshift(File.dirname(__FILE__))
  require 'test_helper'
end

=begin

  Main class for testing Stomp::SSLParams.

=end
class TestSSL < Test::Unit::TestCase
  include TestBase
  
  def setup
    @conn = get_ssl_connection()
    @tssdbg = ENV['TSSDBG'] || ENV['TDBGALL']  ? true : false 
  end

  def teardown
    @conn.disconnect if @conn && @conn.open? # allow tests to disconnect
  end
  #
  def test_ssl_0000
    mn = "test_ssl_0000" if @tssdbg
    p [ "01", mn, "starts" ] if @tssdbg
    assert @conn.open?
    p [ "99", mn, "ends" ] if @tssdbg
  end

  # Test SSLParams basic.
  def test_ssl_0010_parms
    mn = "test_ssl_0010_parms" if @tssdbg
    p [ "01", mn, "starts" ] if @tssdbg

    ssl_params = Stomp::SSLParams.new
    assert ssl_params.ts_files.nil?
    assert ssl_params.cert_file.nil?
    assert ssl_params.key_file.nil?
    assert ssl_params.fsck.nil?
    p [ "99", mn, "ends" ] if @tssdbg
  end

  # Test using correct parameters.
  def test_ssl_0020_noraise
    mn = "test_ssl_0020_noraise" if @tssdbg
    p [ "01", mn, "starts" ] if @tssdbg

    _ = Stomp::SSLParams.new(:cert_file => "dummy1", :key_file => "dummy2")
    _ = Stomp::SSLParams.new(:cert_file => "dummy1", :key_text => "dummy3")
    _ = Stomp::SSLParams.new(:cert_text => "dummy1", :key_file => "dummy2")
    _ = Stomp::SSLParams.new(:cert_text => "dummy4", :key_text => "dummy3")
    _ = Stomp::SSLParams.new(:ts_files => "dummyts1")
    _ = Stomp::SSLParams.new(:ts_files => "dummyts1", 
      :cert_file => "dummy1", :key_file => "dummy2")
    p [ "99", mn, "ends" ] if @tssdbg
  end

  # Test using incorrect / incomplete parameters.
  def test_ssl_0030_raise
    mn = "test_ssl_0030_raise" if @tssdbg
    p [ "01", mn, "starts" ] if @tssdbg

    key_text = '-----BEGIN PRIVATE KEY-----
    fake_key
    -----END PRIVATE KEY-----'
    cert_text = '------BEGIN CERTIFICATE-----
    fake_cert
    ------END CERTIFICATE-----'

    assert_raise(Stomp::Error::SSLClientParamsError) {
      _ = Stomp::SSLParams.new(:cert_file => "dummy1")
    }
    assert_raise(Stomp::Error::SSLClientParamsError) {
      _ = Stomp::SSLParams.new(:cert_text => cert_text)
    }
    assert_raise(Stomp::Error::SSLClientParamsError) {
      _ = Stomp::SSLParams.new(:key_file => "dummy2")
    }
    assert_raise(Stomp::Error::SSLClientParamsError) {
      _ = Stomp::SSLParams.new(:key_text => key_text)
    }
    assert_raise(Stomp::Error::SSLClientParamsError) {
      _ = Stomp::SSLParams.new(:cert_text => cert_text, :cert_file => "dummy1")
    }
    assert_raise(Stomp::Error::SSLClientParamsError) {
      _ = Stomp::SSLParams.new(:key_text => key_text, :cert_text => cert_text, :cert_file => "dummy1")
    }
    assert_raise(Stomp::Error::SSLClientParamsError) {
      _ = Stomp::SSLParams.new(:key_file => "dummy2", :cert_text => cert_text, :cert_file => "dummy1")
    }
    assert_raise(Stomp::Error::SSLClientParamsError) {
      _ = Stomp::SSLParams.new(:key_text => key_text, :key_file => "dummy2")
    }
    assert_raise(Stomp::Error::SSLClientParamsError) {
      _ = Stomp::SSLParams.new(:cert_file => "dummy1", :key_text => key_text, :key_file => "dummy2")
    }
    assert_raise(Stomp::Error::SSLClientParamsError) {
      _ = Stomp::SSLParams.new(:cert_text => cert_text, :key_text => key_text, :key_file => "dummy2")
    }
    p [ "99", mn, "ends" ] if @tssdbg
  end

  # Test that :fsck works.
  def test_ssl_0040_fsck
    mn = "test_ssl_0040_fsck" if @tssdbg
    p [ "01", mn, "starts" ] if @tssdbg

    assert_raise(Stomp::Error::SSLNoCertFileError) {
      _ = Stomp::SSLParams.new(:cert_file => "dummy1", 
        :key_file => "dummy2", :fsck => true)
    }
    assert_raise(Stomp::Error::SSLNoKeyFileError) {
      _ = Stomp::SSLParams.new(:cert_file => __FILE__,
        :key_file => "dummy2", :fsck => true)
    }
    assert_raise(Stomp::Error::SSLNoTruststoreFileError) {
      _ = Stomp::SSLParams.new(:ts_files => "/tmp/not-likely-here.txt", 
        :fsck => true)
    }
    p [ "99", mn, "ends" ] if @tssdbg
  end

  #
end if ENV['STOMP_TESTSSL']

