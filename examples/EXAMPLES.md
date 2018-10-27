# stomp gem examples

This is to describe the existing stomp gem examples.

## Environment Variables

You will likely need to use supported environment variables to
define example related data elements for your system. See example
stomp_common.rb for details of support of this functionality.

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
    STOMP_LOGIN
    </td>
    <td style="border: 2px solid black;padding-left: 10px;" >
    The user ID when connecting to a broker.<br/>
    Default: guest.
    </td>
</tr>
<!--                                                      -->
<tr>
    <td style="border: 2px solid black;padding-left: 10px;" >
    STOMP_PASSCODE
    </td>
    <td style="border: 2px solid black;padding-left: 10px;" >
    The user password when connecting to a broker.<br/>
    Deault: guest.
    </td>
</tr>
<!--                                                      -->
<tr>
    <td style="border: 2px solid black;padding-left: 10px;" >
    STOMP_HOST
    </td>
    <td style="border: 2px solid black;padding-left: 10px;" >
    The broker host name.<br/>
    Default: localhost.
    </td>
</tr>
<!--                                                      -->
<tr>
    <td style="border: 2px solid black;padding-left: 10px;" >
    STOMP_PORT
    </td>
    <td style="border: 2px solid black;padding-left: 10px;" >
    The broker port number.<br/>
    Default: 61613.
    </td>
</tr>
<!--                                                      -->
<tr>
    <td style="border: 2px solid black;padding-left: 10px;" >
    STOMP_VHOST
    </td>
    <td style="border: 2px solid black;padding-left: 10px;" >
    The name of the broker's virtual host for 1.1+ connections.<br/>
    Default: localhost.
    </td>
</tr>
<!--                                                      -->
<tr>
    <td style="border: 2px solid black;padding-left: 10px;" >
    STOMP_PROTOCOL
    </td>
    <td style="border: 2px solid black;padding-left: 10px;" >
    The Stomp protocol level to use.<br/>
    Default: 1.2.
    </td>
</tr>
<!--                                                      -->
<tr>
    <td style="border: 2px solid black;padding-left: 10px;" >
    STOMP_HEARTBEATS
    </td>
    <td style="border: 2px solid black;padding-left: 10px;" >
    The Stomp heart beat parameters to use.<br/>
    Default: nil/none.
    </td>
</tr>
<!--                                                      -->
<tr>
    <td style="border: 2px solid black;padding-left: 10px;" >
    STOMP_NMSGS
    </td>
    <td style="border: 2px solid black;padding-left: 10px;" >
    The number of messages to put and/or get.<br/>
    Default: 1.
    </td>
</tr>
<!--                                                      -->
<tr>
    <td style="border: 2px solid black;padding-left: 10px;" >
    STOMP_DEST
    </td>
    <td style="border: 2px solid black;padding-left: 10px;" >
    The default name of a Stomp destination.<br/>
    Default: /queue/(time-stamp).
    </td>
</tr>
<!--                                                      -->
<tr>
    <td style="border: 2px solid black;padding-left: 10px;" >
    STOMP_SUPPRESS_CL
    </td>
    <td style="border: 2px solid black;padding-left: 10px;" >
    Whether to include a 'suppress_content_length' header in a message.<br/>
    Default: false.
    </td>
</tr>
<!--                                                      -->
<tr>
    <td style="border: 2px solid black;padding-left: 10px;" >
    STOMP_SSL
    </td>
    <td style="border: 2px solid black;padding-left: 10px;" >
    Whether to use an SSL connection.<br/>
    Default: false.
    </td>
</tr>
</table>

## General Examples

Note: you will need a running broker to use these examples.

### examples/client_conndisc.rb

A plain example of using a `Stomp#Client` to:

* Connect to a broker
* Disconnect from the broker

### examples/client_putget.rb

An example of using a `Stomp#Client` to:

* Connect to a broker
* Send and receive some message(s)
* Disconnect from the broker

### examples/conn_conndisc.rb

A plain example of using a `Stomp#Connection` to connect to:

* Connect to a broker
* Disconnect from the broker

### examples/conn_putget.rb

An example of using a `Stomp#Connection` to:

* Connect to a broker
* Send and receive some message(s)
* Disconnect from the broker

### examples/examplogger.rb

This example shows how to write a Stomp gem callback logger.

A callback logger can be used to greatly enhance understanding of
application flow, and the gem actions resulting from that flow.

### examples/logexamp.rb

This example shows how to use the example callback logger in
'examples/examplogger.rb'.

### examples/putget_file.rb

This example is primarily meant to measure performance when sending
 (possibly) large messages.

This example show how to:

* Open a file
* Read the entire file into a buffer
* Close the file
* Connect to a broker
* Send the entire file as a single message
* Disconnect from the broker

### examples/putget_rephdrs.rb

The Stomp 1.1+ specifications describe functionality for supporting multiple user supplied
headers with the same header key.

Experience shows that various real world brokers support this functionality
in a variety of ways.

The gem supports multiple headers with the same key.  This example
demonstrates that support.

However, given the variety of broker support, this example works only with the
(now defunct?) Apache Apollo broker.

You should modify the example to work with other brokers.

## Artemis Specific Examples

The Apache Artemis broker exhibits some behavior that is unusual for a
Stomp broker.

This behavior is to sever connections fairly quickly if there is no
activity on the connection.  The current default is 1 minute of
inactivity.

There are several approaches that a client can use to 'bypass' this
behavior.

### examples/artemis/cliwaiter_not_reliable.rb

This example uses a `Stomp#Client` that specifies `:reliable => false` in the
connection parameters.

### examples/artemis/cliwaiter_reliable_hb.rb

This example uses a `Stomp#Client` that specifies `:reliable => true` in the
connection parameters and also uses Stomp heart beats to help keep a connection
alive.


## Historical Examples

These are examples that are bing kept for historical reasons.  They
have been part of the gem's history since very early days of development.

### examples/historical/consumer.rb

The classical message consumer.

### examples/historical/producer.rb

The classical message producer.

### examples/historical/topic_consumer.rb

The classical message consumer (from a topic).

### examples/historical/topic_producer.rb

The classical message producer (to a topic).
