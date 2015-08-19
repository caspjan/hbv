class Ausgabe
  def initialize einst
    @format = einst.format
    @d_format = einst.datei_format
    @d_gr = einst.datei_groesse
  end
  
  def calc_size size
    #size in Float ändern
    size = size.to_f
    ret = ""
    #Die Größe auf das Fromat bringen, das im Configfile angegeben wurde
    #wenn c angegeben ist, das sinnvollste bestimmen
    if @d_gr.eql? "c"
      #wenn die fertige groesse in KB größer als 1000 und in MB kleiner als 1000, dann nimm MB
      if (size / (2**10).to_f) < 1000
        d_gr = "KiB"
      elsif (size / (2**20).to_f) < 1000
        d_gr = "MiB"
      elsif (size / (2**20).to_f) > 1000
        d_gr = "GiB"
      end
    end
    
    if d_gr.eql? "KB"
      ret = (size / (10**3).to_f).round(2).to_s << " " + d_gr
    elsif d_gr.eql? "MB"
      ret = (size / (10**6).to_f).round(2).to_s << " " + d_gr
    elsif d_gr.eql? "GB"
      ret = (size / (10**9).to_f).round(2).to_s << " " + d_gr
    elsif d_gr.eql? "KiB"
      ret = (size / (2**10).to_f).round(2).to_s << " " + d_gr
    elsif d_gr.eql? "MiB"
      ret = (size / (2**20).to_f).round(2).to_s << " " + d_gr
    elsif d_gr.eql? "GiB"
      ret = (size / (2**30).to_f).round(2).to_s << " " + d_gr
    end
    return ret
  end
  
  def calc_laenge laenge
    #laenge in stunden, minuten und sekunden berechnen
    la = ""
    l = laenge.to_i
    l = 0 if laenge.nil?
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
  end
  
  def aus hb, dateien, size, laenge
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
    out.gsub! "%g", calc_size(size) if !size.nil?
    out.gsub! "%l", calc_laenge(laenge) if !laenge.nil?
    out.gsub! "%s", sprecher
    out.gsub! "%b", hb.bewertung.to_s
    out.gsub! "%p", hb.pfad
    
    puts
    puts out
    if !dateien.nil?
      puts "Dateien:"
      dateien.each {|e|
        
        
        d_out = @d_format.gsub "%n", "\n"
        
        #restliche variablen ersetzen
        d_out.gsub! "%tb", "\t"
        d_out.gsub! "%p", e.pfad
        d_out.gsub! "%t", e.titel
        d_out.gsub! "%a", e.album
        d_out.gsub! "%i", e.interpret
        d_out.gsub! "%g", e.genre
        d_out.gsub! "%no", e.nummer
        d_out.gsub! "%j", e.jahr
        d_out.gsub! "%l", la
        d_out.gsub! "%s", calc_size(e.groesse)
        puts
        puts d_out
      } 
    end
  end
end