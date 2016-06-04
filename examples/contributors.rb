#!/usr/bin/env ruby
#
class UserData

  public
  attr_accessor :count
  attr_reader   :ad, :cd
  #
  def initialize(ad = nil, cd = nil)
    @count, @ad, @cd = 1, ad, cd
  end
  #  
  def to_s
    "UserData: AuthorDate=>#{@ad}, CommitDate=>#{@cd}, CommitCount =>#{@count}"
  end
end
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
puts ttab_s # table start
#
userList = {}
while s = gets do
  s.chomp!
  ad, cd, n, e = s.split(";")
  hk = "#{n}|#{e}"
  if userList.has_key?(hk)
    userList[hk].count += 1
  else
    userList[hk] = UserData.new(ad, cd)
=begin
    if ad != cd
      puts "NE: #{ad}, #{cd}, #{n}, #{e}"
    end
=end
  end

end
#
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
  n, e = k.split("|")
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
