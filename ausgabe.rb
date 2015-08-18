class Ausgabe
  def initialize einst
    @format = einst.format
    @d_format = einst.datei_format
  end
  
  def aus hb, dateien
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
    if !dateien.nil?
      puts "Dateien:"
      dateien.each {|e|
        #laenge in stunden, minuten und sekunden berechnen
        la = ""
        l = e.laenge.to_i
        l = 0 if e.laenge.nil?
        if l > 3600
          h = l / 3600
          la << h.to_s
          la << "h "
        end
        if l > 60
          h = 0 if h.nil?
          m = (l - (h*3600)) / 60
          la << m.to_s
          la << "m "
        end
        h = 0 if h.nil?
        m = 0 if m.nil?
        s = (l - (h*3600) - (m*60))
        la << s.to_s
        la << "s"
        
        d_out = @d_format.gsub "%n", "\n"
        d_out.gsub! "%tb", "\t"
        d_out.gsub! "%p", e.pfad
        d_out.gsub! "%t", e.titel
        d_out.gsub! "%a", e.album
        d_out.gsub! "%i", e.interpret
        d_out.gsub! "%g", e.genre
        d_out.gsub! "%no", e.nummer
        d_out.gsub! "%j", e.jahr
        d_out.gsub! "%l", la
        d_out.gsub! "%s", e.groesse
        puts
        puts d_out
      } 
    end
    
  end
end