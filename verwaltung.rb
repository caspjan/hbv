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
    new_id = @dbcon.calc_next_id "hoerbuecher"
    #über die autoren des hörbuchs iterieren
    autor_ids = Array.new
    hb.autor.each {|e|
      #für jeden autor schauen, ob er schon existiert
      if !@dbcon.gibt_wert? "autor", "autor", e
        pst = @con.prepare 'INSERT INTO autor(autor) VALUES(?)'
        pst.execute e
        autor_ids << @dbcon.gibt_wert?("autor", "autor", e)
      else
        autor_ids << @dbcon.gibt_wert?("autor", "autor", e)
      end
    }
    #verknüpfung für jeden autor in autor_ids in der zwischentabelle erstellen
    pst = @con.prepare 'INSERT INTO autoren(hoerbuch, autor) VALUES(?, ?)'
    autor_ids.each {|e|
      pst.execute new_id, e
    }
    
    #über die sprecher des hörbuchs iterieren
    sprecher_ids = Array.new
    hb.sprecher.each {|e|
      #für jeden sprecher schauen, ob er schon existiert
      if !@dbcon.gibt_wert? "sprecher", "sprecher", e
        pst = @con.prepare 'INSERT INTO sprecher(sprecher) VALUES(?)'
        pst.execute e
        sprecher_ids << @dbcon.gibt_wert?("sprecher", "sprecher", e)
      else
        sprecher_ids << @dbcon.gibt_wert?("sprecher", "sprecher", e)
      end
    }
    #verknüpfung für jeden sprecher in sprecher_ids in der zwischentabelle erstellen
    pst = @con.prepare 'INSERT INTO sprechers(hoerbuch, sprecher) VALUES(?, ?)'
    sprecher_ids.each {|e|
      pst.execute new_id, e
    }
    
    #wenn der titel noch nicht existiert, neu anlegen
    if !@dbcon.gibt_wert? "titel", "titel", hb.titel
      pst = @con.prepare 'INSERT INTO titel(titel) VALUES(?)'
      pst.execute hb.titel
    end
    titel_id = @dbcon.gibt_wert? "titel", "titel", hb.titel
    
    #wenn die bewertung noch nicht existiert, neu anlegen
    if !@dbcon.gibt_wert? "bewertung", "bewertung", hb.bewertung
      pst = @con.prepare 'INSERT INTO bewertung(bewertung) VALUES(?)'
      pst.execute hb.bewertung
    end
    bewertung_id = @dbcon.gibt_wert? "bewertung", "bewertung", hb.bewertung
    
    #pfad neu anlegen
    pst = @con.prepare 'INSERT INTO pfad(pfad) VALUES(?)'
    pst.execute hb.pfad
    pfad_id = @dbcon.calc_next_id('pfad') - 1
    
    #hörbuch anlegen
    pst = @con.prepare 'INSERT INTO hoerbuecher(titel, pfad, bewertung) VALUES(?, ?, ?)'
    pst.execute titel_id, pfad_id, bewertung_id
    
    #dateien einlesen
    pp = Pfad_Parser.new hb.pfad, @einst
    dateien = pp.parse
    dateien.each_with_index {|e,i|
      #metakram von datei holen
      dm = Datei_Meta_Parser.new e, i+1
      #dateien in die datenbank schreiben
      datei_next_id = @dbcon.calc_next_id "datei"
      datei_einfuegen dm.parse
      #verknüpfunge von hoerbuch und datei in die datenbank tun
      datei_verkn_einfuegen datei_next_id, new_id
    }
    
  end
  
  
  def datei_verkn_einfuegen datei_id, hb_id
    pst = @con.prepare 'INSERT INTO dateien(hoerbuch, datei) VALUES(?, ?)'
    pst.execute hb_id, datei_id
  end
  
  def datei_einfuegen datei
    #schauen, ob es den interpreten schon gibt
    if !@dbcon.gibt_wert? "datei_interpret", "interpret", datei.interpret
      pst = @con.prepare 'INSERT INTO datei_interpret(interpret) VALUES(?)'
      pst.execute datei.interpret
    end
    interpret_id = @dbcon.gibt_wert? "datei_interpret", "interpret", datei.interpret
    
    #schauen, ob es das genre schon gibt
    if !@dbcon.gibt_wert? "datei_genre", "genre", datei.genre
      pst = @con.prepare 'INSERT INTO datei_genre(genre) VALUES(?)'
      pst.execute datei.genre
    end
    genre_id = @dbcon.gibt_wert? "datei_genre", "genre", datei.genre
    
    #schauen, ob es das Jahr schon gibt
    if !@dbcon.gibt_wert? "datei_jahr", "jahr", datei.jahr
      pst = @con.prepare 'INSERT INTO datei_jahr(jahr) VALUES(?)'
      pst.execute datei.jahr
    end
    jahr_id = @dbcon.gibt_wert? "datei_jahr", "jahr", datei.jahr
    
    #schauen, ob es das album schon gibt
    if !@dbcon.gibt_wert? "datei_album", "album", datei.album
      pst = @con.prepare 'INSERT INTO datei_album(album) VALUES(?)'
      pst.execute datei.album
    end
    album_id = @dbcon.gibt_wert? "datei_album", "album", datei.album
    
    #feste sachen einfuegen
    pst = @con.prepare 'INSERT INTO datei(pfad, titel, laenge, groesse, nummer, album, interpret, jahr, genre) VALUES(?, ?, ?, ?, ?, ?, ?, ?, ?)'
    pst.execute datei.pfad.expand_path.to_s, datei.titel.to_s, datei.laenge.to_i, datei.groesse.to_i, datei.nummer.to_i, album_id.to_i, interpret_id.to_i, jahr_id.to_i, genre_id.to_i
  end
  
  #def clean_autoren
  #  #alle autoren einlesen
  #  autoren = @con.query 'SELECT * FROM autor'
  #  autoren.each_hash {|e|
  #    kommt_vor = false
  #    #überprüfen, ob die id des autors in der zwischentabelle steht
  #    verkn = @con.query 'SELECT * FROM autoren WHERE autor=' + e['id'] + ';'
  #    verkn.each {|f| kommt_vor = true}
  #    #wenn nicht, loschen
  #    if !kommt_vor
  #      #autor löschen
  #      @con.query 'DELETE FROM autor WHERE id=' + e['id'] + ';'
  #    end
  #  }
  #end
  
  #def clean_sprecher
  #  #alle sprecher einlesen
  #  sprecher = @con.query 'SELECT * FROM sprecher'
  #  sprecher.each_hash {|e|
  #    kommt_vor = false
  #    #überprüfen, ob die id des sprechers in der zwischentabelle steht
  #    verkn = @con.query 'SELECT * FROM sprechers WHERE sprecher=' + e['id'] + ';'
  #    verkn.each {|f| kommt_vor = true}
  #    #wenn nicht, loschen
  #    if !kommt_vor
  #      #sprecher löschen
  #      @con.query 'DELETE FROM sprecher WHERE id=' + e['id'] + ';'
  #    end
  #  }
  #end
  
  #def clean_datei_interpreten
  #  #alle interpreten einlesen
  #  interpreten = @con.query 'SELECT * FROM datei_interpret'
  #  interpreten.each_hash {|e|
  #    kommt_vor = false
  #    #überprüfen, ob die id des interpreten in der tabelle datei steht
  #    datei = @con.query 'SELECT * FROM datei WHERE interpret=' + e['id'] + ';'
  #    datei.each {|f| kommt_vor = true}
  #    #wenn nicht, loschen
  #    if !kommt_vor
  #      #sprecher löschen
  #      @con.query 'DELETE FROM datei_interpret WHERE id=' + e['id'] + ';'
  #    end
  #  }
  #end
  #
  #def clean_datei_alben
  #  #alle alben einlesen
  #  alben = @con.query 'SELECT * FROM datei_album'
  #  alben.each_hash {|e|
  #    kommt_vor = false
  #    #überprüfen, ob die id des album in der tabelle datei steht
  #    datei = @con.query 'SELECT * FROM datei WHERE album=' + e['id'] + ';'
  #    datei.each {|f| kommt_vor = true}
  #    #wenn nicht, loschen
  #    if !kommt_vor
  #      #sprecher löschen
  #      @con.query 'DELETE FROM datei_album WHERE id=' + e['id'] + ';'
  #    end
  #  }
  #end
  #
  #def clean_datei_genres
  #  #alle genres einlesen
  #  genres = @con.query 'SELECT * FROM datei_genre'
  #  genres.each_hash {|e|
  #    kommt_vor = false
  #    #überprüfen, ob die id des interpreten in der tabelle datei steht
  #    datei = @con.query 'SELECT * FROM datei WHERE genre=' + e['id'] + ';'
  #    datei.each {|f| kommt_vor = true}
  #    #wenn nicht, loschen
  #    if !kommt_vor
  #      #sprecher löschen
  #      @con.query 'DELETE FROM datei_genre WHERE id=' + e['id'] + ';'
  #    end
  #  }
  #end
  #
  #def clean_datei_jahr
  #  #alle jahre einlesen
  #  jahr = @con.query 'SELECT * FROM datei_jahr'
  #  jahr.each_hash {|e|
  #    kommt_vor = false
  #    #überprüfen, ob die id des interpreten in der tabelle datei steht
  #    datei = @con.query 'SELECT * FROM datei WHERE jahr=' + e['id'] + ';'
  #    datei.each {|f| kommt_vor = true}
  #    #wenn nicht, loschen
  #    if !kommt_vor
  #      #sprecher löschen
  #      @con.query 'DELETE FROM datei_jahr WHERE id=' + e['id'] + ';'
  #    end
  #  }
  #end
  
  #def clean_bewertung
  #  bw_res = @con.query 'SELECT * FROM bewertung'
  #  bw_res.each_hash {|e|
  #    gibt = false
  #    hb_res = @con.query 'SELECT *FROM hoerbuecher WHERE id=' + e['id'] + ';'
  #    hb_res.each {|f|
  #      gibt = true
  #    }
  #    @con.query 'DELETE FROM bewertung WHERE id=' + e['id'] + ';' if !gibt
  #  }
  #end
  
  def hoerbuch_loeschen hb
    #id des pfades holen und loeschen
    hb_res = @dbcon.get_hb_id hb.id
    hb_res.each_hash {|e|
      #pfad loeschen
      @dbcon.remove_path e['pfad']
      #titel loeschen
      @dbcon.remove_title e['titel']
      #verknüpfungen des autors aus zwischentabelle loeschen
      @dbcon.remove_zw_hb e['id'], 'autoren'
      #verknüpfungen des sprechers aus zwischentabelle loeschen
      @dbcon.remove_zw_hb e['id'], 'sprechers'
      #checken, ob es autoren ohne hoerbuch gibt
      @dbcon.clean_zw_table 'autor'
      #checken, ob es sprecher ohne hoerbuch gibt
      @dbcon.clean_zw_table 'sprecher'
      #checken, ob es bewertungen ohne hoerbuch gibt
      @dbcon.clean_bewertung
      #hoerbuch loeschen
      @dbcon.remove_hb_id hb.id
      #alle dateien des albums loeschen
      dateien = get_dateien hb.id
      dateien.each {|f|
        datei_loeschen f.id
      }
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
    res = @con.query 'SELECT COUNT(*) FROM hoerbuecher'
    res.each_hash {|e| stats.hb_ges = e['COUNT(*)']}
    #gesamtlaenge + groesse aller Hoerbucher
    bw = 0
    hbs_res = @con.query 'SELECT * FROM hoerbuecher'
    hbs_res.each_hash {|e|
      dateien = get_dateien e['id']
      stats.laenge_ges += get_hb_laenge dateien
      stats.size_ges += get_hb_size dateien
      dateien.each {|f|
        stats.dateien_ges += 1
      }
      bw_res = @con.query "SELECT * FROM bewertung WHERE id=" + e['bewertung'] + ";"
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
      puts hb_id, spalte, wert_neu, wert_alt
      puts 'UPDATE ' + spalte + ' SET ' + spalte + '="' + wert_neu + '" WHERE ' + spalte + '="' + wert_alt + '";'
     
      @con.query 'UPDATE ' + spalte + ' SET ' + spalte + '="' + wert_neu + '" WHERE ' + spalte + '="' + wert_alt + '";'
      #neue id in hoerbuch tabelle schreiben
      id = @dbcon.gibt_wert? spalte, spalte, wert_neu
      @con.query 'UPDATE hoerbuecher SET ' + spalte + '=' + id + ' WHERE id=' + hb_id + ";"
      #beim pfad alle dateien neu einlesen
      if spalte.eql? 'pfad'
        #alle variablen vom alten hoerbuch holen, das alte löschen, und ein neues anlegen
        hb = get_hb hb_id
        #altes löschen
        hoerbuch_loeschen hb
        #neues einfuegen
        hoerbuch_einfuegen hb
      end
    elsif spalte.eql? 'autor' or spalte.eql? 'sprecher'
      #schauen, ob es den neuen autor/sprecher gibt
      tabelle = "autoren" if spalte.eql? "autor"
      tabelle = "sprechers" if spalte.eql? "sprecher"
      id = @dbcon.gibt_wert? spalte, spalte, wert_neu
      if id
        #verweis in zwischentabelle ändern
        @con.query 'UPDATE ' + tabelle + ' SET ' + spalte + "='" + wert_neu + "' WHERE hoerbuch=" + hb_id + " and " + spalte + "=" + id + ';'
      else
        #autor/sprecher neu anlegen
        wert_neu.each_with_index {|e,i|
          pst = @con.prepare 'INSERT INTO ' + spalte + '(' + spalte + ') VALUES(?)'
          pst.execute e
          #verweis(e) in zwischentabelle ändern
          id = @dbcon.gibt_wert? spalte, spalte, e
          #id des alten wertes ermitteln
          wert_alt.each {|g| 
            res = @con.query 'SELECT * FROM ' + spalte + ' WHERE ' + spalte + '="' + g + '";'
            j = 0
            res.each_hash {|f|
              if j == i
                @con.query 'UPDATE ' + tabelle + ' SET ' + spalte + "='" + id + "' WHERE hoerbuch=" + hb_id + " and " + spalte + "=" + f['id'] + ';'
              end
              j += 1
            }
          }
        }
        #alten autor/sprecher löschen
        clean_autoren
        clean_sprecher
      end
    elsif spalte.eql? ''
    end
    
  end
end