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
  
  def to_s
    return "ID: " + @id.to_s, "Titel: " + @titel.to_s, "Autor: " + @autor.to_s, "Sprecher: " + @sprecher.to_s, "Pfad: " + @pfad.to_s
  end
end