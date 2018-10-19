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
  # CA private key file.  Change or specify.
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
  # Client cert file.  Change or specify.
	# This is the author's default.
  def cli_cert()
		ENV['CLI_FILE'] || "client.crt" # The client cert File
  end
  # Client private keyfile.  Change or specify.
	# This is the author's default.
	# This file should not be exposed to the outside world.
  def cli_key()
		ENV['CLI_KEY'] || nil # The client private key File
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

end

