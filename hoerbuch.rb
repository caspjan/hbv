class Hoerbuch 
  attr_accessor:titel
  attr_accessor:autor
  attr_accessor:pfad
  attr_accessor:sprecher
  attr_accessor:id
  
  def initialize id, titel, autor, sprecher, pfad
    @id = id
    @titel = titel
    @autor = autor
    @pfad = pfad
    @sprecher = sprecher
  end
end