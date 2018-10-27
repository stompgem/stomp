# -*- encoding: utf-8 -*-

require 'rubygems'
require 'stomp'
#
# == Example message consumer.
#
class ExampleConsumer
  # Initialize.
  def initialize
  end
  # Run example.
  def run
  client = Stomp::Client.new("failover://(stomp://:@localhost:61613,stomp://:@remotehost:61613)?initialReconnectDelay=5000&randomize=false&useExponentialBackOff=false")
  puts "Subscribing ronaldo"
  client.subscribe("/queue/ronaldo", {:ack => "client", "activemq.prefetchSize" => 1, "activemq.exclusive" => true }) do |msg|
    File.open("file", "a") do |f|
      f.write(msg.body)
      f.write("\n----------------\n")
    end

    client.acknowledge(msg)
  end

  loop do
    sleep(1)
    puts "."
  end
  end
end
#
e = ExampleConsumer.new
e.run

