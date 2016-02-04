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
  end
end