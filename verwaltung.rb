require_relative 'require'

class Verwaltung
  def initialize einst
    @einst = einst
    @dbcon = DBCon.new @einst
  end
  
  def full_dump
    @dbcon.full_dump
  end
  
  def get_hb hb_id
    @dbcon.get_hb(hb_id)
  end
  
  def get_dateien hb_id, format
    @dbcon.get_dateien(@dbcon.get_format_id(hb_id, format))
  end
  
  def get_format_id hb_id, format
    @dbcon.get_format_id hb_id, format
  end
  
  def get_formate hb_id
    @dbcon.get_formate hb_id
  end
  
  def suche_bewertung bw
    @dbcon.suche_bewertung bw
  end
  
  def suche_sprecher sprecher
    @dbcon.suche_sprecher sprecher
  end
  
  def suche_autor autor
    @dbcon.suche_autor autor
  end
  
  def suche_tag tag
    @dbcon.suche_tag tag
  end
  
  def suche_titel titel
    @dbcon.suche_titel titel
  end
    
  def clear_tables
    @dbcon.clear_tables
  end
  
  def hoerbuch_einfuegen hb
    #checken ob es ein Format und eine CD gibt
    pfad = Pathname.new @einst.basedir + hb.pfad
    gibt_formate = false
    pfad.children.each {|e|
      gibt_formate = true if @einst.datei_endungen.include? e.basename.to_s.prepend "."
    }
    raise "Im Angegebenen Pfad gibt es kein passendendes Format." if !gibt_formate
    
    gibt_cd = false
    gibt_dateien = false
    pfad.children.each {|e|
      if @einst.datei_endungen.include? e.basename.to_s.prepend "."
        e.children.each {|f|
          gibt_cd = tmp = true if f.basename.to_s.include? "CD" or f.basename.to_s.include? "cd" or f.basename.to_s.include? "Cd" or f.basename.to_s.include? "cD"
          if tmp
            f.children.each {|g|
              gibt_dateien = true if (g.extname.casecmp(e.basename.to_s.prepend(".")) == 0)
              puts g
              puts g.extname
            }
          end
          tmp = false
        }
      end 
    }
    raise "Im Angegebenen Pfad gibt es kein Format mit einer CD drin." if !gibt_cd
    raise "Es wurde keine passende Datei gefunden." if !gibt_dateien
    
    #formate einlesen
    pp = Pfad_Parser.new hb.pfad, @einst
    formate = pp.parse
    
    #checken, ob die längen der Formate übereinstimmen
    laengen = Array.new
    laenge_tmp = 0
    formate.each {|format|
      format.cds.each {|cd|
        cd.dateien.each {|datei|
          laenge_tmp += datei.laenge
        }
      }
      laengen << laenge_tmp
      laenge_tmp = 0
    }
    
    gleich = true
    laengen.each_with_index  {|e,i|
      if i<laengen.size-1
        gleich = false if (e-laengen[i+1]).abs > 300
        puts (e-laengen[i+1]).abs > 300
      end
    }
    
    raise "Die Längen der Formate unterscheiden sich mehr als 5 Minuten." if !gleich
    
    #id des neuen hoerbuchs bestimmen
    #über die autoren des hörbuchs iterieren
    autor_ids = Array.new
    hb.autor.each {|e|
      #für jeden autor schauen, ob er schon existiert
      if !@dbcon.gibt_wert? 'Autor', 'name', e
        #autor anlegen
        @dbcon.ins 'Autor', 'name', e
        autor_ids << @dbcon.gibt_wert?('Autor', 'name', e)
      else
        autor_ids << @dbcon.gibt_wert?('Autor', 'name', e)
      end
    }
    #hörbuch anlegen und neue id merken
    hb_id = @dbcon.ins_hb hb.titel, hb.pfad, hb.bewertung
    #puts hb_id
    
    #verknüpfung für jeden autor in autor_ids in der zwischentabelle erstellen
    @dbcon.ins_zw 'Autor_has_Hoerbuch', 'Hoerbuch_idHoerbuch', 'Autor_idAutor', hb_id, autor_ids
    
    #über die sprecher des hörbuchs iterieren
    sprecher_ids = Array.new
    hb.sprecher.each {|e|
      #für jeden sprecher schauen, ob er schon existiert
      if !@dbcon.gibt_wert? 'Sprecher', 'name', e
        @dbcon.ins 'Sprecher', 'name', e
        sprecher_ids << @dbcon.gibt_wert?('Sprecher', 'name', e)
      else
        sprecher_ids << @dbcon.gibt_wert?('Sprecher', 'name', e)
      end
    }
    #verknüpfung für jeden sprecher in sprecher_ids in der zwischentabelle erstellen
    @dbcon.ins_zw 'Sprecher_has_Hoerbuch', 'Hoerbuch_idHoerbuch', 'Sprecher_idSprecher', hb_id, sprecher_ids
    
    #tags
    tag_ids = Array.new
    hb.tags.each {|e|
       #für jeden tag schauen, ob er schon existiert
      if !@dbcon.gibt_wert? 'Tag', 'tag', e
        @dbcon.ins 'Tag', 'tag', e
        tag_ids << @dbcon.gibt_wert?('Tag', 'tag', e)
      else
        tag_ids << @dbcon.gibt_wert?('Tag', 'tag', e)
      end
    }
    #verküpfung für jeden tag einfügen
    @dbcon.ins_zw 'Tag_has_Hoerbuch', 'Hoerbuch_idHoerbuch', 'Tag_idTag', hb_id, tag_ids
    
   
    formate.each {|format|
      #format inkl allen cds und dateien in die datenbank schreiben
      @dbcon.ins_format hb_id, format
    }
    
  end

  def hoerbuch_loeschen hb_id
    @dbcon.remove_hb hb_id
  end

  def get_hb_size hb_id
    return @dbcon.get_hb_size hb_id
  end
  
  def get_hb_laenge hb_id
    @dbcon.get_hb_laenge hb_id
  end
  
  def get_stats
   @dbcon.get_stats
  end
  
  def update_sprecher hb_id, sprecher
    @dbcon.update_sprecher hb_id, sprecher
  end
  
  def update_autor hb_id, autor
    @dbcon.update_autor hb_id, autor
  end
  
  def add_tag hb_id, tag
    @dbcon.add_tag hb_id, tag
  end
  
  def remove_tag hb_id, tag
    @dbcon.remove_tag hb_id, tag
  end
  
  def update_titel hb_id, titel
    @dbcon.update_titel hb_id, titel
  end
  
  def update_pfad hb_id, pfad
    #alten pfad löschen
    @dbcon.remove_formate hb_id
    
    #formate einlesen
    pp = Pfad_Parser.new pfad, @einst
    formate = pp.parse
    formate.each {|format|
      #format inkl allen cds und dateien in die datenbank schreiben
      @dbcon.ins_format hb_id, format
    }
  end
  
  def get_autoren
    @dbcon.get_autoren
  end
  
  def get_sprecher
    @dbcon.get_sprecher
  end
  
  def up_pos hb_id, pos
    @dbcon.up_pos hb_id, pos
  end
  
  def get_last_pos hb_id
    @dbcon.get_last_pos hb_id
  end
  
  def pfad pfad
    @einst.basedir + pfad
  end
  
  def play hb_id, format, start, ende
    #alle benötigten dateien in ein array schieben
    dateien = get_dateien hb_id, format
    #alle längen der dateien addieren, bis sie größer als start ist
    
    laenge = 0
    start_index = 0
    skip = 0
    dateien.each_with_index {|d,i|
      laenge += d.laenge.to_i
      start_index = i
      if start < laenge
        skip = start-(laenge-d.laenge.to_i)
        break
      end
    }
    #ab start_index alle addieren bis die laenge größer als ende ist
    end_index = 0
    #skip_end = 0
    dateien.each_with_index {|d,i|
      if i > start_index
        laenge += d.laenge.to_i
        end_index = i.to_s
        end_index = end_index.to_i
      end
      if ende < laenge
        stop = skip+(ende-start)
        stop = ende-(laenge-d.laenge.to_i)
        end_index = start_index if i == 0
        break
      end
    }
    
    if end_index == start_index
      stop = skip+(ende-start)
    end
    
    puts "end_index: " + end_index
    
    #playeroptionen feststellen
    player = @einst.player.split('/')[-1]
    case player
    when 'mpv'
      if end_index == start_index
        puts @einst.player + ' --start=' + skip.to_s + ' --end=' + stop.to_s + ' "' + pfad(dateien[start_index].pfad) + '"'
        system @einst.player + ' --start=' + skip.to_s + ' --end=' + stop.to_s + ' "' + pfad(dateien[start_index].pfad) + '"'
      elsif end_index != 0
        puts @einst.player + ' --start=' + skip.to_s + ' "' + pfad(dateien[start_index].pfad) + '"'
        system @einst.player + ' --start=' + skip.to_s + ' "' + pfad(dateien[start_index].pfad) + '"'
        dateien.each_with_index {|e,i|
          puts 'i: ' + i.to_s
          puts 'start_index: ' + start_index.to_s
          puts 'end_index: ' + stop.to_s
          if i > start_index and i < end_index
            system @einst.player + ' "' + pfad(dateien[i].pfad) + '"'
          end
        }
        puts @einst.player + ' --end=' + stop.to_s + ' "' + pfad(dateien[end_index].pfad) + '"'
        system @einst.player + ' --end=' + stop.to_s + ' "' + pfad(dateien[end_index].pfad) + '"'
      end
    end
  end
end