# -*- encoding: utf-8 -*-

module Stomp
 #
 # == Purpose
 #
 # Parameters for STOMP ssl connections.
 #
 class SSLParams

  # The trust store files. Normally the certificate of the CA that signed
  # the server's certificate. One file name, or a CSV list of file names.
  attr_accessor :ts_files

  # The client certificate file.
  attr_accessor :cert_file

  # The client private key file.
  attr_accessor :key_file

# The client certificate text.
  attr_accessor :cert_text

  # The client private key text.
  attr_accessor :key_text

  # The client private key password.
  attr_accessor :key_password

  # SSL Connect Verify Result.  The result of the handshake.
  attr_accessor :verify_result

  # The certificate of the connection peer (the server), received during
  # the handshake.
  attr_accessor :peer_cert

  # Optional list of SSL ciphers to be used.  In the format documented for
  # Ruby's OpenSSL.
  attr_accessor :ciphers

  # Absolute command to use Ruby default ciphers.
  attr_reader :use_ruby_ciphers

  # Back reference to the OpenSSL::SSL::SSLContext instance, gem sets before connect.
  attr_accessor :ctx # Set by the gem during connect, before the callbacks

  # Client wants file existance check on initialize. true/value or false/nil.
  attr_reader :fsck #

  # SSLContext options.
  attr_reader :ssl_ctxopts #

  # initialize returns a valid instance of SSLParams or raises an error.
  def initialize(opts={})

   # Server authentication parameters
   @ts_files = opts[:ts_files]   # A trust store file, normally a CA's cert
   # or a CSV list of cert file names

   # Client authentication parameters
   @cert_file = opts[:cert_file]         # Client cert file
   @key_file = opts[:key_file]           # Client key file
   @cert_text = opts[:cert_text]         # Client cert text
   @key_text = opts[:key_text]           # Client key text
   @key_password = opts[:key_password]   # Client key password
   #
   raise Stomp::Error::SSLClientParamsError if !@cert_file.nil? && @key_file.nil? && @key_text.nil?
   raise Stomp::Error::SSLClientParamsError if !@cert_text.nil? && @key_file.nil? && @key_text.nil?
   raise Stomp::Error::SSLClientParamsError if !@cert_text.nil? && !@cert_file.nil?

   raise Stomp::Error::SSLClientParamsError if !@key_file.nil? && @cert_file.nil? && @cert_text.nil?
   raise Stomp::Error::SSLClientParamsError if !@key_text.nil? && @cert_file.nil? && @cert_text.nil?
   raise Stomp::Error::SSLClientParamsError if !@key_text.nil? && !@key_file.nil?

   #
   @ciphers = opts[:ciphers]
   @use_ruby_ciphers = opts[:use_ruby_ciphers] ? opts[:use_ruby_ciphers] : false
   #
   if opts[:fsck]
    if @cert_file
     raise Stomp::Error::SSLNoCertFileError if !File::exist?(@cert_file)
     raise Stomp::Error::SSLUnreadableCertFileError if !File::readable?(@cert_file)
    end
    if @key_file
     raise Stomp::Error::SSLNoKeyFileError if !File::exist?(@key_file)
     raise Stomp::Error::SSLUnreadableKeyFileError if !File::readable?(@key_file)
    end
    if @ts_files
     tsa = @ts_files.split(",")
     tsa.each do |fn|
      raise Stomp::Error::SSLNoTruststoreFileError if !File::exist?(fn)
      raise Stomp::Error::SSLUnreadableTruststoreFileError if !File::readable?(fn)
     end
    end
   end
   # SSLContext options.  See example:  ssl_ctxoptions.rb.
   @ssl_ctxopts = opts[:ssl_ctxopts]  # nil or options to set
  end

 end # of class SSLParams

end # of module Stomp
