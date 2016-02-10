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
    #id des neuen hoerbuchs bestimmen
    #new_id = @dbcon.calc_next_id 'Hoerbuch'
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
    
    #formate einlesen
    pp = Pfad_Parser.new hb.pfad, @einst
    formate = pp.parse
    formate.each {|format|
      #format inkl allen cds und dateien in die datenbank schreiben
      @dbcon.ins_format hb_id, format
    }
    
  end
  
  def datei_einfuegen datei
    #schauen, ob es den interpreten schon gibt
    if !@dbcon.gibt_wert? 'datei_interpret', 'interpret', datei.interpret
      @dbcon.ins 'datei_interpret', 'interpret', datei.interpret
    end
    interpret_id = @dbcon.gibt_wert? 'datei_interpret', 'interpret', datei.interpret
    
    #schauen, ob es das genre schon gibt
    if !@dbcon.gibt_wert? 'datei_genre', 'genre', datei.genre
      @dbcon.ins 'datei_genre', 'genre', datei.genre
    end
    genre_id = @dbcon.gibt_wert? 'datei_genre', 'genre', datei.genre
    
    #schauen, ob es das Jahr schon gibt
    if !@dbcon.gibt_wert? 'datei_jahr', 'jahr', datei.jahr
      @dbcon.ins 'datei_jahr', 'jahr', datei.jahr
    end
    jahr_id = @dbcon.gibt_wert? 'datei_jahr', 'jahr', datei.jahr
    
    #schauen, ob es das album schon gibt
    if !@dbcon.gibt_wert? 'datei_album', 'album', datei.album
      @dbcon.ins 'datei_album', 'album', datei.album
    end
    album_id = @dbcon.gibt_wert? 'datei_album', 'album', datei.album
    
    #feste sachen einfuegen
    @dbcon.ins_file datei.pfad.expand_path, datei.titel, datei.laenge, datei.groesse, datei.nummer, album_id, interpret_id, jahr_id, genre_id
  end
  
  def hoerbuch_loeschen hb_id
    @dbcon.remove_hb hb_id
  end
  
  def datei_loeschen id
    #datei loeschen
    @dbcon.remove_file id
    #checken, ob es interpreten ohne datei gibt
    @dbcon.clean_file_table 'datei_interpreten'
    #checken, ob es alben ohne datei gibt
    @dbcon.clean_file_table 'datei_album'
    #checken, ob es genres ohne datei gibt
    @dbcon.clean_file_table 'datei_genre'
    #checken, ob es jahre ohne datei gibt
    @dbcon.clean_file_table 'datei_jahr'
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
  
  def change hb_id, spalte, wert_neu, wert_alt
    #hoerbuchtabelle aendern
    if spalte.eql? 'titel' or spalte.eql? 'pfad'
      #titel/pfad ändern
      @dbcon.update 'titel', wert_neu, wert_alt
      #neue id in hoerbuch tabelle schreiben
      id = @dbcon.gibt_wert? spalte, spalte, wert_neu
      @dbcon.update_hb spalte, hb_id, id
      #beim pfad alle dateien neu einlesen
      if spalte.eql? 'pfad'
        #alle variablen vom alten hoerbuch holen, das alte löschen, und ein neues anlegen
        hb = get_hb hb_id
        hb.pfad = wert_neu
        #altes löschen
        hoerbuch_loeschen hb
        #neues einfuegen
        hoerbuch_einfuegen hb
      end
    elsif spalte.eql? 'autor' or spalte.eql? 'sprecher'
      #schauen, ob es den neuen autor/sprecher gibt
      tabelle = 'autoren' if spalte.eql? 'autor'
      tabelle = 'sprechers' if spalte.eql? 'sprecher'
      wert_neu.each_with_index {|neu,i|
        id = @dbcon.gibt_wert? spalte, spalte, neu
        #wenns die schon gibt
        #puts id
        if id
          #verweis in zwischentabelle ändern
          wert_alt.each {|e|  
            id_alt = @dbcon.gibt_wert? spalte, spalte, e
            #puts id_alt
            @dbcon.update_zw tabelle, spalte, id, id_alt, hb_id
          }
        else
          #autor/sprecher neu anlegen
          #wert_neu.each_with_index {|neu,i|
          @dbcon.ins spalte, spalte, neu
          #verweis(e) in zwischentabelle ändern
          id = @dbcon.gibt_wert? spalte, spalte, neu
          #puts id
          #id des alten wertes ermitteln
          wert_alt.each {|g| 
            res = @dbcon.get spalte, spalte, g
            j = 0
            res.each_hash {|alt|
              if j == i
                @dbcon.update_zw tabelle, spalte, id, alt['id'], hb_id
              end
              j += 1
            }
          }
        end
      }
      #alten autor/sprecher löschen
      @dbcon.clean_table 'autor'
      @dbcon.clean_zw_table 'autor'
      @dbcon.clean_table 'sprecher'
      @dbcon.clean_zw_table 'sprecher'
    end
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