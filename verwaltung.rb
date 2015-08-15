require 'mysql'
require_relative 'einstellung_parser'
require_relative 'hoerbuch'

class Verwaltung
  def initialize
    einst_pars = Einstellung_Parser.new '/home/jan/Dokumente/Programmierzeug/Hoerbuch/hoerbuch.conf'
    @einst = einst_pars.einst
    @con = Mysql.new @einst.host, @einst.user, @einst.passwd, @einst.db
  end
  
  def suche_titel titel
    hbs = Array.new
    #Daten aus Datenbank holen
    result = @con.query "SELECT * FROM titel WHERE titel LIKE '%" + titel + "%';"
    result.each_hash {|row|
      hoerbuch_res = @con.query "SELECT * FROM hoerbuecher WHERE titel=" + row['hoerbuch'] + ";"
      hoerbuch_res.each_hash {|f|
        titel_res = @con.query "SELECT * FROM titel WHERE hoerbuch=" + f['titel'] + ";"
        titel = Array.new
        titel_res.each {|e| titel << e}
        autor_res = @con.query "SELECT * FROM autor WHERE hoerbuch=" + f['autor'] + ";"
        autor = Array.new
        autor_res.each {|e| autor << e}
        sprecher_res = @con.query "SELECT * FROM sprecher WHERE hoerbuch=" + f['sprecher'] + ";"
        sprecher = Array.new
        sprecher_res.each {|e| sprecher << e}
        pfad_res = @con.query "SELECT * FROM pfad WHERE hoerbuch=" + f['pfad'] + ";"
        pfad = Array.new
        pfad_res.each {|e| pfad << e}
        hb = Hoerbuch.new row['id'], titel, autor, pfad, sprecher
        hbs << hb
      }
    }
    return strip_cols hbs
  end
  
  def suche_autor autor
    hbs = Array.new
    result = @con.query "SELECT * FROM autor WHERE autor LIKE '%" + autor + "%';"
    result.each_hash {|row|
      hoerbuch_res = @con.query "SELECT * FROM hoerbuecher WHERE autor=" + row['hoerbuch'] + ";"
      hoerbuch_res.each_hash {|f|
        autor_res = @con.query "SELECT * FROM autor WHERE hoerbuch=" + f['autor'] + ";"
        autor = Array.new
        autor_res.each {|e| autor << e}
        titel_res = @con.query "SELECT * FROM titel WHERE hoerbuch=" + f['titel'] + ";"
        titel = Array.new
        titel_res.each {|e| titel << e}
        sprecher_res = @con.query "SELECT * FROM sprecher WHERE hoerbuch=" + f['sprecher'] + ";"
        sprecher = Array.new
        sprecher_res.each {|e| sprecher << e}
        pfad_res = @con.query "SELECT * FROM pfad WHERE hoerbuch=" + f['pfad'] + ";"
        pfad = Array.new
        pfad_res.each {|e| pfad << e}
        hb = Hoerbuch.new f['id'], titel, autor, pfad, sprecher
        hbs << hb
      }
    }
    return strip_cols hbs
  end
  
  def suche_sprecher sprecher
    hbs = Array.new
    result = @con.query "SELECT * FROM sprecher WHERE sprecher LIKE '%" + sprecher + "%';"
    result.each_hash {|row|
      hoerbuch_res = @con.query "SELECT * FROM hoerbuecher WHERE sprecher=" + row['hoerbuch'] + ";"
      hoerbuch_res.each_hash {|f|
        autor_res = @con.query "SELECT * FROM autor WHERE hoerbuch=" + f['autor'] + ";"
        autor = Array.new
        autor_res.each {|e| autor << e}
        titel_res = @con.query "SELECT * FROM titel WHERE hoerbuch=" + f['titel'] + ";"
        titel = Array.new
        titel_res.each {|e| titel << e}
        sprecher_res = @con.query "SELECT * FROM sprecher WHERE hoerbuch=" + f['sprecher'] + ";"
        sprecher = Array.new
        sprecher_res.each {|e| sprecher << e}
        pfad_res = @con.query "SELECT * FROM pfad WHERE hoerbuch=" + f['pfad'] + ";"
        pfad = Array.new
        pfad_res.each {|e| pfad << e}
        hb = Hoerbuch.new f['id'], titel, autor, pfad, sprecher
        hbs << hb
      }
    }
    return  strip_cols hbs
  end
  
  def strip_cols hbs
    #unnötige spalten des mysql resultats loswerden
    hbs.collect { |hb|
      hb.titel.map! {|t| t[2]}
      hb.sprecher.map! {|s| s[2]}
      hb.autor.map! {|a| a[2]}
      hb.pfad.map! {|p| p[2]}
    }
    return hbs
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
    t = gibt_titel? hb.titel
    a = gibt_autor? hb.autor
    s = gibt_sprecher? hb.sprecher
    #id des neuen hoerbuchs bestimmen
    id = calc_next_id "hoerbuecher"
    #titel, autor und sprecher anlegen, sofern es sie noch nich gibt
    if !t
      pst = @con.prepare 'INSERT INTO titel(hoerbuch, titel) VALUES(?, ?)'
      pst.execute id, hb.titel
      t = calc_next_id 'titel'
    end
    if !a
      pst = @con.prepare 'INSERT INTO autor(hoerbuch, autor) VALUES(?, ?)'
      pst.execute id, hb.autor
      a = calc_next_id 'autor'
    end
    if !s
      pst = @con.prepare 'INSERT INTO sprecher(hoerbuch, sprecher) VALUES(?, ?)'
      pst.execute id, hb.sprecher
      s = calc_next_id 'sprecher'
    end
    #pfad auf jeden fall neu einfügen
    pst = @con.prepare 'INSERT INTO pfad(hoerbuch, pfad) VALUES(?, ?)'
    pst.execute id, hb.pfad
    p = calc_next_id 'pfad'
    #hoerbuch schreiben
    pst = @con.prepare 'INSERT INTO hoerbuecher(autor, titel, sprecher, pfad) VALUES(?, ?, ?, ?)'
    pst.execute a, t, s, p
  end
  
  def calc_next_id tabelle
    res = @con.query 'SELECT COUNT(*) FROM ' + tabelle + ';'
    id = 0
    res.each {|e| id = e[0].to_i + 1}
    return id
  end
end