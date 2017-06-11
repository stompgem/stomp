# Stomp Gem Change Log

## 1.4.4 20170611

* Merge fix for issue 141.
* Fix broken MatReconnectAttempts
* Attempt to detect mismatched SSL port and params.
* Issue 139, add ssl checks to receive timeout logic.
* Eliminate assert_nothing_raised from tests.
* Add Artemis suport to standard test bed.
* Run JRuby tests more easily.

## 1.4.3 20160821

* Quick fix of install failures.  Do not try to use install 1.4.2.

## 1.4.2 20160820

* Refine SSL examples.
* Address issue #124 with additional RDOC.
* spec for Stomp::Client - check that headers passed to connection contain 
  required values as well as given custom and that given hash is not modified.
* Stomp::Client now does not modify given headers hash
* spec description enhancement.
* fix build_subscription_id - symbol and string were mixed up.
* STOMP_TESTSSL flag should enable all SSL tests.
* Add a basic Gemfile.
* Fix a memory leak in receipt implementation.
* Add unit test helper script.

## 1.4.1 20160623

* Add call to #post_connection_check to normal SSL processing.  This change
  further validates the name of the broker connected to.  This change adds to
  the current SSL connection processing logic, and is **highly recommended**.  In the
  case a client cannot tolerate this logic, it can be disabled by adding
  :ssl_post_conn_check => false to the connection hash.
* Fix typo in SSL failure recovery processing.

## 1.4.0 20160608

* Connection parameter :parse_timeout now means IO:select wait time for socket
    reads.  Consumer clients should see a significantly reduced memory
    footprint.  If the default (5 seconds) is not used by your client,
    we suggest you test carefully.
* Add example programs for sending / receiving large messages.
* Changelog format is changed from .rdoc to .md.
* README format is changed from .rdoc to .md.
* README format change of contributor's list.
* Add example utilities for generating the contributor's list.
* Eliminate many warnings when using 'rake test', mostly from the 2.x Ruby series.
* Get rakefile up to date.
* Add the 'adhoc' subdirectory, an area for experiments and issue recreation code.

## 1.3.5 20160302

* Add AMQ specific durable topic example.
* Output error to stderr only in logger is undefined.
* Move README changelog lower.
* Handle newline at start of receive buffer.
* Use Timeout::timeout instead of deprecated kernel version.
* If socket open on reconnect, close it before new open.
* On misc_err, make error messages more readable.
* Attempt to support both Rspec 2.14.1+ and 3.x.

## 1.3.4 20141202

