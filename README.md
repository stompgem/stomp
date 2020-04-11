# README

* [Project Information](https://github.com/stompgem/stomp)

## Overview

An implementation of the Stomp protocol for Ruby. See:

* [STOMP 1.0](http://stomp.github.io/stomp-specification-1.0.html)
* [STOMP 1.1](http://stomp.github.io/stomp-specification-1.1.html)
* [STOMP 1.2](http://stomp.github.io/stomp-specification-1.2.html)

## Hash Login Example Usage (**this is the recommended login technique**):

```ruby
hash = {
  hosts: [
    # First connect is to remotehost1
    { login: 'login1', passcode: 'passcode1', host: 'remotehost1', port: 61_612, ssl: true },
    # First failover connect is to remotehost2
    { login: 'login2', passcode: 'passcode2', host: 'remotehost2', port: 61_613, ssl: false }
  ],
  # These are the default parameters and do not need to be set
  reliable: true,                  # reliable (use failover)
  initial_reconnect_delay: 0.01,   # initial delay before reconnect (secs)
  max_reconnect_delay: 30.0,       # max delay before reconnect
  use_exponential_back_off: true,  # increase delay between reconnect attpempts
  back_off_multiplier: 2,          # next delay multiplier
  max_reconnect_attempts: 0,       # retry forever, use # for maximum attempts
  randomize: false,                # do not radomize hosts hash before reconnect
  connect_timeout: 0,              # Timeout for TCP/TLS connects, use # for max seconds
  connect_headers: {},             # user supplied CONNECT headers (req'd for Stomp 1.1+)
  parse_timeout: 5,                # IO::select wait time on socket reads
  logger: nil,                     # user suplied callback logger instance
  dmh: false,                      # do not support multihomed IPV4 / IPV6 hosts during failover
  closed_check: true,              # check first if closed in each protocol method
  hbser: false,                    # raise on heartbeat send exception
  stompconn: false,                # Use STOMP instead of CONNECT
  usecrlf: false,                  # Use CRLF command and header line ends (1.2+)
  max_hbread_fails: 0,             # Max HB read fails before retry.  0 => never retry
  max_hbrlck_fails: 0,             # Max HB read lock obtain fails before retry.  0 => never retry
  fast_hbs_adjust: 0.0,            # Fast heartbeat senders sleep adjustment, seconds, needed ...
  # For fast heartbeat senders.  'fast' == YMMV.  If not
  # correct for your environment, expect unnecessary fail overs
  connread_timeout: 0,             # Timeout during CONNECT for read of CONNECTED/ERROR, secs
  tcp_nodelay: true,               # Turns on the TCP_NODELAY socket option; disables Nagle's algorithm
  start_timeout: 0,                # Timeout around Stomp::Client initialization
  sslctx_newparm: nil,             # Param for SSLContext.new
  ssl_post_conn_check: true,       # Further verify broker identity
  nto_cmd_read: true,              # No timeout on COMMAND read
}

# for a client
client = Stomp::Client.new(hash)

# for a connection
connection = Stomp::Connection.new(hash)
```

### Positional Parameter Usage:

```ruby
client = Stomp::Client.new("user", "pass", "localhost", 61613)
client.publish("/queue/mine", "hello world!")
client.subscribe("/queue/mine") do |msg|
    p msg
end
```

### Stomp URL Usage:

A Stomp URL must begin with `stomp://` and can be in one of the following forms:

```
stomp://host:port
stomp://host.domain.tld:port
stomp://login:passcode@host:port
stomp://login:passcode@host.domain.tld:port

# e.g. c = Stomp::Client.new(urlstring)
```

### Failover + SSL Example URL Usage:

```ruby
options = 'initialReconnectDelay=5000&randomize=false&useExponentialBackOff=false'
# remotehost1 uses SSL, remotehost2 doesn't
client = Stomp::Client.new("failover:(stomp+ssl://login1:passcode1@remotehost1:61612,stomp://login2:passcode2@remotehost2:61613)?#{options}")
client.publish('/queue/mine', 'hello world!')
client.subscribe('/queue/mine') do |msg|
  p msg
end
```

### New:

See _CHANGELOG.rdoc_ for details.

* Gem version 1.4.9. Fix two issues, enhance debugging and examples.
* Gem version 1.4.8. Fix missed merge in 1.4.7 release.
* Gem version 1.4.7. Add support for text SSL certs.  Do not use, use 1.4.8 instead.
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

#### Contributors

See CONTRIBUTORS.md.

