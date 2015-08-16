require 'mysql'
require_relative 'einstellung_parser'
require_relative 'hoerbuch'

class Verwaltung
  def initialize
    einst_pars = Einstellung_Parser.new '/home/jan/Dokumente/Programmierzeug/Hoerbuch/hoerbuch.conf'
    @einst = einst_pars.einst
    @con = Mysql.new @einst.host, @einst.user, @einst.passwd, @einst.db
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
      titel_res.each {|f| titel = f}
      #pfad holen
      pfad_res = @con.query 'SELECT * FROM pfad WHERE id=' + e['pfad'] + ';'
      pfad_res.each {|f| pfad = f}
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
            autor_res.each {|i| autor << i}
          }
          #in der zwischentabelle für sprecher nach der id des Hoerbuchs suchen
          sprechers = @con.query "SELECT * FROM sprechers WHERE hoerbuch=" + g['id'] + ";"
          sprecher = Array.new
          sprechers.each_hash {|h|
            sprecher_res = @con.query "SELECT * FROM sprecher WHERE id=" + h['sprecher'] + ";"
            #sprecher in array speichern
            sprecher_res.each {|i| sprecher << i}
          }
          titel_res = @con.query "SELECT * FROM titel WHERE id=" + g['titel'] + ";"
          titel = Array.new
          titel_res.each {|i| titel << i}
          pfad_res = @con.query "SELECT * FROM pfad WHERE id=" + g['pfad'] + ";"
          pfad = Array.new
          pfad_res.each {|i| pfad << i}
          hb = Hoerbuch.new g['id'], titel, autor, pfad, sprecher
          hbs << hb
        }
      }
    }
    return strip_cols hbs
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
            autor_res.each {|i| autor << i}
          }
          #in der zwischentabelle für sprecher nach der id des Hoerbuchs suchen
          sprechers = @con.query "SELECT * FROM sprechers WHERE hoerbuch=" + g['id'] + ";"
          sprecher = Array.new
          sprechers.each_hash {|h|
            sprecher_res = @con.query "SELECT * FROM sprecher WHERE id=" + h['sprecher'] + ";"
            #sprecher in array speichern
            sprecher_res.each {|i| sprecher << i}
          }
          titel_res = @con.query "SELECT * FROM titel WHERE id=" + g['titel'] + ";"
          titel = Array.new
          titel_res.each {|i| titel << i}
          pfad_res = @con.query "SELECT * FROM pfad WHERE id=" + g['pfad'] + ";"
          pfad = Array.new
          pfad_res.each {|i| pfad << i}
          hb = Hoerbuch.new g['id'], titel, autor, sprecher, pfad
          hbs << hb
        }
      }
    }
    return strip_cols hbs
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
        titel = Array.new
        titel_res.each {|e| titel << e}
        #in der zwischentabelle nach allen autoren mit dem hoerbuch suchen
        autoren = @con.query "SELECT * FROM autoren WHERE hoerbuch=" + f['id'] + ";"
        autor = Array.new
        autoren.each_hash {|e|
          #in der tabelle autor nach den autoren mit der id suchen
          autor_res = @con.query "SELECT * FROM autor WHERE id=" + e['autor'] + ";"
          autor_res.each {|g| autor << g}
        }
        #in der zwischentabelle nach allen sprechern mit dem hoerbuch suchen
        sprechers = @con.query "SELECT * FROM sprechers WHERE hoerbuch=" + f['id'] + ";"
        sprecher = Array.new
        sprechers.each_hash {|e|
          #in der tabelle autor nach den autoren mit der id suchen
          sprecher_res = @con.query "SELECT * FROM sprecher WHERE id=" + e['sprecher'] + ";"
          sprecher_res.each {|g| sprecher << g}
        }
        pfad_res = @con.query "SELECT * FROM pfad WHERE id=" + f['pfad'] + ";"
        pfad = Array.new
        pfad_res.each {|e| pfad << e}
        hb = Hoerbuch.new row['id'], titel, autor, pfad, sprecher
        hbs << hb
      }
    }
    return strip_cols hbs
  end
  
  def strip_cols hbs
    #unnötige spalten des mysql resultats loswerden
    hbs.collect { |hb|
      hb.titel.map! {|t| t[1]}
      hb.sprecher.map! {|s| s[1]}
      hb.autor.map! {|a| a[1]}
      hb.pfad.map! {|p| p[1]}
    }
    return hbs
  end
  
  def clear_tables
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
    res = @con.query 'SHOW TABLE STATUS FROM hoerbuch;'
    #res = @con.query 'SELECT Auto_increment FROM information_schema.tables WHERE TABLE_NAME=' + tabelle + ';'
    #res = @con.query 'SELECT COUNT(*) FROM ' + tabelle + ';'
    id = 0
    res.each_hash {|e| id = e['Auto_increment'].to_i}
    return id
  end
end