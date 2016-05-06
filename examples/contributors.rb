#!/usr/bin/env ruby
#
class UserData

  public
  attr_accessor :count
  attr_reader   :time
  #
  def initialize(time = nil)
    @count, @time = 1, time
  end
  #  
  def to_s
    "UserData: time=>#{@time}, count =>#{@count}"
  end
end
# Row Data
trow_s = "<tr>\n"
trow_e = "<tr>\n"
# Header Data
th_s = "<th style=\"border: 1px solid black;padding-left: 10px;\" >\n"
th_c1 = "First Author Date"
th_c2 = "(Commit Count)"
th_c3 = "Name / E-mail"
th_e = "</th>\n"
# User Data (partial)
td_s = "<td style=\"border: 1px solid black;padding-left: 10px;\" >\n"
td_e = "</td>\n"
#
userList = {}
while s = gets do
  s.chomp!
  t, n, e = s.split(";")
  hk = "#{n}|#{e}"
  if userList.has_key?(hk)
    userList[hk].count += 1
  else
    userList[hk] = UserData.new(t)
  end

end
#
puts trow_s
#
puts th_s
puts th_c1
puts th_e
#
puts th_s
puts th_c2
puts th_e
#
puts th_s
puts th_c3
puts th_e
#
puts trow_e
#
userList.each do |k, v|
  n, e = k.split("|")
  oc = "(" + sprintf("%04d", v.count) + ")"
  # puts "# #{v.time} (#{oc}) #{n} #{e}"
  puts trow_s
  #
  puts td_s
  puts "#{v.time}"
  puts td_e
  #
  puts td_s
  puts oc
  puts td_e
  #
  puts td_s
  puts "<span style=\"font-weight: bold;\" >\n"
  puts "#{n}\n"
  puts "</span>\n"
  puts " / #{e}"
  puts td_e
  #  
  puts trow_e  
end
