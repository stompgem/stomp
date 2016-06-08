# -*- encoding: utf-8 -*-
if Kernel.respond_to?(:require_relative)
  require_relative("payload_generator")
else
  $LOAD_PATH << File.dirname(__FILE__)
  require "payload_generator"
end
#
cmin, cmax = 1292, 67782
ffmts = "%16.6f"
#
PayloadGenerator::initialize(min= cmin, max= cmax)

to, nmts, nts, umps = 0.0, Time.now.to_f, 100, 5.6
# p [ "nmts", nmts ]
tslt = 1.0 / umps
# p [ "tslt", tslt ]
nts.times do |i|
  ns = PayloadGenerator::payload()
  to += ns.bytesize
  # puts "t: #{i+1}, len: #{ns.bytesize}, tslt: #{tslt}"
  sleep(tslt)
  # puts "Done sleep!"
end
#
te = Time.now.to_f
# p [ "te", te ]
et = te - nmts
avgsz = to / nts
mps = nts.to_f / et
#
fet = sprintf(ffmts, et)
favgsz = sprintf(ffmts, avgsz)
fmps = sprintf(ffmts, mps)
#
puts "=" * 48
puts "\tNumber of payloads generated: #{nts}"
puts "\tMin Length: #{cmin}, Max Length: #{cmax}"
puts "\tAVG_SIZE: #{favgsz}, ELAPS_SEC: #{fet}(seconds)"
puts "\tNMSGS_PER_SEC: #{fmps}"
#
