class Datei
  attr_accessor:nummer
  attr_accessor:pfad
  attr_accessor:laenge
  attr_accessor:groesse
  
  def initialize nummer, pfad, laenge, groesse
    @nummer = nummer
    @pfad = pfad
    @laenge = laenge
    @groesse = groesse
  end
end