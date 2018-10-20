# -*- encoding: utf-8 -*-

#
# The current require dance for different Ruby versions.
# Change this to suit your requirements.
#
if Kernel.respond_to?(:require_relative)
  require_relative("./stomp_common")
else
  $LOAD_PATH << File.dirname(__FILE__)
  require "stomp_common"
end
include Stomp1xCommon
=begin

  A recent experience suggested that we might provide an example of how
  to establish a "durable" topic subscription using ActiveMQ.

  This code attempts to do that.

  References: 

  http://activemq.apache.org/stomp.html

  http://activemq.apache.org/how-does-a-queue-compare-to-a-topic.html

  http://activemq.apache.org/how-do-durable-queues-and-topics-work.html

  Specifically, locate the section titled: ActiveMQ extensions to Stomp.

  There are two programmatic requirements:

  1) On CONNECT, indicate to AMQ the code will be using durable topic 
    subscription(s).
    Done by providing a "cilent-id" CONNECT header.

  2) On SUBSCRIBE, indicate an AMQ specific (unique) subscription ID.  Done
    by providing a "activemq.subscriptionName" header to SUBSCRIBE.

=end

# login hash
hash = { :hosts => [ 
       {:login => login(), :passcode => passcode(), :host => host(), :port => port(),
          :ssl => usessl()}, #
      ],
      :reliable => true,
			:closed_check => false, 
      :connect_headers => {:host => "localhost", :"accept-version" => "1.2",
        # Requirement 1, name should be unique.
        :"client-id" => "dursubcli01",  # REF the 1st AMQ link above
			} 
    }
# The topic
topic = "/topic/topicName"

# Establish the client connection
cli = Stomp::Client.open(hash)
# SUBSCRIBE Headers
sh = { "activemq.subscriptionName" => "subname01" } # REF the 1st AMQ link above
# And the client subscribe
cli.subscribe(topic, sh) do |msg|
  puts "msg: #{msg}"
end
=begin
  At this point open your AMQ admin console (port 8161 usually), and examine 
  the 'subscribers' section.  You should see an instance of this client 
  displayed in the "Active Durable Topic Subscribers" section.
=end
# Wait for a very long time, usually exit via ^C
puts "Open AMQ console and examing the 'subscribers' section"
puts "Wne done, press ^C to exit, and reexamine the 'subscribers' section"
sleep 1000000
=begin
  After you press ^C to exit this program, return to the AMQ console and
  refresh the display.  (Do not restart AMQ).  You should see this client in the
  "Offline Durable Topic Subscribers" section.
=end
