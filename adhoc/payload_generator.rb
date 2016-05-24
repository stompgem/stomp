# -*- encoding: utf-8 -*-

class PayloadGenerator

  private

  @@BSTRING = ""

  public

  def self.initialize(min = 1, max = 4096)
    srand()
    #
    @@min, @@max = min, max
    if @@min > @@max
      @@min, @@max = @@max, @@min
      warn "Swapping min and max values"
    end
    #
    @@BSTRING = "9" * @@max
    nil
  end # of initialize

  def self.payload
    i = rand(@@max - @@min)
    i = 1 if i == 0
    i += @@min 
    # puts "DBI: #{i}"
    @@BSTRING.byteslice(0, i)
  end

end # of class
