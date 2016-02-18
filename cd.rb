class CD
  attr_accessor:nummer
  attr_accessor:hoerbuch_id
  attr_accessor:pfad
  attr_accessor:format
  attr_accessor:id
  attr_accessor:dateien
  
  def initialize id, nummer, hoerbuch_id, pfad, format, dateien
    @id = id
    @nummer = nummer
    @pfad = pfad
    @dateien = dateien
    @hoerbuch_id = hoerbuch_id
    @format = format
  end
  
  def to_h
    res = Hash.new
    res[:id] = @id
    res[:nummer] = @nummer
    res[:pfad] = @pfad
    res[:hoerbuch_id] = @hoerbuch_id
    res[:format] = @format
    dateien_tmp = Array.new
    @dateien.each {|datei|
      dateien_tmp << datei.to_h
    }
    res[:dateien] = dateien_tmp
    return res
  end
end