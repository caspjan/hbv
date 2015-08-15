class Hoerbuch 
  attr_accessor:titel
  attr_accessor:autor
  attr_accessor:pfad
  attr_accessor:sprecher
  attr_accessor:id
  
  def initialize id, titel, autor, pfad, sprecher
    @id = id
    @titel = titel
    @autor = Array.new
    @autor << autor
    @pfad = pfad
    @sprecher = Array.new
    @sprecher << sprecher
  end
  
  def to_s
    return "ID: " + @id, "Titel: " + @titel.to_s, "Autor: " + @autor.to_s, "Sprecher: " + @sprecher.to_s, "Pfad: " + @pfad.to_s
  end
end