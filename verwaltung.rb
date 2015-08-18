require 'mysql'
require_relative 'einstellung_parser'
require_relative 'hoerbuch'

class Verwaltung
  def initialize einst
    @einst = einst
    @con = Mysql.new @einst.host, @einst.user, @einst.passwd, @einst.db
  end
  
  def init_db
    #alle benötigten Tabellen anlegen
    @con.query 'CREATE TABLE `autor` (`id` int(11) NOT NULL AUTO_INCREMENT, `autor` text NOT NULL, UNIQUE KEY `id` (`id`)) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=latin1'
    @con.query 'CREATE TABLE `autoren` (`hoerbuch` int(11) NOT NULL, `autor` int(11) NOT NULL) ENGINE=InnoDB DEFAULT CHARSET=latin1'
    @con.query 'CREATE TABLE `hoerbuecher` (`id` int(11) NOT NULL AUTO_INCREMENT, `titel` int(11) NOT NULL, `pfad` int(11) NOT NULL, UNIQUE KEY `id_2` (`id`), KEY `id` (`id`)) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=latin1'
    @con.query 'CREATE TABLE `pfad` (`id` int(11) NOT NULL AUTO_INCREMENT, `pfad` text NOT NULL, UNIQUE KEY `id` (`id`)) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=latin1'
    @con.query 'CREATE TABLE `sprecher` (`id` int(11) NOT NULL AUTO_INCREMENT, `sprecher` text NOT NULL, UNIQUE KEY `id` (`id`)) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=latin1'
    @con.query 'CREATE TABLE `sprechers` (`hoerbuch` int(11) NOT NULL, `sprecher` int(11) NOT NULL) ENGINE=InnoDB DEFAULT CHARSET=latin1'
    @con.query 'CREATE TABLE `titel` (`id` int(1) NOT NULL AUTO_INCREMENT, `titel` text NOT NULL, UNIQUE KEY `id` (`id`)) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=latin1'
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
    gibt = false
    hb_res.each_hash {|e|
      gibt = true
      #titel holen
      titel_res = @con.query 'SELECT * FROM titel WHERE id=' + e['titel'] + ';'
      titel_res.each_hash {|f| titel = f['titel']}
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
      return Hoerbuch.new id, titel, autor, sprecher, pfad
    else
      return nil
    end
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
          pfad_res = @con.query "SELECT * FROM pfad WHERE id=" + g['pfad'] + ";"
          pfad = ""
          pfad_res.each_hash {|i| pfad << i['pfad']}
          hb = Hoerbuch.new g['id'], titel, autor, sprecher, pfad
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
          pfad_res = @con.query "SELECT * FROM pfad WHERE id=" + g['pfad'] + ";"
          pfad = ""
          pfad_res.each_hash {|i| pfad << i['pfad']}
          hb = Hoerbuch.new g['id'], titel, autor, sprecher, pfad
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
        hb = Hoerbuch.new row['id'], titel, autor, sprecher, pfad
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
  end
  
  def gibt_titel? titel
    result = @con.query "SELECT * FROM titel WHERE titel='" + titel + "';"
    id = -1
    result.each_hash {|e| id = e['id']}
    if id == -1
        return false
    else
      return id
    end
  end
  
  def gibt_autor? autor
    result = @con.query "SELECT * FROM autor WHERE autor='" + autor + "';"
    id = -1
    result.each_hash {|e| id = e['id']}
    if id == -1
        return false
    else
      return id
    end
  end
    
  def gibt_sprecher? sprecher
    result = @con.query "SELECT * FROM sprecher WHERE sprecher='" + sprecher + "';"
    id = -1
    result.each_hash {|e| id = e['id']}
    if id == -1
        return false
    else
      return id
    end
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
      if !gibt_autor? e
        pst = @con.prepare 'INSERT INTO autor(autor) VALUES(?)'
        pst.execute e
        autor_ids << gibt_autor?(e)
      else
        autor_ids << gibt_autor?(e)
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
      if !gibt_sprecher? e
        pst = @con.prepare 'INSERT INTO sprecher(sprecher) VALUES(?)'
        pst.execute e
        sprecher_ids << gibt_sprecher?(e)
      else
        sprecher_ids << gibt_sprecher?(e)
      end
    }
    #verknüpfung für jeden sprecher in sprecher_ids in der zwischentabelle erstellen
    pst = @con.prepare 'INSERT INTO sprechers(hoerbuch, sprecher) VALUES(?, ?)'
    sprecher_ids.each {|e|
      pst.execute new_id, e
    }
    
    #wenn der titel noch nicht existiert, neu anlegen
    if !gibt_titel? hb.titel
      pst = @con.prepare 'INSERT INTO titel(titel) VALUES(?)'
      pst.execute hb.titel
    end
    titel_id = gibt_titel? hb.titel
    
    #pfad neu anlegen
    pst = @con.prepare 'INSERT INTO pfad(pfad) VALUES(?)'
    pst.execute hb.pfad
    pfad_id = calc_next_id('pfad') - 1
    
    #hörbuch anlegen
    pst = @con.prepare 'INSERT INTO hoerbuecher(titel, pfad) VALUES(?, ?)'
    pst.execute titel_id, pfad_id
    return new_id
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
      #hoerbuch loeschen
      @con.query 'DELETE FROM hoerbuecher WHERE id=' + hb.id + ';'
    }
  end
  
  def calc_next_id tabelle
    res = @con.query 'SHOW TABLE STATUS FROM ' + @einst.db + ' WHERE Name="' + tabelle + '";'
    id = 0
    res.each_hash {|e| id = e['Auto_increment'].to_i}
    return id
  end
end