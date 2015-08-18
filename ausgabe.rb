class Ausgabe
  def initialize einst
    @format = einst.format
  end
  
  def aus hb 
    out = @format.gsub "%n", "\n"
    out.gsub! "%tb", "\t"
    out.gsub! "%id", hb.id.to_s
    out.gsub! "%t", hb.titel
    autoren = ""
    anz_autoren = hb.autor.length
    hb.autor.each_with_index {|e,i|
      autoren << e
      if i < anz_autoren-1
        autoren << ', '
      end
      }
    out.gsub! "%a", autoren
   
    sprecher = ""
    anz_sprecher = hb.sprecher.length
    hb.sprecher.each_with_index {|e,i|
      sprecher << e
      if i < anz_sprecher-1
        sprecher << ', '
      end
      }
    out.gsub! "%s", sprecher
    out.gsub! "%b", hb.bewertung.to_s
    out.gsub! "%p", hb.pfad
    puts
    puts out
  end
end