# README

* [Project Information](https://github.com/stompgem/stomp)

## Overview

An implementation of the Stomp protocol for Ruby. See:

* [STOMP 1.0, 1.1, and 1.2] (http://stomp.github.com/index.html)

## Hash Login Example Usage (**this is the recommended login technique**):

```
    hash = {
        :hosts => [
        # First connect is to remotehost1
        {:login => "login1", :passcode => "passcode1", :host => "remotehost1", :port => 61612, :ssl => true},
        # First failover connect is to remotehost2
        {:login => "login2", :passcode => "passcode2", :host => "remotehost2", :port => 61613, :ssl => false},
        ],
        # These are the default parameters and do not need to be set
        :reliable => true,                  # reliable (use failover)
        :initial_reconnect_delay => 0.01,   # initial delay before reconnect (secs)
        :max_reconnect_delay => 30.0,       # max delay before reconnect
        :use_exponential_back_off => true,  # increase delay between reconnect attpempts
        :back_off_multiplier => 2,          # next delay multiplier
        :max_reconnect_attempts => 0,       # retry forever, use # for maximum attempts
        :randomize => false,                # do not radomize hosts hash before reconnect
        :connect_timeout => 0,              # Timeout for TCP/TLS connects, use # for max seconds
        :connect_headers => {},             # user supplied CONNECT headers (req'd for Stomp 1.1+)
        :parse_timeout => 5,                # IO::select wait time on socket reads
        :logger => nil,                     # user suplied callback logger instance
        :dmh => false,                      # do not support multihomed IPV4 / IPV6 hosts during failover
        :closed_check => true,              # check first if closed in each protocol method
        :hbser => false,                    # raise on heartbeat send exception
        :stompconn => false,                # Use STOMP instead of CONNECT
        :usecrlf => false,                  # Use CRLF command and header line ends (1.2+)
        :max_hbread_fails => 0,             # Max HB read fails before retry.  0 => never retry
        :max_hbrlck_fails => 0,             # Max HB read lock obtain fails before retry.  0 => never retry
        :fast_hbs_adjust => 0.0,            # Fast heartbeat senders sleep adjustment, seconds, needed ...
                                            # For fast heartbeat senders.  'fast' == YMMV.  If not
                                            # correct for your environment, expect unnecessary fail overs
        :connread_timeout => 0,             # Timeout during CONNECT for read of CONNECTED/ERROR, secs
        :tcp_nodelay => true,               # Turns on the TCP_NODELAY socket option; disables Nagle's algorithm
        :start_timeout => 0,                # Timeout around Stomp::Client initialization
        :sslctx_newparm => nil,             # Param for SSLContext.new
        :ssl_post_conn_check => true,       # Further verify broker identity
      }

      # for a client
      client = Stomp::Client.new(hash)

      # for a connection
      connection = Stomp::Connection.new(hash)
```

### Positional Parameter Usage:

```
    client = Stomp::Client.new("user", "pass", "localhost", 61613)
    client.publish("/queue/mine", "hello world!")
    client.subscribe("/queue/mine") do |msg|
        p msg
    end
```

### Stomp URL Usage:

A Stomp URL must begin with 'stomp://' and can be in one of the following forms:

```
    stomp://host:port
    stomp://host.domain.tld:port
    stomp://login:passcode@host:port
    stomp://login:passcode@host.domain.tld:port
    
    # e.g. c = Stomp::Client.new(urlstring)
```

### Failover + SSL Example URL Usage:

```
    options = "initialReconnectDelay=5000&randomize=false&useExponentialBackOff=false"
    # remotehost1 uses SSL, remotehost2 doesn't
    client = Stomp::Client.new("failover:(stomp+ssl://login1:passcode1@remotehost1:61612,stomp://login2:passcode2@remotehost2:61613)?#{options}")
    client.publish("/queue/mine", "hello world!")
    client.subscribe("/queue/mine") do |msg|
        p msg
    end
```

### New:

See _CHANGELOG.rdoc_ for details.

* Gem version 1.4.4. Miscellaneous fixes, see CHANGELOG.rdoc for details.
* Gem version 1.4.3. Fix broken install.  Do not try to install 1.4.2.
* Gem version 1.4.2. Fix memory leak, and others !: see CHANGELOG.md for details.
* Gem version 1.4.1. Important SSL changes !: see CHANGELOG.md for details.
* Gem version 1.4.0. Note: Change sementics of :parse_timeout, see CHANGELOG.md for details.
* Gem version 1.3.5. Miscellaneous fixes, see CHANGELOG.rdoc for details.
* Gem version 1.3.4. Miscellaneous fixes, see CHANGELOG.rdoc for details.
* Gem version 1.3.3. Miscellaneous fixes, see CHANGELOG.rdoc for details.
* Gem version 1.3.2. Miscellaneous fixes, see changelog for details.
* Gem version 1.3.1. Bugfix for logging.
* Gem version 1.3.0. Added ERROR frame raising as exception, added anonymous connections, miscellaneous other fixes.

For changes in older versions see CHANGELOG.rdoc for details.

### Historical Information:

Up until March 2009 the project was maintained and primarily developed by Brian McCallister.

### Source Code and Project URLs:

  [Source Code and Project](https://github.com/stompgem/stomp)

### Stomp Protocol Information:

  [Protocol Information](http://stomp.github.com/index.html)

#### Contributors (by first author date) ####

Contribution information:

<table border="1" style="width:100%;border: 1px solid black;">
<tr>
<th style="border: 1px solid black;padding-left: 10px;" >
First Author Date
</th>
<th style="border: 1px solid black;padding-left: 10px;" >
(Commit Count)
</th>
<th style="border: 1px solid black;padding-left: 10px;" >
Name / E-mail
</th>
</tr>
<tr>
<td style="border: 1px solid black;padding-left: 10px;" >
2005-08-26
</td>
<td style="border: 1px solid black;padding-left: 10px;" >
(0023)
</td>
<td style="border: 1px solid black;padding-left: 10px;" >
<span style="font-weight: bold;" >
brianm
</span>
 / brianm@fd4e7336-3dff-0310-b68a-b6615a75f13b
</td>
</tr>
<tr>
<td style="border: 1px solid black;padding-left: 10px;" >
2006-03-16
</td>
<td style="border: 1px solid black;padding-left: 10px;" >
(0005)
</td>
<td style="border: 1px solid black;padding-left: 10px;" >
<span style="font-weight: bold;" >
jstrachan
</span>
 / jstrachan@fd4e7336-3dff-0310-b68a-b6615a75f13b
</td>
</tr>
<tr>
<td style="border: 1px solid black;padding-left: 10px;" >
2006-04-19
</td>
<td style="border: 1px solid black;padding-left: 10px;" >
(0001)
</td>
<td style="border: 1px solid black;padding-left: 10px;" >
<span style="font-weight: bold;" >
chirino
</span>
 / chirino@fd4e7336-3dff-0310-b68a-b6615a75f13b
</td>
</tr>
<tr>
<td style="border: 1px solid black;padding-left: 10px;" >
2007-05-09
</td>
<td style="border: 1px solid black;padding-left: 10px;" >
(0003)
</td>
<td style="border: 1px solid black;padding-left: 10px;" >
<span style="font-weight: bold;" >
kookster
</span>
 / kookster@fd4e7336-3dff-0310-b68a-b6615a75f13b
</td>
</tr>
<tr>
<td style="border: 1px solid black;padding-left: 10px;" >
2008-05-08
</td>
<td style="border: 1px solid black;padding-left: 10px;" >
(0016)
</td>
<td style="border: 1px solid black;padding-left: 10px;" >
<span style="font-weight: bold;" >
Glenn Rempe
</span>
 / glenn@rempe.us
</td>
</tr>
<tr>
<td style="border: 1px solid black;padding-left: 10px;" >
2009-02-03
</td>
<td style="border: 1px solid black;padding-left: 10px;" >
(0001)
</td>
<td style="border: 1px solid black;padding-left: 10px;" >
<span style="font-weight: bold;" >
Tony Garnock-Jones
</span>
 / tonyg@lshift.net
</td>
</tr>
<tr>
<td style="border: 1px solid black;padding-left: 10px;" >
2009-02-09
</td>
<td style="border: 1px solid black;padding-left: 10px;" >
(0003)
</td>
<td style="border: 1px solid black;padding-left: 10px;" >
<span style="font-weight: bold;" >
Marius Mathiesen
</span>
 / marius.mathiesen@gmail.com
</td>
</tr>
<tr>
<td style="border: 1px solid black;padding-left: 10px;" >
2009-02-13
</td>
<td style="border: 1px solid black;padding-left: 10px;" >
(0004)
</td>
<td style="border: 1px solid black;padding-left: 10px;" >
<span style="font-weight: bold;" >
Johan Sørensen
</span>
 / johan@johansorensen.com
</td>
</tr>
<tr>
<td style="border: 1px solid black;padding-left: 10px;" >
2009-11-17
</td>
<td style="border: 1px solid black;padding-left: 10px;" >
(0022)
</td>
<td style="border: 1px solid black;padding-left: 10px;" >
<span style="font-weight: bold;" >
Thiago Morello
</span>
 / thiago.morello@locaweb.com.br
</td>
</tr>
<tr>
<td style="border: 1px solid black;padding-left: 10px;" >
2009-11-22
</td>
<td style="border: 1px solid black;padding-left: 10px;" >
(0001)
</td>
<td style="border: 1px solid black;padding-left: 10px;" >
<span style="font-weight: bold;" >
unknown
</span>
 / katy@.(none)
</td>
</tr>
<tr>
<td style="border: 1px solid black;padding-left: 10px;" >
2009-12-18
</td>
<td style="border: 1px solid black;padding-left: 10px;" >
(0052)
</td>
<td style="border: 1px solid black;padding-left: 10px;" >
<span style="font-weight: bold;" >
Thiago Morello
</span>
 / morello@queroinfra32.fabrica.locaweb.com.br
</td>
</tr>
<tr>
<td style="border: 1px solid black;padding-left: 10px;" >
2009-12-25
</td>
<td style="border: 1px solid black;padding-left: 10px;" >
(0387)
</td>
<td style="border: 1px solid black;padding-left: 10px;" >
<span style="font-weight: bold;" >
gmallard
</span>
 / allard.guy.m@gmail.com
</td>
</tr>
<tr>
<td style="border: 1px solid black;padding-left: 10px;" >
2010-01-07
</td>
<td style="border: 1px solid black;padding-left: 10px;" >
(0007)
</td>
<td style="border: 1px solid black;padding-left: 10px;" >
<span style="font-weight: bold;" >
Rafael Rosa
</span>
 / rafael.rosa@locaweb.com.br
</td>
</tr>
<tr>
<td style="border: 1px solid black;padding-left: 10px;" >
2010-03-23
</td>
<td style="border: 1px solid black;padding-left: 10px;" >
(0042)
</td>
<td style="border: 1px solid black;padding-left: 10px;" >
<span style="font-weight: bold;" >
Guy M. Allard
</span>
 / allard.guy.m@gmail.com
</td>
</tr>
<tr>
<td style="border: 1px solid black;padding-left: 10px;" >
2010-04-01
</td>
<td style="border: 1px solid black;padding-left: 10px;" >
(0001)
</td>
<td style="border: 1px solid black;padding-left: 10px;" >
<span style="font-weight: bold;" >
Dmytro Shteflyuk
</span>
 / kpumuk@kpumuk.info
</td>
</tr>
<tr>
<td style="border: 1px solid black;padding-left: 10px;" >
2010-10-22
</td>
<td style="border: 1px solid black;padding-left: 10px;" >
(0001)
</td>
<td style="border: 1px solid black;padding-left: 10px;" >
<span style="font-weight: bold;" >
Neil Wilson
</span>
 / neil@aldur.co.uk
</td>
</tr>
<tr>
<td style="border: 1px solid black;padding-left: 10px;" >
2011-02-09
</td>
<td style="border: 1px solid black;padding-left: 10px;" >
(0001)
</td>
<td style="border: 1px solid black;padding-left: 10px;" >
<span style="font-weight: bold;" >
Dinesh Majrekar
</span>
 / dinesh.majrekar@advantage-interactive.com
</td>
</tr>
<tr>
<td style="border: 1px solid black;padding-left: 10px;" >
2011-04-15
</td>
<td style="border: 1px solid black;padding-left: 10px;" >
(0002)
</td>
<td style="border: 1px solid black;padding-left: 10px;" >
<span style="font-weight: bold;" >
Kiall Mac Innes
</span>
 / kiall@managedit.ie
</td>
</tr>
<tr>
<td style="border: 1px solid black;padding-left: 10px;" >
2011-04-29
</td>
<td style="border: 1px solid black;padding-left: 10px;" >
(0002)
</td>
<td style="border: 1px solid black;padding-left: 10px;" >
<span style="font-weight: bold;" >
Rob Skaggs
</span>
 / rob@pivotal-it.com
</td>
</tr>
<tr>
<td style="border: 1px solid black;padding-left: 10px;" >
2011-08-23
</td>
<td style="border: 1px solid black;padding-left: 10px;" >
(0003)
</td>
<td style="border: 1px solid black;padding-left: 10px;" >
<span style="font-weight: bold;" >
Tom May
</span>
 / tom@gist.com
</td>
</tr>
<tr>
<td style="border: 1px solid black;padding-left: 10px;" >
2011-08-24
</td>
<td style="border: 1px solid black;padding-left: 10px;" >
(0002)
</td>
<td style="border: 1px solid black;padding-left: 10px;" >
<span style="font-weight: bold;" >
Thiago Morello
</span>
 / morellon@gmail.com
</td>
</tr>
<tr>
<td style="border: 1px solid black;padding-left: 10px;" >
2011-09-11
</td>
<td style="border: 1px solid black;padding-left: 10px;" >
(0003)
</td>
<td style="border: 1px solid black;padding-left: 10px;" >
<span style="font-weight: bold;" >
Lucas Hills
</span>
 / info@lucashills.com
</td>
</tr>
<tr>
<td style="border: 1px solid black;padding-left: 10px;" >
2011-11-20
</td>
<td style="border: 1px solid black;padding-left: 10px;" >
(0002)
</td>
<td style="border: 1px solid black;padding-left: 10px;" >
<span style="font-weight: bold;" >
Chris Needham
</span>
 / chrisn303@gmail.com
</td>
</tr>
<tr>
<td style="border: 1px solid black;padding-left: 10px;" >
2011-12-11
</td>
<td style="border: 1px solid black;padding-left: 10px;" >
(0003)
</td>
<td style="border: 1px solid black;padding-left: 10px;" >
<span style="font-weight: bold;" >
R.I.Pienaar
</span>
 / rip@devco.net
</td>
</tr>
<tr>
<td style="border: 1px solid black;padding-left: 10px;" >
2011-12-13
</td>
<td style="border: 1px solid black;padding-left: 10px;" >
(0001)
</td>
<td style="border: 1px solid black;padding-left: 10px;" >
<span style="font-weight: bold;" >
tworker
</span>
 / tworker@onyx.ove.com
</td>
</tr>
<tr>
<td style="border: 1px solid black;padding-left: 10px;" >
2012-03-16
</td>
<td style="border: 1px solid black;padding-left: 10px;" >
(0001)
</td>
<td style="border: 1px solid black;padding-left: 10px;" >
<span style="font-weight: bold;" >
James Pearson
</span>
 / james@fearmediocrity.co.uk
</td>
</tr>
<tr>
<td style="border: 1px solid black;padding-left: 10px;" >
2012-05-10
</td>
<td style="border: 1px solid black;padding-left: 10px;" >
(0001)
</td>
<td style="border: 1px solid black;padding-left: 10px;" >
<span style="font-weight: bold;" >
Tommy Bishop
</span>
 / bishop.thomas@gmail.com
</td>
</tr>
<tr>
<td style="border: 1px solid black;padding-left: 10px;" >
2012-06-18
</td>
<td style="border: 1px solid black;padding-left: 10px;" >
(0002)
</td>
<td style="border: 1px solid black;padding-left: 10px;" >
<span style="font-weight: bold;" >
Jeremy Gailor
</span>
 / jeremy@infinitecube.com
</td>
</tr>
<tr>
<td style="border: 1px solid black;padding-left: 10px;" >
2013-02-20
</td>
<td style="border: 1px solid black;padding-left: 10px;" >
(0002)
</td>
<td style="border: 1px solid black;padding-left: 10px;" >
<span style="font-weight: bold;" >
JP Hastings-Spital
</span>
 / jphastings@gmail.com
</td>
</tr>
<tr>
<td style="border: 1px solid black;padding-left: 10px;" >
2013-03-14
</td>
<td style="border: 1px solid black;padding-left: 10px;" >
(0003)
</td>
<td style="border: 1px solid black;padding-left: 10px;" >
<span style="font-weight: bold;" >
glennr
</span>
 / glenn@siyelo.com
</td>
</tr>
<tr>
<td style="border: 1px solid black;padding-left: 10px;" >
2013-07-29
</td>
<td style="border: 1px solid black;padding-left: 10px;" >
(0021)
</td>
<td style="border: 1px solid black;padding-left: 10px;" >
<span style="font-weight: bold;" >
Ian Smith
</span>
 / ian.smith@mylookout.com
</td>
</tr>
<tr>
<td style="border: 1px solid black;padding-left: 10px;" >
2013-08-07
</td>
<td style="border: 1px solid black;padding-left: 10px;" >
(0001)
</td>
<td style="border: 1px solid black;padding-left: 10px;" >
<span style="font-weight: bold;" >
Hiram Chirino
</span>
 / hiram@hiramchirino.com
</td>
</tr>
<tr>
<td style="border: 1px solid black;padding-left: 10px;" >
2013-08-15
</td>
<td style="border: 1px solid black;padding-left: 10px;" >
(0005)
</td>
<td style="border: 1px solid black;padding-left: 10px;" >
<span style="font-weight: bold;" >
Ian Smith
</span>
 / ian.smith@lookout.com
</td>
</tr>
<tr>
<td style="border: 1px solid black;padding-left: 10px;" >
2013-08-22
</td>
<td style="border: 1px solid black;padding-left: 10px;" >
(0007)
</td>
<td style="border: 1px solid black;padding-left: 10px;" >
<span style="font-weight: bold;" >
Ian Smith
</span>
 / ismith@mit.edu
</td>
</tr>
<tr>
<td style="border: 1px solid black;padding-left: 10px;" >
2013-09-26
</td>
<td style="border: 1px solid black;padding-left: 10px;" >
(0001)
</td>
<td style="border: 1px solid black;padding-left: 10px;" >
<span style="font-weight: bold;" >
Orazio Cotroneo
</span>
 / orazio@we7.com
</td>
</tr>
<tr>
<td style="border: 1px solid black;padding-left: 10px;" >
2013-10-22
</td>
<td style="border: 1px solid black;padding-left: 10px;" >
(0001)
</td>
<td style="border: 1px solid black;padding-left: 10px;" >
<span style="font-weight: bold;" >
OrazioWE7
</span>
 / orazio@we7.com
</td>
</tr>
<tr>
<td style="border: 1px solid black;padding-left: 10px;" >
2014-03-13
</td>
<td style="border: 1px solid black;padding-left: 10px;" >
(0001)
</td>
<td style="border: 1px solid black;padding-left: 10px;" >
<span style="font-weight: bold;" >
Richard Clamp
</span>
 / richardc@unixbeard.net
</td>
</tr>
<tr>
<td style="border: 1px solid black;padding-left: 10px;" >
2014-12-08
</td>
<td style="border: 1px solid black;padding-left: 10px;" >
(0001)
</td>
<td style="border: 1px solid black;padding-left: 10px;" >
<span style="font-weight: bold;" >
m4rCsi
</span>
 / m4rCsi@gmail.com
</td>
</tr>
<tr>
<td style="border: 1px solid black;padding-left: 10px;" >
2015-09-05
</td>
<td style="border: 1px solid black;padding-left: 10px;" >
(0001)
</td>
<td style="border: 1px solid black;padding-left: 10px;" >
<span style="font-weight: bold;" >
Michael Klishin
</span>
 / michael@novemberain.com
</td>
</tr>
<tr>
<td style="border: 1px solid black;padding-left: 10px;" >
2015-11-10
</td>
<td style="border: 1px solid black;padding-left: 10px;" >
(0002)
</td>
<td style="border: 1px solid black;padding-left: 10px;" >
<span style="font-weight: bold;" >
Patrick Sharp
</span>
 / psharp@numerex.com
</td>
</tr>
<tr>
<td style="border: 1px solid black;padding-left: 10px;" >
2016-02-03
</td>
<td style="border: 1px solid black;padding-left: 10px;" >
(0001)
</td>
<td style="border: 1px solid black;padding-left: 10px;" >
<span style="font-weight: bold;" >
Wayne Robinson
</span>
 / wayne.robinson@gmail.com
</td>
</tr>
<tr>
<td style="border: 1px solid black;padding-left: 10px;" >
2016-07-12
</td>
<td style="border: 1px solid black;padding-left: 10px;" >
(0006)
</td>
<td style="border: 1px solid black;padding-left: 10px;" >
<span style="font-weight: bold;" >
Nikolay Khasanov
</span>
 / nkhasanov@groupon.com
</td>
</tr>
<tr>
<td style="border: 1px solid black;padding-left: 10px;" >
2016-07-16
</td>
<td style="border: 1px solid black;padding-left: 10px;" >
(0006)
</td>
<td style="border: 1px solid black;padding-left: 10px;" >
<span style="font-weight: bold;" >
GitHub
</span>
 / noreply@github.com
</td>
</tr>
<tr>
<td style="border: 1px solid black;padding-left: 10px;" >
2016-06-02
</td>
<td style="border: 1px solid black;padding-left: 10px;" >
(0001)
</td>
<td style="border: 1px solid black;padding-left: 10px;" >
<span style="font-weight: bold;" >
Ryan Rosenblum
</span>
 / ryan.rosenblum@gmail.com
</td>
</tr>
<tr>
<td style="border: 1px solid black;padding-left: 10px;" >
2016-08-17
</td>
<td style="border: 1px solid black;padding-left: 10px;" >
(0002)
</td>
<td style="border: 1px solid black;padding-left: 10px;" >
<span style="font-weight: bold;" >
Alexandre Moutot
</span>
 / a.moutot@alphalink.fr
</td>
</tr>
<tr>
<td style="border: 1px solid black;padding-left: 10px;" >
2016-10-25
</td>
<td style="border: 1px solid black;padding-left: 10px;" >
(0001)
</td>
<td style="border: 1px solid black;padding-left: 10px;" >
<span style="font-weight: bold;" >
Raducu Deaconu
</span>
 / raducu.deaconu@visma.com
</td>
</tr>
<tr>
<td style="border: 1px solid black;padding-left: 10px;" >
2017-03-23
</td>
<td style="border: 1px solid black;padding-left: 10px;" >
(0001)
</td>
<td style="border: 1px solid black;padding-left: 10px;" >
<span style="font-weight: bold;" >
Steve Traylen
</span>
 / steve.traylen@cern.ch
</td>
</tr>
<tr>
<td style="border: 1px solid black;padding-left: 10px;" >
2017-06-01
</td>
<td style="border: 1px solid black;padding-left: 10px;" >
(0001)
</td>
<td style="border: 1px solid black;padding-left: 10px;" >
<span style="font-weight: bold;" >
Michael Smith
</span>
 / michael.smith@puppet.com
</td>
</tr>
</table>
