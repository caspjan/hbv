require_relative 'require'

class Verwaltung
  def initialize einst
    @einst = einst
    @dbcon = DBCon.new @einst
  end
  
  def full_dump
    hbs = Array.new
    calc_next_id('hoerbuecher').downto(0) {|e|
      hb = get_hb e.to_s
      if !hb.nil?
        hbs << hb
      end
    }
    return hbs
  end
  
  def get_hb id
    hb_res = @con.query 'SELECT * FROM hoerbuecher WHERE id=' + id + ';'
    pfad = ""
    titel = ""
    autor = Array.new
    sprecher = Array.new
    bw = -1
    gibt = false
    hb_res.each_hash {|e|
      gibt = true
      #titel holen
      titel_res = @con.query 'SELECT * FROM titel WHERE id=' + e['titel'] + ';'
      titel_res.each_hash {|f| titel = f['titel']}
      bw_res = @con.query "SELECT * FROM bewertung WHERE id=" + e['bewertung'] + ";"
      bw_res.each_hash {|i| bw = i['bewertung']}
      #pfad holen
      pfad_res = @con.query 'SELECT * FROM pfad WHERE id=' + e['pfad'] + ';'
      pfad_res.each_hash {|f| pfad = f['pfad']}
      #autoren aus zwischentabelle holen
      autoren_res = @con.query 'SELECT * FROM autoren WHERE hoerbuch=' + e['id'] + ';'
      autoren_res.each_hash {|f|
        autor_res = @con.query 'SELECT *FROM autor WHERE id=' + f['autor'] + ';'
        autor_res.each_hash {|g| autor << g['autor'] }
      }
      #sprecher aus zwischentabelle holen
      sprechers_res = @con.query 'SELECT * FROM sprechers WHERE hoerbuch=' + e['id'] + ';'
      sprechers_res.each_hash {|f|
        #sprecher aus sprecher tabelle holen
        sprecher_res = @con.query 'SELECT * FROM sprecher WHERE id=' + f['sprecher'] + ';'
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
    res = @con.query 'SELECT * FROM dateien WHERE hoerbuch=' + hb_id.to_s + ';'
    res.each_hash {|e|
      datei = @con.query 'SELECT * FROM datei WHERE id=' + e['datei'] + ';'
      hbd = Hoerbuch_Datei.new
      datei.each_hash {|f|
        hbd.id = f['id']
        hbd.pfad = f['pfad']
        hbd.titel = f['titel']
        hbd.laenge = f['laenge']
        hbd.groesse = f['groesse']
        hbd.nummer = f['nummer']
        #interpret holen
        interpret_res = @con.query 'SELECT * FROM datei_interpret WHERE id=' + f['interpret'] + ';'
        interpret_res.each_hash {|g| hbd.interpret = g['interpret']}
        #album holen
        album_res = @con.query 'SELECT * FROM datei_album WHERE id=' + f['album'] + ';'
        album_res.each_hash {|g| hbd.album = g['album']}
        #jahr holen
        jahr_res = @con.query 'SELECT * FROM datei_jahr WHERE id=' + f['jahr'] + ';'
        jahr_res.each_hash {|g| hbd.jahr = g['jahr']}
        #genre holens
        genre_res = @con.query 'SELECT * FROM datei_genre WHERE id=' + f['genre'] + ';'
        genre_res.each_hash {|g| hbd.genre = g['genre']}
        dateien << hbd
      }
    }
    return dateien
  end
  
  def suche_bewertung bw
    hbs = Array.new
    #bewertung in der tabelle bewertung suchen
    result = @con.query "SELECT * FROM bewertung WHERE bewertung=" + bw.to_s + ";"
    #über die titel iterieren
    result.each_hash {|row|
      #alle hörbücher mit dem titel suchen
      hoerbuch_res = @con.query "SELECT * FROM hoerbuecher WHERE bewertung=" + row['id'] + ";"
      hoerbuch_res.each_hash {|f|
        titel_res = @con.query "SELECT * FROM titel WHERE id=" + f['titel'] + ";"
        titel = ""
        titel_res.each_hash {|e| titel << e['titel']}
        #in der zwischentabelle nach allen autoren mit dem hoerbuch suchen
        autoren = @con.query "SELECT * FROM autoren WHERE hoerbuch=" + f['id'] + ";"
        autor = Array.new
        autoren.each_hash {|e|
          #in der tabelle autor nach den autoren mit der id suchen
          autor_res = @con.query "SELECT * FROM autor WHERE id=" + e['autor'] + ";"
          autor_res.each_hash {|g| autor << g['autor']}
        }
        #in der zwischentabelle nach allen sprechern mit dem hoerbuch suchen
        sprechers = @con.query "SELECT * FROM sprechers WHERE hoerbuch=" + f['id'] + ";"
        sprecher = Array.new
        sprechers.each_hash {|e|
          #in der tabelle sprecher nach den sprechern mit der id suchen
          sprecher_res = @con.query "SELECT * FROM sprecher WHERE id=" + e['sprecher'] + ";"
          sprecher_res.each_hash {|g| sprecher << g['sprecher']}
        }
        pfad_res = @con.query "SELECT * FROM pfad WHERE id=" + f['pfad'] + ";"
        pfad = ""
        pfad_res.each_hash {|e| pfad << e['pfad']}
        bw_res = @con.query "SELECT * FROM bewertung WHERE id=" + f['bewertung'] + ";"
        bw = 0
        bw_res.each_hash {|i| bw = i['bewertung']}
        hb = Hoerbuch.new row['id'], titel, autor, sprecher, pfad, bw
        hbs << hb
      }
    }
    return hbs
  end
  
  def suche_sprecher sprecher
    hbs = Array.new
    #Aus der Tabelle sprecher den Sprecher suchen und das resultat in array speichern
    sprecher = @con.query "SELECT * FROM sprecher WHERE sprecher LIKE '%" + sprecher + "%';"
    #über das Array iterieren und in der tabelle sprechers die ids der hoerbucher rausholen, zu denen die sprecher gehören
    sprecher.each_hash {|e|
      #Die Hoerbuecher zu den Sprechern bestimmen
      sprecher_zw = @con.query "SELECT * FROM sprechers WHERE sprecher=" + e['id'] + ";"
      #über die sprecher iterieren und die hoerbuch id bestimmen
      sprecher_zw.each_hash {|f|
        hoerbuecher = @con.query "SELECT * FROM hoerbuecher WHERE id=" + f['hoerbuch'] + ";"
        #über die hoerbuecher iterieren und den rest bestimmen
        hoerbuecher.each_hash {|g|
          #in der zwischentabelle für autoren nach der id des Hoerbuchs suchen
          autoren = @con.query "SELECT * FROM autoren WHERE hoerbuch=" + g['id'] + ";"
          #über die autoren iterieren und den namen in array Speichern
          autor = Array.new
          autoren.each_hash {|h|
            autor_res = @con.query "SELECT * FROM autor WHERE id=" + h['autor'] + ";"
            #autoren in array speichern
            autor_res.each_hash {|i| autor << i['autor']}
          }
          #in der zwischentabelle für sprecher nach der id des Hoerbuchs suchen
          sprechers = @con.query "SELECT * FROM sprechers WHERE hoerbuch=" + g['id'] + ";"
          sprecher = Array.new
          sprechers.each_hash {|h|
            sprecher_res = @con.query "SELECT * FROM sprecher WHERE id=" + h['sprecher'] + ";"
            #sprecher in array speichern
            sprecher_res.each_hash {|i| sprecher << i['sprecher']}
          }
          titel_res = @con.query "SELECT * FROM titel WHERE id=" + g['titel'] + ";"
          titel = ""
          titel_res.each_hash {|i| titel << i['titel']}
          bw_res = @con.query "SELECT * FROM bewertung WHERE id=" + g['bewertung'] + ";"
          bw = 0
          bw_res.each_hash {|i| bw = i['bewertung']}
          pfad_res = @con.query "SELECT * FROM pfad WHERE id=" + g['pfad'] + ";"
          pfad = ""
          pfad_res.each_hash {|i| pfad << i['pfad']}
          hb = Hoerbuch.new g['id'], titel, autor, sprecher, pfad, bw
          hbs << hb
        }
      }
    }
    return hbs
  end
  
  def suche_autor autor
    hbs = Array.new
    #Aus der Tabelle sprecher den Autor suchen und das resultat in array speichern
    autoren = @con.query "SELECT * FROM autor WHERE autor LIKE '%" + autor + "%';"
    #über das Array iterieren und in der tabelle autoren die ids der hoerbucher rausholen, zu denen die autoren gehören
    autoren.each_hash {|e|
      #Die Hoerbuecher zu den Autoren bestimmen
      autoren_zw = @con.query "SELECT * FROM autoren WHERE autor=" + e['id'] + ";"
      #über die sprecher iterieren und die hoerbuch id bestimmen
      autoren_zw.each_hash {|f|
        hoerbuecher = @con.query "SELECT * FROM hoerbuecher WHERE id=" + f['hoerbuch'] + ";"
        #über die hoerbuecher iterieren und den rest bestimmen
        hoerbuecher.each_hash {|g|
          #in der zwischentabelle für autoren nach der id des Hoerbuchs suchen
          autoren = @con.query "SELECT * FROM autoren WHERE hoerbuch=" + g['id'] + ";"
          #über die autoren iterieren und den namen in array Speichern
          autor = Array.new
          autoren.each_hash {|h|
            autor_res = @con.query "SELECT * FROM autor WHERE id=" + h['autor'] + ";"
            #autoren in array speichern
            autor_res.each_hash {|i| autor << i['autor']}
          }
          #in der zwischentabelle für sprecher nach der id des Hoerbuchs suchen
          sprechers = @con.query "SELECT * FROM sprechers WHERE hoerbuch=" + g['id'] + ";"
          sprecher = Array.new
          sprechers.each_hash {|h|
            sprecher_res = @con.query "SELECT * FROM sprecher WHERE id=" + h['sprecher'] + ";"
            #sprecher in array speichern
            sprecher_res.each_hash {|i| sprecher << i['sprecher']}
          }
          titel_res = @con.query "SELECT * FROM titel WHERE id=" + g['titel'] + ";"
          titel = ""
          titel_res.each_hash {|i| titel << i['titel']}
          bw_res = @con.query "SELECT * FROM bewertung WHERE id=" + g['bewertung'] + ";"
          bw = 0
          bw_res.each_hash {|i| bw = i['bewertung']}
          pfad_res = @con.query "SELECT * FROM pfad WHERE id=" + g['pfad'] + ";"
          pfad = ""
          pfad_res.each_hash {|i| pfad << i['pfad']}
          hb = Hoerbuch.new g['id'], titel, autor, sprecher, pfad, bw
          hbs << hb
        }
      }
    }
    return hbs
  end
  
  def suche_titel titel
    hbs = Array.new
    #titel in der tabelle titel suchen
    result = @con.query "SELECT * FROM titel WHERE titel LIKE '%" + titel + "%';"
    #über die titel iterieren
    result.each_hash {|row|
      #alle hörbücher mit dem titel suchen
      hoerbuch_res = @con.query "SELECT * FROM hoerbuecher WHERE titel=" + row['id'] + ";"
      hoerbuch_res.each_hash {|f|
        titel_res = @con.query "SELECT * FROM titel WHERE id=" + f['titel'] + ";"
        titel = ""
        titel_res.each_hash {|e| titel << e['titel']}
        #in der zwischentabelle nach allen autoren mit dem hoerbuch suchen
        autoren = @con.query "SELECT * FROM autoren WHERE hoerbuch=" + f['id'] + ";"
        autor = Array.new
        autoren.each_hash {|e|
          #in der tabelle autor nach den autoren mit der id suchen
          autor_res = @con.query "SELECT * FROM autor WHERE id=" + e['autor'] + ";"
          autor_res.each_hash {|g| autor << g['autor']}
        }
        #in der zwischentabelle nach allen sprechern mit dem hoerbuch suchen
        sprechers = @con.query "SELECT * FROM sprechers WHERE hoerbuch=" + f['id'] + ";"
        sprecher = Array.new
        sprechers.each_hash {|e|
          #in der tabelle sprecher nach den sprechern mit der id suchen
          sprecher_res = @con.query "SELECT * FROM sprecher WHERE id=" + e['sprecher'] + ";"
          sprecher_res.each_hash {|g| sprecher << g['sprecher']}
        }
        pfad_res = @con.query "SELECT * FROM pfad WHERE id=" + f['pfad'] + ";"
        pfad = ""
        pfad_res.each_hash {|e| pfad << e['pfad']}
        bw_res = @con.query "SELECT * FROM bewertung WHERE id=" + f['bewertung'] + ";"
        bw = 0
        bw_res.each_hash {|i| bw = i['bewertung']}
        hb = Hoerbuch.new row['id'], titel, autor, sprecher, pfad, bw
        hbs << hb
      }
    }
    return hbs
  end
    
  def clear_tables
    @con.query 'TRUNCATE datei'
    @con.query 'TRUNCATE dateien'
    @con.query 'TRUNCATE datei_interpret'
    @con.query 'TRUNCATE datei_jahr'
    @con.query 'TRUNCATE datei_genre'
    @con.query 'TRUNCATE datei_album'
    @con.query 'TRUNCATE hoerbuecher'
    @con.query 'TRUNCATE titel'
    @con.query 'TRUNCATE autor'
    @con.query 'TRUNCATE autoren'
    @con.query 'TRUNCATE pfad'
    @con.query 'TRUNCATE sprecher'
    @con.query 'TRUNCATE sprechers'
    @con.query 'TRUNCATE bewertung'
  end
  
  def gibt_wert? tabelle, spalte, wert
    result = @con.query "SELECT * FROM " + tabelle + " WHERE " + spalte + "='" + wert.to_s + "';"
    id = -1
    result.each_hash {|e| id = e['id']}
    if id == -1
        return false
    else
      return id
    end
  end
  
  def hoerbuch_einfuegen hb
    #id des neuen hoerbuchs bestimmen
    new_id = calc_next_id "hoerbuecher"
    #über die autoren des hörbuchs iterieren
    autor_ids = Array.new
    hb.autor.each {|e|
      #für jeden autor schauen, ob er schon existiert
      if !gibt_wert? "autor", "autor", e
        pst = @con.prepare 'INSERT INTO autor(autor) VALUES(?)'
        pst.execute e
        autor_ids << gibt_wert?("autor", "autor", e)
      else
        autor_ids << gibt_wert?("autor", "autor", e)
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
      if !gibt_wert? "sprecher", "sprecher", e
        pst = @con.prepare 'INSERT INTO sprecher(sprecher) VALUES(?)'
        pst.execute e
        sprecher_ids << gibt_wert?("sprecher", "sprecher", e)
      else
        sprecher_ids << gibt_wert?("sprecher", "sprecher", e)
      end
    }
    #verknüpfung für jeden sprecher in sprecher_ids in der zwischentabelle erstellen
    pst = @con.prepare 'INSERT INTO sprechers(hoerbuch, sprecher) VALUES(?, ?)'
    sprecher_ids.each {|e|
      pst.execute new_id, e
    }
    
    #wenn der titel noch nicht existiert, neu anlegen
    if !gibt_wert? "titel", "titel", hb.titel
      pst = @con.prepare 'INSERT INTO titel(titel) VALUES(?)'
      pst.execute hb.titel
    end
    titel_id = gibt_wert? "titel", "titel", hb.titel
    
    #wenn die bewertung noch nicht existiert, neu anlegen
    if !gibt_wert? "bewertung", "bewertung", hb.bewertung
      pst = @con.prepare 'INSERT INTO bewertung(bewertung) VALUES(?)'
      pst.execute hb.bewertung
    end
    bewertung_id = gibt_wert? "bewertung", "bewertung", hb.bewertung
    
    #pfad neu anlegen
    pst = @con.prepare 'INSERT INTO pfad(pfad) VALUES(?)'
    pst.execute hb.pfad
    pfad_id = calc_next_id('pfad') - 1
    
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
      datei_next_id = calc_next_id "datei"
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
    if !gibt_wert? "datei_interpret", "interpret", datei.interpret
      pst = @con.prepare 'INSERT INTO datei_interpret(interpret) VALUES(?)'
      pst.execute datei.interpret
    end
    interpret_id = gibt_wert? "datei_interpret", "interpret", datei.interpret
    
    #schauen, ob es das genre schon gibt
    if !gibt_wert? "datei_genre", "genre", datei.genre
      pst = @con.prepare 'INSERT INTO datei_genre(genre) VALUES(?)'
      pst.execute datei.genre
    end
    genre_id = gibt_wert? "datei_genre", "genre", datei.genre
    
    #schauen, ob es das Jahr schon gibt
    if !gibt_wert? "datei_jahr", "jahr", datei.jahr
      pst = @con.prepare 'INSERT INTO datei_jahr(jahr) VALUES(?)'
      pst.execute datei.jahr
    end
    jahr_id = gibt_wert? "datei_jahr", "jahr", datei.jahr
    
    #schauen, ob es das album schon gibt
    if !gibt_wert? "datei_album", "album", datei.album
      pst = @con.prepare 'INSERT INTO datei_album(album) VALUES(?)'
      pst.execute datei.album
    end
    album_id = gibt_wert? "datei_album", "album", datei.album
    
    #feste sachen einfuegen
    pst = @con.prepare 'INSERT INTO datei(pfad, titel, laenge, groesse, nummer, album, interpret, jahr, genre) VALUES(?, ?, ?, ?, ?, ?, ?, ?, ?)'
    pst.execute datei.pfad.expand_path.to_s, datei.titel.to_s, datei.laenge.to_i, datei.groesse.to_i, datei.nummer.to_i, album_id.to_i, interpret_id.to_i, jahr_id.to_i, genre_id.to_i
  end
  
  def clean_autoren
    #alle autoren einlesen
    autoren = @con.query 'SELECT * FROM autor'
    autoren.each_hash {|e|
      kommt_vor = false
      #überprüfen, ob die id des autors in der zwischentabelle steht
      verkn = @con.query 'SELECT * FROM autoren WHERE autor=' + e['id'] + ';'
      verkn.each {|f| kommt_vor = true}
      #wenn nicht, loschen
      if !kommt_vor
        #autor löschen
        @con.query 'DELETE FROM autor WHERE id=' + e['id'] + ';'
      end
    }
  end
  
  def clean_sprecher
    #alle sprecher einlesen
    sprecher = @con.query 'SELECT * FROM sprecher'
    sprecher.each_hash {|e|
      kommt_vor = false
      #überprüfen, ob die id des sprechers in der zwischentabelle steht
      verkn = @con.query 'SELECT * FROM sprechers WHERE sprecher=' + e['id'] + ';'
      verkn.each {|f| kommt_vor = true}
      #wenn nicht, loschen
      if !kommt_vor
        #sprecher löschen
        @con.query 'DELETE FROM sprecher WHERE id=' + e['id'] + ';'
      end
    }
  end
  
  def clean_datei_interpreten
    #alle interpreten einlesen
    interpreten = @con.query 'SELECT * FROM datei_interpret'
    interpreten.each_hash {|e|
      kommt_vor = false
      #überprüfen, ob die id des interpreten in der tabelle datei steht
      datei = @con.query 'SELECT * FROM datei WHERE interpret=' + e['id'] + ';'
      datei.each {|f| kommt_vor = true}
      #wenn nicht, loschen
      if !kommt_vor
        #sprecher löschen
        @con.query 'DELETE FROM datei_interpret WHERE id=' + e['id'] + ';'
      end
    }
  end
  
  def clean_datei_alben
    #alle alben einlesen
    alben = @con.query 'SELECT * FROM datei_album'
    alben.each_hash {|e|
      kommt_vor = false
      #überprüfen, ob die id des album in der tabelle datei steht
      datei = @con.query 'SELECT * FROM datei WHERE album=' + e['id'] + ';'
      datei.each {|f| kommt_vor = true}
      #wenn nicht, loschen
      if !kommt_vor
        #sprecher löschen
        @con.query 'DELETE FROM datei_album WHERE id=' + e['id'] + ';'
      end
    }
  end
  
  def clean_datei_genres
    #alle genres einlesen
    genres = @con.query 'SELECT * FROM datei_genre'
    genres.each_hash {|e|
      kommt_vor = false
      #überprüfen, ob die id des interpreten in der tabelle datei steht
      datei = @con.query 'SELECT * FROM datei WHERE genre=' + e['id'] + ';'
      datei.each {|f| kommt_vor = true}
      #wenn nicht, loschen
      if !kommt_vor
        #sprecher löschen
        @con.query 'DELETE FROM datei_genre WHERE id=' + e['id'] + ';'
      end
    }
  end
  
  def clean_datei_jahr
    #alle jahre einlesen
    jahr = @con.query 'SELECT * FROM datei_jahr'
    jahr.each_hash {|e|
      kommt_vor = false
      #überprüfen, ob die id des interpreten in der tabelle datei steht
      datei = @con.query 'SELECT * FROM datei WHERE jahr=' + e['id'] + ';'
      datei.each {|f| kommt_vor = true}
      #wenn nicht, loschen
      if !kommt_vor
        #sprecher löschen
        @con.query 'DELETE FROM datei_jahr WHERE id=' + e['id'] + ';'
      end
    }
  end
  
  def clean_bewertung
    bw_res = @con.query 'SELECT * FROM bewertung'
    bw_res.each_hash {|e|
      gibt = false
      hb_res = @con.query 'SELECT *FROM hoerbuecher WHERE id=' + e['id'] + ';'
      hb_res.each {|f|
        gibt = true
      }
      @con.query 'DELETE FROM bewertung WHERE id=' + e['id'] + ';' if !gibt
    }
  end
  
  def hoerbuch_loeschen hb
    #id des pfades holen und loeschen
    hb_res = @con.query 'SELECT * FROM hoerbuecher WHERE id=' + hb.id + ';'
    hb_res.each_hash {|e|
      #pfad loeschen
      @con.query 'DELETE FROM pfad WHERE id=' + e['pfad'] + ';'
      #titel loeschen
      @con.query 'DELETE FROM titel WHERE id=' + e['titel'] + ';'
      #verknüpfungen des autors aus zwischentabelle loeschen
      @con.query 'DELETE FROM autoren WHERE hoerbuch=' + e['id'] + ';'
      #verknüpfungen des sprechers aus zwischentabelle loeschen
      @con.query 'DELETE FROM sprechers WHERE hoerbuch=' + e['id'] + ';'
      #checken, ob es autoren ohne hoerbuch gibt
      clean_autoren
      #checken, ob es sprecher ohne hoerbuch gibt
      clean_sprecher
      #checken, ob es bewertungen ohne hoerbuch gibt
      clean_bewertung
      #hoerbuch loeschen
      @con.query 'DELETE FROM hoerbuecher WHERE id=' + hb.id + ';'
      #alle dateien des albums loeschen
      dateien = get_dateien hb.id
      dateien.each {|f|
        datei_loeschen f.id
      }
      #alle verknüpfungen zum hoerbuch loschen
      @con.query 'DELETE FROM dateien WHERE hoerbuch=' + hb.id + ';'
    }
  end
  
  def datei_loeschen id
    #datei loeschen
    @con.query 'DELETE FROM datei WHERE id=' + id + ';'
    #checken, ob es interpreten ohne datei gibt
    clean_datei_interpreten
    #checken, ob es alben ohne datei gibt
    clean_datei_alben
    #checken, ob es genres ohne datei gibt
    clean_datei_genres
    #checken, ob es jahre ohne datei gibt
    clean_datei_jahr
  end
  
  def calc_next_id tabelle
    res = @con.query 'SHOW TABLE STATUS FROM ' + @einst.db + ' WHERE Name="' + tabelle + '";'
    id = 0
    res.each_hash {|e| id = e['Auto_increment'].to_i}
    return id
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
      id = gibt_wert? spalte, spalte, wert_neu
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
      id = gibt_wert? spalte, spalte, wert_neu
      if id
        #verweis in zwischentabelle ändern
        @con.query 'UPDATE ' + tabelle + ' SET ' + spalte + "='" + wert_neu + "' WHERE hoerbuch=" + hb_id + " and " + spalte + "=" + id + ';'
      else
        #autor/sprecher neu anlegen
        wert_neu.each_with_index {|e,i|
          pst = @con.prepare 'INSERT INTO ' + spalte + '(' + spalte + ') VALUES(?)'
          pst.execute e
          #verweis(e) in zwischentabelle ändern
          id = gibt_wert? spalte, spalte, e
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