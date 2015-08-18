class Hoerbuch 
  attr_accessor:titel
  attr_accessor:autor
  attr_accessor:pfad
  attr_accessor:sprecher
  attr_accessor:id
  attr_accessor:bewertung
  
  def initialize id, titel, autor, sprecher, pfad, bewertung
    @id = id
    @titel = titel
    @autor = autor
    @pfad = pfad
    @sprecher = sprecher
    @bewertung = bewertung
  end
end