* Change :start_timeout default to 0 (might break some clients) (#98).
* Allow user set of SSLContext options (#105).
* Allow user set of parm in SSLContext.new(parm) (#105).

## 1.3.3 20140810

* Do not attempt to write empty message bodies.
* Explicity close ssl socket on connection timeout.
* Fix incorrect behavior for empty header keys (#93)
* Do not override explicit :reliable => false.
* Fix client fail-over fails (#98)

## 1.3.2 20131208

* Anon tests assigned unique class name.
* Fix TypeError on connect timeout with 1.8.x, 2.x.
* Complete revert to previous logger logic.
* start_timeout and tcp_nodelay parameters
* SSL Fix, revert not setting default ciphers.
* Copy hash params at init.
* Fix ssl => true for Ruby 1.9.x and 2.x.
* Expanded list of STOMP default SSL ciphers:
* Do not change caller's :hosts array
* Issue #78, again.
* Clean up logger interfacing.
* Fixes from RSpec testing

## 1.3.1 20131002

* Method calls to the logger object should check for that method first (#83)

## 1.3.0 20130930

* ERROR frames now raise an exception in the Stomp::Client thread(#73, #81)
* Allow anonymous connections (#75)
* Fix for subscription id handling in STOMP 1.1 (#78)
* Added a NullLogger (#77)
* Added :tcp_nodelay option (disable Nagle's algorithm) (#76)
* Read receipt ids are now UUIDs
* Added a :start_timeout parameter

## 1.2.16 20130812

* Stomp::Client's should expose connection's host params

## 1.2.15 20130809

* Add user-specified timeout for initial CONNECTED/ERROR frame read.
* Eliminate dup Timeout::timeout in ssl connect
* Add license information to gemspec (#69)

## 1.2.14 20130819

* Version bump (1.2.13 release had Stomp::Version of 1.1.12.)
* Prevent dup subscription header on re-receive

## 1.2.13 20130817

* Issue #68, Stomp::Client#unreceive max_redeliveries off-by-one error

## 1.2.12 20130811

* Fix infinite loop when max reconn attempts is reached
* Enhance JRuby support in tests
* Issue #63, nil message on rapid AMQ restarts
* Issue #63, fast spurious failovers with JRuby and AMQ
* Issue #67, SSL SNI support (thanks Hiram)
* Proper cleanup when not reliable adn EOF from broker
* Remove extraneous privte declarations
* Issue #65, allow non-word characters in login and passcode using stomp://
* Issue #66, allow a single broker in a failover URL

## 1.2.11 20130728

* Issue #60, timeout/hang under JRuby
* More generally support JRuby use and testing
* Issue #58, nil message in Client on AMQ shutdown
* More robust RabbitMQ tests

## 1.2.10 20130708

* Issue #57, reconnect delays not honored if erroneous headers
* Support fail overs when heartbeat send/receive fails
* Update callback logger example

## 1.2.9 20130328

* Refactoring and documentation updates (glennr)
* Fix test encoding for Ruby 2.0+
* Fixes to tests due to :suppress_content_length fix
* Issue #50 Stomp::Client reconnects fail
* Correctly honor :suppress_content_length with 1.1 (JP Hastings-Spital)
* Fix reference to client.publish rather than client.send (JP Hastings-Spital)

## 1.2.8 20121228

* Fix inverted encode / decode logic (fairly major 1.1+ bug)
* Enhance codec tests
* Enhance Stomp 1.1+ tests

## 1.2.7 20121102

* Stomp 1.2 support (see http://stomp.github.com)
* Reset reconnect_delay to default value upon successful reconnect
* Enhance tests for Stomp 1.2

## 1.2.6 20120913

* Provide ability to eliminate checks for closed in protocol methods
* Cover ssl.connect with connection timeout parameter
* If heartbeat send raises, do not reraise unless client requests that
* Remove methods that invoke __send__
* Move internal methods to 'private'

## 1.2.5 20120804

* Issue #48 any forks with modifications will be affected!
* Source code restructured into individual files
* Common indentation used throughout the source
* Many method comments have been added
* See notes in source regarding making methods private in the next release
* See notes in source regarding removal of methods in the next release
* Include examples and tests in rdoc generated during install
* Issue #47 socket is open during retries

## 1.2.4 20120625

* Add ability for client to request flush on write to the connection (Issue #45)
* Add ability for client to retrieve heartbeat intervals and counters
* Fix I/O errors with heartbeats and multithreaded clients (Issue #46)
* Enhance tests for heartbeats
* Correct typos and clarify comments in many examples

## 1.2.3 20120616

* Fix UnsupportedProtocol on connect to a 1.0 broker
* Add Client#poll method
* Add help to stompcat and catstomp
* Allow password to be set for private SSL key
* Update comments to reflect new repository URL
* Reformat changelog dates to ISO8601
* Fix SSL connection failures using JRuby
* Use symbols, not strings for all header keys
* Add IPV6 to IPV4 failover for dual homed systems when requested

## 1.2.2 20120324

* Major performance improvement for read of messages without content-length header
* Correct Stomp 1.1 failing test
* Update sample code to reflect removal of 'send'
* Add on_ssl_connectfail callback and allow clients to signal quit from the callback
* Ensure that SSL certificates and SSL related files exist and are readable
* Allow SSL file checks before connect using SSLParams.new(:fsck => true, ...)
* Correct a test for Windows compatibility

## 1.2.1 20120313

* Robust SSL certificate support.  See examples and: https://github.com/stompgem/stomp/wiki/extended-ssl-overview
* Really remove the deprecated #send methods
* Fix exception in Stomp 1.1 code when headers are frozen
* Revert 245e734a0. See ce8335fb2f for details. Fixes broken Connection#poll.
* Add reconnection attempts to callback logging.
* Add SSL specific connection information to callback logging.

## 1.2.0 20111214

* Stomp 1.1 protocol support.  A significant change.  Please test existing 1.0 code well.  See the examples directory for 1.1 examples.
* Accept :reliable in a Stomp::Client connection hash
* Add connect timeout with hashed parameters
* Do not allow calls after close/disconnect
* Enhance supported logger callbacks
* Fix subscription id in find_listener
* Start to bootstrap STOMP 1.1 support

## 1.1.10 20111107

* Fixes for JRuby support
* Fix EOF error on disconnect
* Refactoring and additional test
* Set up tests for use of RabbitMQ

## 1.1.9 20110615

* Support wildcard destinations
* Handle subscribe with string or symbol ID
* Check for duplicate subscriptions in spec tests
* Support AMQ and Apollo servers in uinit tests
* Correct UTF-8 (Unicode) content-length calcualtion in Ruby 1.9
* Send of a nil body causes exception
* Add optional callback logging.  See the examples install directory, files logexamp.rb and slogger.rb
* Correct date stamps in this file

## 1.1.8 20110316

* Set KEEPALIVE on connection socket options
* Attempt to support JRuby more robustly (poll remains broken)
* Switch to ruby supplied IO#ready?
* Test enhancements for suppress_content_length header
* Miscellaneous small documentation updates
* Add parse_timeout parameter for use with hashed logins 
* Allow connection to hosts with a - (dash) in the host name
* Add limit parameter to thread joins

## 1.1.7 20110109

* Binary parse of raw STOMP frame
* Fix broken tests on Ruby 1.9.2

## 1.1.6 20100610

* Fixed multi-thread app hanging

## 1.1.5 20100317

* Added publish method (send is now deprecated)
* Changes on Rake File
* Added original_destination header to unreceive
* suppress content length header is send on the message for future handling (like unreceive)

## 1.1.4 20100121

* Added unreceive message method that sends the message back to its queue or to the 
  dead letter queue, depending on the :max_redeliveries option, similar to a13m one.
* Added environment variable option for running 'rake test' on any stomp server, using any port with any user.
* Added suppress_content_length header option for ActiveMQ knowing it is a text message (see: 
  http://juretta.com/log/2009/05/24/activemq-jms-stomp/)
* Fixed some bugs with Ruby 1.9 (concatenate string + exception)
* Major changes on message parsing feature
* Fixed bug with old socket not being closed when using failover
* Fixed broken poll method on Connection
* Fixed broken close method on Client
* Added connection_frame accessor
* Added disconnect receipt

## 1.1.3 20091124

* Failover support
* SSL support
* Stomp::Connection and Stomp::Client accept a hash on their constructor

## 1.1 20090227

* Ruby 1.9 Support
* Add support for connect_headers, to control the CONNECT command.
* Refactored lib dir to separate concerns.
* Better test coverage
* General code cleanup. 

## 1.0.6 20080805

* Whitespace cleanup
* Refactored Rakefile and added stomp.gemspec for GitHub friendliness.
* Added .gitignore file
* Refactored layout of lib dir to separate concerns
* Cleanup of initializers, and provide Client accessors for reading values (for testing)
* Removed test/test_url_* files as they only differed from the test_client.rb in their
  setup.  Super UnDry.  Added URL tests to cover stomp URL as param.
* Created initial RSpec specs which stub/mock objects and should not require a running
  Stomp server instance.

## v1.0.5 20070201

* better url parsing
* git-svn-id: http://svn.codehaus.org/stomp/ruby/trunk@48 fd4e7336-3dff-0310-b68a-b6615a75f13b

## v1.0.4 20070115

* Allow URL style connections descriptors
* git-svn-id: http://svn.codehaus.org/stomp/ruby/trunk@44 fd4e7336-3dff-0310-b68a-b6615a75f13b

## v1.0.3 20070114

* Additional fixes for reliable by Andrew Kuklewicz
* git-svn-id: http://svn.codehaus.org/stomp/ruby/trunk@42 fd4e7336-3dff-0310-b68a-b6615a75f13b

## v1.0.2 20060922

* Moving ruby so we can tag it ;-)
* git-svn-id: http://svn.codehaus.org/stomp/ruby/trunk@37 fd4e7336-3dff-0310-b68a-b6615a75f13b

## v1.0.1 20051217

* Increment version
* git-svn-id: http://svn.codehaus.org/stomp/trunk/ruby@24 fd4e7336-3dff-0310-b68a-b6615a75f13b

## v1.0.0 20051015

* works in repl, getting messages in weird order or dupes in test, but unable to isolate so far #(
* git-svn-id: http://svn.codehaus.org/stomp/trunk/ruby@20 fd4e7336-3dff-0310-b68a-b6615a75f13b

