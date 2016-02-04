class Format
  attr_accessor:cds
  attr_accessor:format
  
  def initialize format
    @cds = Array.new
    @format = format
  end
  
  def add_cd cd
    @cds << cd
  end
end