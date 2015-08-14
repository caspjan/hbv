require 'mysql'
require_relative 'einstellung_parser'

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
      hb.titel.map! { |t| t[2]}
      hb.sprecher.map! { |s| s[2]}
      hb.autor.map! { |a| a[2]}
      hb.pfad.map! { |p| p[2]}
    }
    return hbs
  end
end