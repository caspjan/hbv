class Ausgabe
  def initialize einst
    @format = einst.format
    @d_format = einst.datei_format
    @d_gr = einst.datei_groesse
    @stats_format = einst.stats_format
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
  
  def stats_aus stats
#   %l  -> Gesamtlaenge aller Hoerbuecher
#   %s  -> Gesamtgroesse aller Hoerbuecher
#   %d  -> Anzahl aller Dateien
#   %h  -> Anzahl aller Hoerbuecher
#   %t  -> Anzahl aller Tags
#   %b  -> Durchschnittliche Bewertung
#   %ha -> Durchschnittliche Anzahl Hörbücher pro Autor
#   %hs -> Durchschnittliche Anzahl Hörbücher pro Sprecher
#   %ht -> Durchschnittliche Anzahl Hörbücher pro Tag
#   %ah -> Durchschnittliche Anzahl Autoren pro Hörbuch
#   %sh -> Durchschnittliche Anzahl Sprecher pro Hörbuch
#   %th -> Durchschnittliche Anzahl Tags pro Hörbuch
    
    out = @stats_format.gsub "%n", "\n"
    out.gsub! "%tb", "\t"
    out.gsub! "%ha", stats.avg_hb_pro_autor
    out.gsub! "%hf", stats.avg_hb_pro_format
    out.gsub! "%fh", stats.avg_format_pro_hb
    out.gsub! "%db", calc_size(stats.db_size)
    out.gsub! "%hs", stats.avg_hb_pro_sprecher
    out.gsub! "%ht", stats.avg_hb_pro_tag
    out.gsub! "%ah", stats.avg_autoren_pro_hb
    out.gsub! "%sh", stats.avg_sprecher_pro_hb
    out.gsub! "%th", stats.avg_tags_pro_hb
    out.gsub! "%h", stats.hb_ges
    out.gsub! "%s", calc_size(stats.size_ges)
    out.gsub! "%d", stats.dateien_ges.to_s
    out.gsub! "%l", calc_laenge(stats.laenge_ges)
    out.gsub! "%b", stats.bw_avg.to_s
    out.gsub! "%t", stats.tags_ges
    
    puts out
  end
  
  def aus hb, dateien, size, laenge
    out = @format.gsub "%n", "\n"

    autoren = ""
    anz_autoren = hb.autor.length
    hb.autor.each_with_index {|e,i|
      autoren << e
      if i < anz_autoren-1
        autoren << ', '
      end
      }
   
    sprecher = ""
    anz_sprecher = hb.sprecher.length
    hb.sprecher.each_with_index {|e,i|
      sprecher << e
      if i < anz_sprecher-1
        sprecher << ', '
      end
    }
    
    tags = ""
    anz_tags = hb.tags.length
    hb.tags.each_with_index {|e,i|
      tags << e
      if i < anz_tags-1
        tags << ', '
      end
    }
    
    formate = ''
    if !size.nil?   
      size.each_with_index {|e,i|
        formate += e[0] + ': ' + calc_size(e[1])
        if i < size.length-1
          formate += ', '
        end
        
      }
    end
    
    out.gsub! "%tb", "\t"
    out.gsub! "%id", hb.id.to_s
    out.gsub! "%ta", tags
    out.gsub! "%t", hb.titel
    out.gsub! "%g", formate #calc_size(size) if !size.nil?
    out.gsub! "%l", calc_laenge(laenge) if !laenge.nil?
    out.gsub! "%s", sprecher
    out.gsub! "%a", autoren
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
        d_out.gsub! "%no", e.nummer
        d_out.gsub! "%l", calc_laenge(e.laenge)
        d_out.gsub! "%s", calc_size(e.groesse)
        puts
        puts d_out
      } 
    end
  end
  
  def autoren_aus autoren
    #laenge des Laengesten Namen bestimmen
    laenge = 0
    autoren.each {|aut|
      laenge = aut[0].size if aut[0].size > laenge
    }
    ausg = "Name"
    (laenge-3).times {|i| ausg += " "}
    ausg += "Anzahl der Hörbücher"
    puts 'Alle Autoren:'
    puts ausg
    puts
    autoren.each {|e|
      ausg = e[0].to_s
      (laenge-e[0].size+1).times {|i| ausg += " "}
      puts ausg + e[1].to_s
    }
  end
  
  def sprecher_aus sprecher
    #laenge des Laengesten Namen bestimmen
    laenge = 0
    sprecher.each {|sp|
      laenge = sp[0].size if sp[0].size > laenge
    }
    ausg = "Name"
    (laenge-3).times {|i| ausg += " "}
    ausg += "Anzahl der Hörbücher"
    puts 'Alle Sprecher:'
    puts ausg
    puts
    sprecher.each {|e|
      ausg = e[0].to_s
      (laenge-e[0].size+1).times {|i| ausg += " "}
      puts ausg + e[1].to_s
    }
  end
end