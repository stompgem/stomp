# -*- encoding: utf-8 -*-

require 'rubygems'
require 'stomp'
#
# == Example message publisher
#
class ExamplePublisher
  # Initialize.
  def initialize
  end
  # Run example.
  def run
    client = Stomp::Client.new("failover://(stomp://:@localhost:61613,stomp://:@remotehost:61613)?initialReconnectDelay=5000&randomize=false&useExponentialBackOff=false")
    message = "ronaldo #{ARGV[0]}"

    for i in (1..50)
      puts "Sending message"
      client.publish("/queue/ronaldo", "#{i}: #{message}", {:persistent => true})
      puts "(#{Time.now})Message sent: #{i}"
      sleep 0.2
    end
  end
end
#
e = ExamplePublisher.new
e.run



