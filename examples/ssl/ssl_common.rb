# -*- encoding: utf-8 -*-

#
# Common Stomp 1.1 code.
#
require "rubygems" if RUBY_VERSION < "1.9"
require "stomp"
#
module SSLCommon

	# CA Data.

  # CA cert file location/directory.  Change or specify.
	# This is the author's default.
  def ca_loc()
		ENV['CA_FLOC'] || "/ad3/gma/ad3/sslwork/2017-01" # The CA cert location
  end

	# CA cert file.  Change or specify.
	# This is the author's default.
  def ca_cert()
		ENV['CA_FILE'] || "ca.crt" # The CA cert File
  end

	# CA private key file name.  Change or specify.
	# This is the author's default.
	# This file should not be exposed to the outside world.
	# Not currently used/needed in stomp examples.
  def ca_key()
		ENV['CA_KEY'] || nil # The CA private key File
  end

	# Client Data.

  # Client cert file location/directory.  Change or specify.
	# This is the author's default.
  def cli_loc()
		ENV['CLI_FLOC'] || "/ad3/gma/ad3/sslwork/2017-01" # The client cert location
	end

  # Client cert file name.  Change or specify.
	# This is the author's default.
  def cli_cert()
		ENV['CLI_FILE'] || "client.crt" # The client cert File
	end

  # Client private key file name.  Change or specify.
	# This is the author's default.
	# This file should not be exposed to the outside world.
  def cli_key()
		ENV['CLI_KEY'] || pck() # The client private key File
  end

  # Client cert file name.  Change or specify.
  # This is the author's default.
  def cli_cert_text()
    fake_cert = '------BEGIN CERTIFICATE-----
    fake_cert
    ------END CERTIFICATE-----'

    # The client cert text is stored in environmental variable
    ENV['CLI_CERT_TEXT'] || fake_cert
    
  end

  # Client private key .  Change or specify.
  # This is the author's default.
  # This file should not be exposed to the outside world.
  def cli_key_text()
    fake_key = '-----BEGIN PRIVATE KEY-----
    fake_key
    -----END PRIVATE KEY-----'

    # The client private key text is stored in environment variable
    ENV['CLI_KEY_TEXT'] ||  fake_key
  end

	# Server Data.

  # Server file location/directory.  Change or specify.
	# This is the author's default.
	# Not currently used in stomp examples.
  def svr_loc()
		ENV['SVR_FLOC'] || "/ad3/gma/ad3/sslwork/2017-01" # The server cert location
	end

  # Server cert file.  Change or specify.
	# This is the author's default.
	# Not currently used in stomp examples.
  def svr_cert()
		ENV['SVR_FILE'] || "server.crt" # The server cert File
	end

  # Server private keyfile.  Change or specify.
	# This is the author's default.
	# This file should not be exposed to the outside world.
	# Not currently used in stomp examples.
  def svr_key()
		ENV['SVR_KEY'] || nil # The server private key File
  end
	# Show peer cert or not
	def showPeerCert()
		ENV['SHOWPEERCERT'] || false
	end

	# Ciphers list for the ciphers examples
	def ciphers_list()
		[["DHE-RSA-AES256-SHA", "TLSv1/SSLv3", 256, 256], ["DHE-DSS-AES256-SHA", "TLSv1/SSLv3", 256, 256], ["AES256-SHA", "TLSv1/SSLv3", 256, 256], ["EDH-RSA-DES-CBC3-SHA", "TLSv1/SSLv3", 168, 168], ["EDH-DSS-DES-CBC3-SHA", "TLSv1/SSLv3", 168, 168], ["DES-CBC3-SHA", "TLSv1/SSLv3", 168, 168], ["DHE-RSA-AES128-SHA", "TLSv1/SSLv3", 128, 128], ["DHE-DSS-AES128-SHA", "TLSv1/SSLv3", 128, 128], ["AES128-SHA", "TLSv1/SSLv3", 128, 128], ["RC4-SHA", "TLSv1/SSLv3", 128, 128], ["RC4-MD5", "TLSv1/SSLv3", 128, 128], ["EDH-RSA-DES-CBC-SHA", "TLSv1/SSLv3", 56, 56], ["EDH-DSS-DES-CBC-SHA", "TLSv1/SSLv3", 56, 56], ["DES-CBC-SHA", "TLSv1/SSLv3", 56, 56], ["EXP-EDH-RSA-DES-CBC-SHA", "TLSv1/SSLv3", 40, 56], ["EXP-EDH-DSS-DES-CBC-SHA", "TLSv1/SSLv3", 40, 56], ["EXP-DES-CBC-SHA", "TLSv1/SSLv3", 40, 56], ["EXP-RC2-CBC-MD5", "TLSv1/SSLv3", 40, 128], ["EXP-RC4-MD5", "TLSv1/SSLv3", 40, 128]]
	end

	# Private
	private

	# Client Key File
	def pck()
		"client.key"
	end

end

