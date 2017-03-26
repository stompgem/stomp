# -*- encoding: utf-8 -*-

require 'rubygems' if RUBY_VERSION < "1.9"
require 'rspec'
dir = File.dirname(__FILE__)
lib_path = File.expand_path("#{dir}/../lib")
$LOAD_PATH.unshift lib_path unless $LOAD_PATH.include?(lib_path)

puts "RSpec version: #{RSpec::Version::STRING}"
$stdout.flush

require 'stomp'
