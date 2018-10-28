# SSL Examples

This is to provide additional documentation regarding the gem's
SSL related examples.

This documentation is based on experiments with OpenSSL.


## Environment Variables

You will likely need to use supported environment variables to
define SSL related data locations on your system. See example
ssl_common.rb for details of support of this functionality.

<table border="2" style="width:100%;border: 2px solid black;">
<tr>
    <th style="border: 2px solid black;padding-left: 10px;" >
    Environment Variable
    </th>
    <th style="border: 2px solid black;padding-left: 10px;" >
    Description
    </th>
</tr>
<!--                                                      -->
<tr>
    <td style="border: 2px solid black;padding-left: 10px;" >
    CA_FLOC
    </td>
    <td style="border: 2px solid black;padding-left: 10px;" >
    CA cert file location/directory.
    </td>
</tr>
<!--                                                      -->
<tr>
    <td style="border: 2px solid black;padding-left: 10px;" >
    CLI_FLOC
    </td>
    <td style="border: 2px solid black;padding-left: 10px;" >
    Client cert file location/directory.
    </td>
</tr>
<!--                                                      -->
<tr>
    <td style="border: 2px solid black;padding-left: 10px;" >
    CLI_FILE
    </td>
    <td style="border: 2px solid black;padding-left: 10px;" >
        Clent cert file name.
    </td>
</tr>
<!--                                                      -->
<tr>
    <td style="border: 2px solid black;padding-left: 10px;" >
    CLI_KEY
    </td>
    <td style="border: 2px solid black;padding-left: 10px;" >
    Client private key file name. This file should not be 
    exposed to the outside world.
    </td>
</tr>
<!--                                                      -->
<tr>
    <td style="border: 2px solid black;padding-left: 10px;" >
    STOMP_HOST
    </td>
    <td style="border: 2px solid black;padding-left: 10px;" >
    The host name of your SSL broker.
    </td>
</tr>
<!--                                                      -->
<tr>
    <td style="border: 2px solid black;padding-left: 10px;" >
    STOMP_PORT
    </td>
    <td style="border: 2px solid black;padding-left: 10px;" >
    The the TCP port number used by your SSL broker.
    </td>
</tr>
</table>

## The Four Main SSL Use Cases

There are four main SSL use cases.  Example code for each of these can be found
in the 'examples/uc?' subdirectories.  Each individual use case is described below.

Each 'sxamples/uc?' subdirectory contains two example programs:

* A primary demonstration of the example
* A secondary demonstration of the example where client code overrides the
default list of ciphers that SSL considers.

Note that each use case has two subcases:

* Your broker does _not_ require client authentication
* Your broker _does_ require client authentication

### Use Case 1 - No Authentification by broker or client

Subcase A - When your broker does _not_ require client authentication:


* Expect connection success.
* Expect a verify result of 20 becuase the client did not authenticate the
server's certificate.


Subcase B - When your broker _does_ require client authentication:

* Expect connection failure (broker must be sent a valid client certificate).

### Use Case 2 - No Authentification by broker, authentification by client

Subcase A - When your broker does _not_ require client authentication:

* Expect connection success
* Expect a verify result of 0 becuase the client did authenticate the
server's certificate.

Subcase B - When your broker _does_ require client authentication:

* Expect connection failure (broker must be sent a valid client certificate).

### Use Case 3 - Authentification by broker, no authentification by client

Subcase A - When your broker does _not_ require client authentication:

* Expect connection success
* Expect a verify result of 20 becuase the client did not authenticate the
server's certificate.

Subcase B - When your broker _does_ require client authentication:

* Expect connection success if the server can authenticate the client certificate
* Expect a verify result of 20 because the client did not authenticate the
server's certificate.

### Use Case 4 - Authentification by both broker and client

Subcase A - When your broker does _not_ require client authentication:

* Expect connection success
* Expect a verify result of 0 becuase the client did authenticate the
server's certificate.

Subcase B - When your broker _does_ require client authentication:

* Expect connection success if the server can authenticate the client certificate
* Expect a verify result of 0 because the client did authenticate the
server's certificate.

## Miscellaneous SSL Examples

The gem provides several other examples of using the built-in SSL
functionality.  These examples are described below.

### Override SSL Context Options

This example is in 'examples/misc/ssl_ctxoptions.rb'.

The gem provides the capability for the client to supply SSL context options
to be used during an SSL connect.

These options are passed to the gem in the `Stomp::SSLParams` instance.

These options are then placed by the gem in the `OpenSSL::SSL::SSLContext` instance used during
an SSL connect.

### Specify Parameters When SSL Context Options Are Created

This example is in 'examples/misc/ssl_newparm.rb'.

The gem provides the capability of passing parameters to
`OpenSSL::SSL::SSLContext.new(..)`.

These options are passed to the gem in the connect hash used for open/new.

### Override The Default Cipher List Used BY SSL

This example is in 'examples/misc/ssl_ucx_default_ciphers.rb'.

Note:  this example is _not_ for use in JRuby.

The gem allows use of a default list of fairly well known and broker
supported ciphers found in `Stomp::DEFAULT_CIPHERS`.

However, the default list of Ruby ciphers can be requested.

This is requested when `Stomp::SSLParams` is created by the client using the
`:use_ruby_ciphers => true` parameter.
