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
  
  def to_h
    res = Hash.new
    res[:format] = @format
    cds_tmp = Array.new
    @cds.each {|cd|
      cds_tmp << cd.to_h
    }
    res[:cds] = cds_tmp
    return res
  end
end