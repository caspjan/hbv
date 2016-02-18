class Hoerbuch 
  attr_accessor:titel
  attr_accessor:autor
  attr_accessor:pfad
  attr_accessor:sprecher
  attr_accessor:id
  attr_accessor:bewertung
  attr_accessor:formate
  attr_accessor:tags
  attr_accessor:laenge
  attr_accessor:groesse
  
  def initialize id, titel, autor, sprecher, pfad, bewertung, tags
    @id = id
    @titel = titel
    @autor = autor
    @pfad = pfad
    @sprecher = sprecher
    @bewertung = bewertung
    @tags = tags
  end
  
  def to_h
    res = Hash.new
    res[:id] = @id
    res[:titel] = @titel
    res[:autor] = @autor
    res[:pfad] = @pfad
    res[:sprecher] = @sprecher
    res[:bewertung] = @bewertung
    res[:tags] = @tags
    res[:laenge] = @laenge if !@laenge.nil?
    res[:groesse] = @groesse if !@groesse.nil?
    if !formate.nil?
      formate_tmp = Array.new
      @formate.each {|f|
        formate_tmp << f.to_h
      }
      res[:formate] = formate_tmp
    end
    return res
  end
end