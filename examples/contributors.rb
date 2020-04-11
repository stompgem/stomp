#!/usr/bin/env ruby
#
class UserData

  public
  attr_accessor :count
  attr_reader   :ad
  #
  def initialize(ad = nil)
    @count, @ad = 1, ad
  end
  #  
  def to_s
    "UserData: AuthorDate=>#{@ad}, AuthorDate=>#{@ad}, CommitCount =>#{@count}"
  end
end
#
def partOne()
  puts "# Contributors"
  puts
  puts "## Contributors (by first author date)"
  puts
  puts
  puts "Contribution Information:"
  puts
  puts
end
#
# tABLE Data
ttab_s = "<table border=\"1\" style=\"width:100%;border: 1px solid black;\">\n"
ttab_e = "</table>\n"
# Row Data
trow_s = "<tr>\n"
trow_e = "</tr>\n"
# Header Data
th_s = "<th style=\"border: 1px solid black;padding-left: 10px;\" >\n"
th_c1 = "First Author Date"
th_c1b = "First Commit Date"
th_c2 = "(Commit Count)"
th_c3 = "Name / E-mail"
th_e = "</th>\n"
# User Data (partial)
td_s = "<td style=\"border: 1px solid black;padding-left: 10px;\" >\n"
td_e = "</td>\n"
#
#
partOne()
userList = {}
while s = gets do
  s.chomp!
  ##puts
  ##puts 
  sa = s.split(" ")
  ## puts sa
  ad = sa[-1]
  ##puts ad
  e = sa[-2]
  ##puts e
  na = sa[0..-3]
  n = na.join(" ")
  ##puts n
  #
  hk = "#{n}|#{e}"
  ##puts hk
  if userList.has_key?(hk)
    userList[hk].count += 1
    ##puts "BUMP"
  else
    userList[hk] = UserData.new(ad)
    ##puts "ADD"
 end

end
puts ttab_s # table start
puts trow_s
#
puts th_s
puts th_c1
puts th_e
#
=begin
puts th_s
puts th_c1b
puts th_e
=end
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
  ##puts "K: #{k}"
  n, e = k.split("|")
  ##puts "N: #{n}"
  e = "&lt;" + e[1..-2] + "&gt;"
  ##puts "E: #{e}"
  oc = "(" + sprintf("%04d", v.count) + ")"
  # puts "# #{v.time} (#{oc}) #{n} #{e}"
  puts trow_s
  #
  puts td_s
  puts "#{v.ad}"
  puts td_e
=begin
  #
  puts td_s
  puts "#{v.cd}"
  puts td_e
=end
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
#
puts ttab_e # table end
