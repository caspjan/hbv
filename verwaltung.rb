require_relative 'require'

class Verwaltung
  def initialize einst
    @einst = einst
    @dbcon = DBCon.new @einst
  end
  
  def full_dump
    hbs = Array.new
    @dbcon.calc_next_id('hoerbuecher').downto(0) {|e|
      hb = get_hb e.to_s
      if !hb.nil?
        hbs << hb
      end
    }
    return hbs
  end
  
  def get_hb id
    hb_res = @dbcon.get_hb_id id
    pfad = ""
    titel = ""
    autor = Array.new
    sprecher = Array.new
    bw = -1
    gibt = false
    hb_res.each_hash {|e|
      gibt = true
      #titel holen
      titel_res = @dbcon.get_titel_id e['titel']
      titel_res.each_hash {|f| titel = f['titel']}
      bw_res = @dbcon.get_bewertung_id e['bewertung']
      bw_res.each_hash {|i| bw = i['bewertung']}
      #pfad holen
      pfad_res = @dbcon.get_pfad_id e['pfad']
      pfad_res.each_hash {|f| pfad = f['pfad']}
      #autoren aus zwischentabelle holen
      autoren_res = @dbcon.get_autor_zw_hb e['id']
      autoren_res.each_hash {|f|
        autor_res = @dbcon.get_autor_id f['autor']
        autor_res.each_hash {|g| autor << g['autor'] }
      }
      #sprecher aus zwischentabelle holen
      sprechers_res = @dbcon.get_sprecher_zw_hb e['id']
      sprechers_res.each_hash {|f|
        #sprecher aus sprecher tabelle holen
        sprecher_res = @dbcon.get_sprecher_id f['sprecher']
        sprecher_res.each_hash {|g| sprecher << g['sprecher']}
      }
    }
    if gibt
      return Hoerbuch.new id, titel, autor, sprecher, pfad, bw
    else
      return nil
    end
  end
  
  def get_dateien hb_id
    dateien = Array.new
    #alle ids aus zwischentabelle holen
    res = @dbcon.get_datei_zw_hb hb_id
    res.each_hash {|e|
      datei = @dbcon.get_datei e['datei']
      hbd = Hoerbuch_Datei.new
      datei.each_hash {|f|
        hbd.id = f['id']
        hbd.pfad = f['pfad']
        hbd.titel = f['titel']
        hbd.laenge = f['laenge']
        hbd.groesse = f['groesse']
        hbd.nummer = f['nummer']
        #interpret holen
        interpret_res = @dbcon.get_interpret f['interpret']
        interpret_res.each_hash {|g| hbd.interpret = g['interpret']}
        #album holen
        album_res = @dbcon.get_album f['album']
        album_res.each_hash {|g| hbd.album = g['album']}
        #jahr holen
        jahr_res = @dbcon.get_jahr f['jahr']
        jahr_res.each_hash {|g| hbd.jahr = g['jahr']}
        #genre holens
        genre_res = @dbcon.get_genre f['genre']
        genre_res.each_hash {|g| hbd.genre = g['genre']}
        dateien << hbd
      }
    }
    return dateien
  end
  
  def suche_bewertung bw
    hbs = Array.new
    #bewertung in der tabelle bewertung suchen
    res = @dbcon.get_bewertung bw
    #über die titel iterieren
    res.each_hash {|row|
      #alle hörbücher mit dem titel suchen
      hoerbuch_res = @dbcon.get_hb_bw_id row['id']
      hoerbuch_res.each_hash {|f|
        hb = get_hb f['id']
        hbs << hb
      }
    }
    return hbs
  end
  
  def suche_sprecher sprecher
    hbs = Array.new
    #Aus der Tabelle sprecher den Sprecher suchen und das resultat in array speichern
    sprecher = @dbcon.suche_sprecher sprecher
    #über das Array iterieren und in der tabelle sprechers die ids der hoerbucher rausholen, zu denen die sprecher gehören
    sprecher.each_hash {|e|
      #Die Hoerbuecher zu den Sprechern bestimmen
      sprecher_zw = @dbcon.get_sprecher_zw_sprecher e['id']
      #über die sprecher iterieren und die hoerbuch id bestimmen
      sprecher_zw.each_hash {|f|
          hb = get_hb f['hoerbuch']
          hbs << hb
        }
      }
    return hbs
  end
  
  def suche_autor autor
    hbs = Array.new
    #Aus der Tabelle sprecher den Autor suchen und das resultat in array speichern
    autoren = @dbcon.suche_autor autor
    #über das Array iterieren und in der tabelle autoren die ids der hoerbucher rausholen, zu denen die autoren gehören
    autoren.each_hash {|e|
      #Die Hoerbuecher zu den Autoren bestimmen
      autoren_zw = @dbcon.get_autor_zw_autor e['id']
      #über die sprecher iterieren und die hoerbuch id bestimmen
      autoren_zw.each_hash {|f|
        hb = get_hb f['hoerbuch']
        hbs << hb
      }
    }
    return hbs
  end
  
  def suche_titel titel
    hbs = Array.new
    #titel in der tabelle titel suchen
    result = @dbcon.suche_titel titel
    #über die titel iterieren
    result.each_hash {|g|
      #alle hörbücher mit dem titel suchen
      hoerbuch_res = @dbcon.get_hb_titel_id g['id']
      hoerbuch_res.each_hash {|f|
        hb = get_hb f['id']
        hbs << hb
      }
    }
    return hbs
  end
    
  def clear_tables
    @dbcon.clear_tables
  end
  
  def hoerbuch_einfuegen hb
    #id des neuen hoerbuchs bestimmen
    new_id = @dbcon.calc_next_id 'hoerbuecher'
    #über die autoren des hörbuchs iterieren
    autor_ids = Array.new
    hb.autor.each {|e|
      #für jeden autor schauen, ob er schon existiert
      if !@dbcon.gibt_wert? 'autor', 'autor', e
        #autor anlegen
        @dbcon.ins 'autor', 'autor', e
        autor_ids << @dbcon.gibt_wert?('autor', 'autor', e)
      else
        autor_ids << @dbcon.gibt_wert?('autor', 'autor', e)
      end
    }
    #verknüpfung für jeden autor in autor_ids in der zwischentabelle erstellen
    @dbcon.ins_zw 'autoren', 'hoerbuch', 'autor', new_id, autor_ids
    #über die sprecher des hörbuchs iterieren
    sprecher_ids = Array.new
    hb.sprecher.each {|e|
      #für jeden sprecher schauen, ob er schon existiert
      if !@dbcon.gibt_wert? 'sprecher', 'sprecher', e
        @dbcon.ins 'sprecher', 'sprecher', e
        sprecher_ids << @dbcon.gibt_wert?('sprecher', 'sprecher', e)
      else
        sprecher_ids << @dbcon.gibt_wert?('sprecher', 'sprecher', e)
      end
    }
    #verknüpfung für jeden sprecher in sprecher_ids in der zwischentabelle erstellen
    @dbcon.ins_zw 'sprechers', 'hoerbuch', 'sprecher', new_id, sprecher_ids
    
    #wenn der titel noch nicht existiert, neu anlegen
    if !@dbcon.gibt_wert? 'titel', 'titel', hb.titel
      @dbcon.ins 'titel', 'titel', hb.titel
    end
    titel_id = @dbcon.gibt_wert? 'titel', 'titel', hb.titel
    
    #wenn die bewertung noch nicht existiert, neu anlegen
    if !@dbcon.gibt_wert? 'bewertung', 'bewertung', hb.bewertung
      @dbcon.ins 'bewertung', 'bewertung', hb.bewertung
    end
    bewertung_id = @dbcon.gibt_wert? 'bewertung', 'bewertung', hb.bewertung
    
    #pfad neu anlegen
    pfad_id = @dbcon.calc_next_id('pfad')
    @dbcon.ins 'pfad', 'pfad', hb.pfad
    
    #hörbuch anlegen
    @dbcon.ins_hb titel_id, pfad_id, bewertung_id
    
    #dateien einlesen
    pp = Pfad_Parser.new hb.pfad, @einst
    dateien = pp.parse
    dateien.each_with_index {|e,i|
      #metakram von datei holen
      dm = Datei_Meta_Parser.new e, i+1
      #dateien in die datenbank schreiben
      datei_next_id = @dbcon.calc_next_id 'datei'
      datei_einfuegen dm.parse
      #verknüpfunge von hoerbuch und datei in die datenbank tun
      @dbcon.ins_file_zw datei_next_id, new_id
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
  
  def hoerbuch_loeschen hb
    #id des pfades holen und loeschen
    hb_res = @dbcon.get_hb_id hb.id
    hb_res.each_hash {|hbb|
      #pfad loeschen
      @dbcon.remove_path hbb['pfad']
      #titel loeschen
      @dbcon.remove_title hbb['titel']
      #verknüpfungen des autors aus zwischentabelle loeschen
      @dbcon.remove_zw_hb hbb['id'], 'autoren'
      #verknüpfungen des sprechers aus zwischentabelle loeschen
      @dbcon.remove_zw_hb hbb['id'], 'sprechers'
      
      #hoerbuch loeschen
      @dbcon.remove_hb hbb['id']
      
      #checken, ob es autoren ohne hoerbuch gibt
      @dbcon.clean_table 'autor'
      #checken, ob es sprecher ohne hoerbuch gibt
      @dbcon.clean_table 'sprecher'
      #checken, ob es bewertungen ohne hoerbuch gibt
      @dbcon.clean_table 'bewertung'
      #alle dateien des albums loeschen
      dateien = get_dateien hbb['id']
      dateien.each_with_index {|f,i|
        @dbcon.remove_file f.id
      }
      #checken, ob es interpreten ohne datei gibt
      @dbcon.clean_file_table 'datei_interpret'
      #checken, ob es alben ohne datei gibt
      @dbcon.clean_file_table 'datei_album'
      #checken, ob es genres ohne datei gibt
      @dbcon.clean_file_table 'datei_genre'
      #checken, ob es jahre ohne datei gibt
      @dbcon.clean_file_table 'datei_jahr'
      #alle verknüpfungen zum hoerbuch loschen
      @dbcon.remove_zw_hb hb.id, 'dateien'
    }
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
  
  def get_hb_size hb_dateien
    ges_gr = Float(0)
    hb_dateien.each {|e|
      ges_gr += e.groesse.to_f
    }
    return ges_gr
  end
  
  def get_hb_laenge hb_dateien
    ges_len = 0
    hb_dateien.each {|e|
      ges_len += e.laenge.to_f
    }
    return ges_len
  end
  
  def get_stats
    stats = Stats.new
    #anzahl der Hoerbucher
    res = @dbcon.count 'hoerbuecher'
    res.each_hash {|e| stats.hb_ges = e['COUNT(*)']}
    #gesamtlaenge + groesse aller Hoerbucher
    bw = 0
    hbs_res = @dbcon.get_hbs
    hbs_res.each_hash {|e|
      dateien = get_dateien e['id']
      stats.laenge_ges += get_hb_laenge dateien
      stats.size_ges += get_hb_size dateien
      dateien.each {|f|
        stats.dateien_ges += 1
      }
      bw_res = @dbcon.get_bewertung_id e['bewertung']
      bw_res.each_hash {|i|
        bw += i['bewertung'].to_i
        f = i['bewertung']
        if stats.bewertungen[f].nil?
          stats.bewertungen[f] = 0
        end
        stats.bewertungen[f] += 1
        }
    }
   stats.bw_durchschn = Float(bw) / Float(stats.hb_ges)
   return stats
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
        puts id
        if id
          #verweis in zwischentabelle ändern
          wert_alt.each {|e|  
            id_alt = @dbcon.gibt_wert? spalte, spalte, e
            puts id_alt
            @dbcon.update_zw tabelle, spalte, id, id_alt, hb_id
          }
        else
          #autor/sprecher neu anlegen
          #wert_neu.each_with_index {|neu,i|
          @dbcon.ins spalte, spalte, neu
          #verweis(e) in zwischentabelle ändern
          id = @dbcon.gibt_wert? spalte, spalte, neu
          puts id
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
    autoren = Hash.new
    #alle autoren holen
    autoren_res = @dbcon.get_all 'autor'
    autoren_res.each_hash {|aut|
      autoren[aut['autor']] = 0
      #anzahl der Hoerbuecher des Autors bestimmen
      hbs = Array.new
      #zwischentabelle holen
      res = @dbcon.get_autor_zw_autor aut['id']
      #id des hoerbuchs speichern
      res.each_hash {|zw|
        if !hbs.include? zw['hoerbuch']
          hbs << zw['hoerbuch']
          autoren[aut['autor']] += 1
        end
      }
    }
    return autoren
  end
  
  def get_sprecher
    sprecher = Hash.new
    #alle sprecher holen
    sprecher_res = @dbcon.get_all 'sprecher'
    sprecher_res.each_hash {|sp|
      sprecher[sp['sprecher']] = 0
      #anzahl der Hoerbucher des Sprechers bestimmen
      hbs = Array.new
      #zwischentabelle holen
      res = @dbcon.get_sprecher_zw_sprecher sp['id']
      #id des hoerbuchs speichern
      res.each_hash {|zw|
        if !hbs.include? zw['hoerbuch']
          hbs << zw['hoerbuch']
            sprecher[sp['sprecher']] += 1
        end 
      }
    }
    return sprecher
  end
  
  def play hb_id, start, ende
    #alle benötigten dateien in ein array schieben
    dateien = get_dateien hb_id
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
    skip_end = 0
    dateien.each_with_index {|d,i|
      if i > start_index
        laenge += d.laenge.to_i
        end_index = i.to_s
        end_index = end_index.to_i
      end
      if ende < laenge
        stop = skip+(ende-start)
        stop = ende-(laenge-d.laenge.to_i)
        puts stop
        end_index = start_index if i == 0
        break
      end
    }
    
    if end_index == start_index
      stop = skip+(ende-start)
    end
    
    #playeroptionen feststellen
    player = @einst.player.split('/')[-1]
    case player
    when 'mpv'
      if end_index == start_index
        puts @einst.player + ' --start=' + skip.to_s + ' --end=' + stop.to_s + ' "' + dateien[start_index].pfad + '"'
        system @einst.player + ' --start=' + skip.to_s + ' --end=' + stop.to_s + ' "' + dateien[start_index].pfad + '"'
      elsif end_index != 0
        puts @einst.player + ' --start=' + skip.to_s + ' "' + dateien[start_index].pfad + '"'
        system @einst.player + ' --start=' + skip.to_s + ' "' + dateien[start_index].pfad + '"'
        dateien.each_with_index {|e,i|
          puts 'i: ' + i.to_s
          puts 'start_index: ' + start_index.to_s
          puts 'end_index: ' + stop.to_s
          if i > start_index and i < end_index
            system @einst.player + ' "' + dateien[i].pfad + '"'
          end
        }
        puts @einst.player + ' --end=' + stop.to_s + ' "' + dateien[end_index].pfad + '"'
        system @einst.player + ' --end=' + stop.to_s + ' "' + dateien[end_index].pfad + '"'
      end
    end
  end
end