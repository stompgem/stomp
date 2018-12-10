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
        :nto_cmd_read => true,              # No timeout on COMMAND read
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

* Gem version 1.4.6. Fix version 1.4.5 which breaks JRuby support.
* Gem version 1.4.5. JRuby broken here.  Use is not recommended.
* Gem version 1.4.4. Miscellaneous fixes, see CHANGELOG.md for details.
* Gem version 1.4.3. Fix broken install.  Do not try to install 1.4.2.
* Gem version 1.4.2. Fix memory leak, and others !: see CHANGELOG.md for details.
* Gem version 1.4.1. Important SSL changes !: see CHANGELOG.md for details.
* Gem version 1.4.0. Note: Change sementics of :parse_timeout, see CHANGELOG.md for details.
* Gem version 1.3.5. Miscellaneous fixes, see CHANGELOG.md for details.

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
 / &lt;brianm@fd4e7336-3dff-0310-b68a-b6615a75f13b&gt;
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
 / &lt;jstrachan@fd4e7336-3dff-0310-b68a-b6615a75f13b&gt;
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
 / &lt;chirino@fd4e7336-3dff-0310-b68a-b6615a75f13b&gt;
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
 / &lt;kookster@fd4e7336-3dff-0310-b68a-b6615a75f13b&gt;
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
 / &lt;glenn@rempe.us&gt;
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
 / &lt;tonyg@lshift.net&gt;
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
 / &lt;marius.mathiesen@gmail.com&gt;
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
 / &lt;johan@johansorensen.com&gt;
</td>
</tr>
<tr>
<td style="border: 1px solid black;padding-left: 10px;" >
2009-11-17
</td>
<td style="border: 1px solid black;padding-left: 10px;" >
(0019)
</td>
<td style="border: 1px solid black;padding-left: 10px;" >
<span style="font-weight: bold;" >
Thiago Morello
</span>
 / &lt;thiago.morello@locaweb.com.br&gt;
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
 / &lt;katy@.(none)&gt;
</td>
</tr>
<tr>
<td style="border: 1px solid black;padding-left: 10px;" >
2009-12-18
</td>
<td style="border: 1px solid black;padding-left: 10px;" >
(0047)
</td>
<td style="border: 1px solid black;padding-left: 10px;" >
<span style="font-weight: bold;" >
Thiago Morello
</span>
 / &lt;morello@queroinfra32.fabrica.locaweb.com.br&gt;
</td>
</tr>
<tr>
<td style="border: 1px solid black;padding-left: 10px;" >
2009-12-25
</td>
<td style="border: 1px solid black;padding-left: 10px;" >
(0362)
</td>
<td style="border: 1px solid black;padding-left: 10px;" >
<span style="font-weight: bold;" >
gmallard
</span>
 / &lt;allard.guy.m@gmail.com&gt;
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
 / &lt;rafael.rosa@locaweb.com.br&gt;
</td>
</tr>
<tr>
<td style="border: 1px solid black;padding-left: 10px;" >
2010-03-23
</td>
<td style="border: 1px solid black;padding-left: 10px;" >
(0092)
</td>
<td style="border: 1px solid black;padding-left: 10px;" >
<span style="font-weight: bold;" >
Guy M. Allard
</span>
 / &lt;allard.guy.m@gmail.com&gt;
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
 / &lt;kpumuk@kpumuk.info&gt;
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
 / &lt;neil@aldur.co.uk&gt;
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
 / &lt;dinesh.majrekar@advantage-interactive.com&gt;
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
 / &lt;kiall@managedit.ie&gt;
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
 / &lt;rob@pivotal-it.com&gt;
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
 / &lt;tom@tommay.net&gt;
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
 / &lt;info@lucashills.com&gt;
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
 / &lt;chrisn303@gmail.com&gt;
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
 / &lt;rip@devco.net&gt;
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
 / &lt;tworker@onyx.ove.com&gt;
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
Thiago Morello
</span>
 / &lt;morellon@gmail.com&gt;
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
 / &lt;james@fearmediocrity.co.uk&gt;
</td>
</tr>
<tr>
<td style="border: 1px solid black;padding-left: 10px;" >
2012-05-02
</td>
<td style="border: 1px solid black;padding-left: 10px;" >
(0003)
</td>
<td style="border: 1px solid black;padding-left: 10px;" >
<span style="font-weight: bold;" >
mindscratch
</span>
 / &lt;craig@mindscratch.org&gt;
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
 / &lt;bishop.thomas@gmail.com&gt;
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
 / &lt;jeremy@infinitecube.com&gt;
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
 / &lt;jphastings@gmail.com&gt;
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
 / &lt;glenn@siyelo.com&gt;
</td>
</tr>
<tr>
<td style="border: 1px solid black;padding-left: 10px;" >
2013-07-29
</td>
<td style="border: 1px solid black;padding-left: 10px;" >
(0020)
</td>
<td style="border: 1px solid black;padding-left: 10px;" >
<span style="font-weight: bold;" >
Ian Smith
</span>
 / &lt;ian.smith@mylookout.com&gt;
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
 / &lt;hiram@hiramchirino.com&gt;
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
 / &lt;ian.smith@lookout.com&gt;
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
 / &lt;orazio@we7.com&gt;
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
 / &lt;orazio@we7.com&gt;
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
 / &lt;richardc@unixbeard.net&gt;
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
 / &lt;m4rCsi@gmail.com&gt;
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
 / &lt;michael@novemberain.com&gt;
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
 / &lt;psharp@numerex.com&gt;
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
 / &lt;wayne.robinson@gmail.com&gt;
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
 / &lt;nkhasanov@groupon.com&gt;
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
 / &lt;ryan.rosenblum@gmail.com&gt;
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
 / &lt;a.moutot@alphalink.fr&gt;
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
 / &lt;raducu.deaconu@visma.com&gt;
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
 / &lt;steve.traylen@cern.ch&gt;
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
Reid Vandewiele
</span>
 / &lt;reid@puppetlabs.com&gt;
</td>
</tr>
<tr>
<td style="border: 1px solid black;padding-left: 10px;" >
2017-07-27
</td>
<td style="border: 1px solid black;padding-left: 10px;" >
(0001)
</td>
<td style="border: 1px solid black;padding-left: 10px;" >
<span style="font-weight: bold;" >
Meg Richards
</span>
 / &lt;mouse@cmu.edu&gt;
</td>
</tr>
<tr>
<td style="border: 1px solid black;padding-left: 10px;" >
2018-11-19
</td>
<td style="border: 1px solid black;padding-left: 10px;" >
(0003)
</td>
<td style="border: 1px solid black;padding-left: 10px;" >
<span style="font-weight: bold;" >
Katharine
</span>
 / &lt;krsibbald@gmail.com&gt;
</td>
</tr>
</table>
