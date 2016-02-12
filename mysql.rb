require_relative 'require'

class DBCon
  def initialize einst
    @einst = einst
    @con = Mysql.new @einst.host, @einst.user, @einst.passwd, @einst.db
  end
  
  def s i
    i.to_s.dup.force_encoding(Encoding::UTF_8)
  end
  
  def i s
    s.to_i
  end
  
  def get_hb hb_id
    #autoren holen
    autoren = Array.new
    res = @con.query "SELECT name FROM Autor,Hoerbuch,Autor_has_Hoerbuch where Hoerbuch.idHoerbuch = " + s(hb_id) + " and Hoerbuch.idHoerbuch = Autor_has_Hoerbuch.Hoerbuch_idHoerbuch and Autor.idAutor = Autor_has_Hoerbuch.Autor_idAutor;"
    res.each_hash {|aut|
      autoren << s(aut['name'])
    }
    #sprecher holen
    sprecher = Array.new
    res = @con.query "SELECT name FROM Sprecher,Hoerbuch,Sprecher_has_Hoerbuch where Hoerbuch.idHoerbuch = " + s(hb_id) + " and Hoerbuch.idHoerbuch = Sprecher_has_Hoerbuch.Hoerbuch_idHoerbuch and Sprecher.idSprecher = Sprecher_has_Hoerbuch.Sprecher_idSprecher;"
    res.each_hash {|spr|
      sprecher << s(spr['name'])
    }
    
    #tags holen
    tags = Array.new
    res = @con.query "SELECT Tag.tag FROM Tag,Tag_has_Hoerbuch,Hoerbuch where Hoerbuch.idHoerbuch = " + s(hb_id) + " and Hoerbuch.idHoerbuch = Tag_has_Hoerbuch.Hoerbuch_idHoerbuch and Tag.idTag = Tag_has_Hoerbuch.Tag_idTag;"
    res.each_hash {|tag|
      tags << s(tag['tag'])
    }
    
    #rest holen
    hb = Hoerbuch.new 0, nil, autoren, sprecher, nil, nil, tags
    res = @con.query "SELECT Hoerbuch.idHoerbuch as id,Hoerbuch.titel as titel,Hoerbuch.pfad as pfad,Hoerbuch.bewertung as bw from Hoerbuch where Hoerbuch.idHoerbuch = " + s(hb_id)

    res.each_hash {|e|
      hb.titel = e['titel']
      hb.id = e['id']
      hb.pfad = e['pfad']
      hb.bewertung = e['bw']
    }
    if hb.id.eql? 0
      return nil
    else
      return hb
    end
  end
  
  def get_hb_laenge hb_id
    res = @con.query 'SELECT sum(D.laenge) AS laenge FROM Datei D,CD,Format F,Hoerbuch H where D.CD_idCD = CD.idCD and CD.Format_idFormat = F.idFormat and F.Hoerbuch_idHoerbuch = H.idHoerbuch and H.idHoerbuch = ' + s(hb_id)
    res.each_hash {|e|
      return e['laenge']
    }
  end

  def get_hb_size hb_id
    formate = Hash.new
    res = @con.query 'SELECT sum(D.groesse) AS size, F.format as format FROM Datei D,CD,Format F,Hoerbuch H where D.CD_idCD = CD.idCD and CD.Format_idFormat = F.idFormat and F.Hoerbuch_idHoerbuch = H.idHoerbuch and H.idHoerbuch = ' + s(hb_id) + ' group by F.idFormat'
    res.each_hash {|e|
      formate[e['format']] = e['size']
    }
    return formate
  end
  
  def full_dump
    hbs = Array.new
    #alle ids der hörbücher holen
    res = @con.query "SELECT Hoerbuch.idHoerbuch AS id FROM Hoerbuch"
    res.each_hash {|e|
      hbs << get_hb(e['id'])
    }
    return hbs
  end
  
  def clear_tables
    @con.query 'SET FOREIGN_KEY_CHECKS = 0'
    @con.query 'TRUNCATE TABLE Autor_has_Hoerbuch'
    @con.query 'TRUNCATE TABLE Sprecher_has_Hoerbuch'
    @con.query 'TRUNCATE TABLE Autor'
    @con.query 'TRUNCATE TABLE Sprecher'
    @con.query 'TRUNCATE TABLE Datei'
    @con.query 'TRUNCATE TABLE CD'
    @con.query 'TRUNCATE TABLE Format'
    @con.query 'TRUNCATE TABLE Tag'
    @con.query 'TRUNCATE TABLE Tag_has_Hoerbuch'
    @con.query 'TRUNCATE TABLE Hoerbuch'
    @con.query 'SET FOREIGN_KEY_CHECKS = 1'
  end
  
  def gibt_wert? tabelle, spalte, wert
    #puts "SELECT * FROM " + tabelle + " WHERE " + spalte + "='" + wert.to_s + "';"
    result = @con.query "SELECT * FROM " + tabelle + " WHERE " + spalte + "='" + wert.to_s + "';"
    id = -1
    id_name = "id" + tabelle
    result.each_hash {|e| id = e[id_name]}
    if id == -1
        return false
    else
      return id
    end
  end
  
  def suche_sprecher speaker
    #ids der hoerbucher holen
    res = @con.query "SELECT Hoerbuch.idHoerbuch as id from Sprecher,Hoerbuch,Sprecher_has_Hoerbuch where Sprecher.name LIKE '%" + s(speaker) + "%' and Sprecher.idSprecher = Sprecher_has_Hoerbuch.Sprecher_idSprecher and Hoerbuch.idHoerbuch = Sprecher_has_Hoerbuch.Hoerbuch_idHoerbuch;"
    
    hbs = Array.new
    res.each_hash {|hb|
      hbs << get_hb(hb['id'])
    }
    return hbs
  end
  
  def suche_autor author
    #ids der hoerbucher holen
    res = @con.query "SELECT Hoerbuch.idHoerbuch as id from Autor,Hoerbuch,Autor_has_Hoerbuch where Autor.name LIKE '%" + s(author) + "%' and Autor.idAutor = Autor_has_Hoerbuch.Autor_idAutor and Hoerbuch.idHoerbuch = Autor_has_Hoerbuch.Hoerbuch_idHoerbuch;"
    
    hbs = Array.new
    res.each_hash {|hb|
      hbs << get_hb(hb['id'])
    }
    return hbs
  end
  
  def suche_tag tag
    #ids der hoerbucher holen
    res = @con.query "SELECT Hoerbuch.idHoerbuch as id from Tag,Hoerbuch,Tag_has_Hoerbuch where Tag.tag LIKE '%" + s(tag) + "%' and Tag.idTag = Tag_has_Hoerbuch.Tag_idTag and Hoerbuch.idHoerbuch = Tag_has_Hoerbuch.Hoerbuch_idHoerbuch;"
    
    hbs = Array.new
    res.each_hash {|hb|
      hbs << get_hb(hb['id'])
    }
    return hbs
  end
  
  def suche_bewertung bw
    #ids der hoerbucher holen
    res = @con.query "SELECT Hoerbuch.idHoerbuch as id from Hoerbuch where Hoerbuch.bewertung >= " + s(bw)
    
    hbs = Array.new
    res.each_hash {|hb|
      hbs << get_hb(hb['id'])
    }
    return hbs
  end
  
  def suche_titel title
    #ids der hoerbucher holen
    res = @con.query "SELECT Hoerbuch.idHoerbuch as id FROM Hoerbuch WHERE titel LIKE '%" + s(title) + "%';"
    
    hbs = Array.new
    res.each_hash {|hb|
      hbs << get_hb(hb['id'])
    }
    return hbs
  end
  
  def get_dateien format_id
    dateien = Array.new
    res = @con.query "SELECT D.pfad as pfad, D.nummer as nummer ,D.laenge as laenge ,D.groesse as groesse from Datei D, CD, Format F where F.idFormat = " + s(format_id) + " and CD.Format_idFormat = F.idFormat and D.CD_idCD = CD.idCD"
    res.each_hash {|d|
      dateien << Datei.new(d['nummer'], d['pfad'], d['laenge'], d['groesse'])
    }
    return dateien
  end
  
  #def get_dateien_komplett hb_id
  #  dateien_tmp = Array.new
  #  dateien = Hash.new
  #  format_res = @con.query "SELECT Format.idFormat as id, Format.format as f FROM Format where Format.Hoerbuch_idHoerbuch = " + s(hb_id) + ";"
  #  format_res.each_hash {|format|
  #    #für jedes format die dateien holen
  #    dateien_res = @con.query "SELECT D.pfad as pfad, D.nummer as nummer ,D.laenge as laenge ,D.groesse as groesse from Datei D, CD, Format F where F.idFormat = " + s(format['id']) + " and CD.Format_idFormat = F.idFormat and D.CD_idCD = CD.idCD"
  #    dateien_res.each_hash {|d|
  #      dateien_tmp << Datei.new(d['nummer'], d['pfad'], d['laenge'], d['groesse'])
  #    }
  #    dateien[format['f']] = dateien_tmp
  #    dateien_tmp.clear
  #  }
  #  return dateien
  #end
  
  def get_format_id hb_id, format
    fid = nil
    res = @con.query "SELECT Format.idFormat as id from Format where Format.format = '" + s(format) + "' and Format.Hoerbuch_idHoerbuch = " + s(hb_id)
    res.each_hash {|e|
      fid = i(e['id'])
    }
    return fid
  end
  
  def get_interpret interpret_id
    @con.query 'SELECT * FROM datei_interpret WHERE id=' + s(interpret_id) + ';'
  end
  
  def get_album album_id
    @con.query 'SELECT * FROM datei_album WHERE id=' + s(album_id) + ';'
  end
  
  def get_jahr year_id
    @con.query 'SELECT * FROM datei_jahr WHERE id=' + s(year_id) + ';'
  end
  
  def get_genre genre_id
    @con.query 'SELECT * FROM datei_genre WHERE id=' + s(genre_id) + ';'
  end
  
  def get_bewertung bw
    @con.query 'SELECT * FROM bewertung WHERE bewertung=' + s(bw) + ';'
  end
  
  def get_hb_bw_id bw_id
    @con.query 'SELECT * FROM hoerbuecher WHERE bewertung=' + s(bw_id) + ';'
  end
  
  def calc_next_id table
    res = @con.query 'SHOW TABLE STATUS FROM ' + s(@einst.db) + ' WHERE Name="' + s(table) + '";'
    id = 0
    res.each_hash {|e| id = e['Auto_increment'].to_i}
    return id
  end
  
  def get_autoren
    autoren = Hash.new
    res = @con.query "SELECT Autor.name as name,COUNT(Autor_has_Hoerbuch.Hoerbuch_idHoerbuch) as anz FROM Autor,Autor_has_Hoerbuch WHERE Autor_has_Hoerbuch.Autor_idAutor = Autor.idAutor GROUP BY Autor_has_Hoerbuch.Autor_idAutor ORDER BY name;"
    res.each_hash {|e|
      autoren[e['name']] = e['anz']
    }
    return autoren
  end
  
  def get_sprecher
    sprecher = Hash.new
    res = @con.query "SELECT Sprecher.name as name,COUNT(Sprecher_has_Hoerbuch.Hoerbuch_idHoerbuch) as anz FROM Sprecher,Sprecher_has_Hoerbuch WHERE Sprecher_has_Hoerbuch.Sprecher_idSprecher = Sprecher.idSprecher GROUP BY Sprecher_has_Hoerbuch.Sprecher_idSprecher ORDER BY name;"
    res.each_hash {|e|
      sprecher[e['name']] = e['anz']
    }
    return sprecher
  end
  
  def get_stats
    stats = Stats.new
    #anzahl der hoerbücher
    res = @con.query "SELECT COUNT(idHoerbuch) as anz FROM Hoerbuch;"
    res.each_hash {|e|
      stats.hb_ges = e['anz']
    }
    
    #anzahl der dateien
    res = @con.query "SELECT COUNT(idDatei) as anz FROM Datei;"
    res.each_hash {|e|
      stats.dateien_ges = e['anz']
    }
    
    #gesamtgroesse aller dateien
    res = @con.query "SELECT SUM(Datei.groesse) as gr FROM Datei;"
    res.each_hash {|e|
      stats.size_ges = e['gr']
    }
    
    #gesamtlange aller dateien
    res = @con.query "SELECT SUM(Datei.laenge) as le FROM Datei;"
    res.each_hash {|e|
      stats.laenge_ges = e['le']
    }
    
    #durchschnittliche Bewertung
    res = @con.query "SELECT AVG(Hoerbuch.bewertung) as bw FROM Hoerbuch;"
    res.each_hash {|e|
      stats.bw_avg = e['bw']
    }
    
    #anzahl aller tags
    res = @con.query "SELECT COUNT(Tag.idTag) as tags FROM Tag"
    res.each_hash {|e|
      stats.tags_ges = e['tags']
    }
    
    #Durchschnittliche Anzahl der Autoren pro Hoerbuch
    res = @con.query "SELECT AVG(a.res) as avg_aut FROM (SELECT COUNT(Autor_idAutor) AS res FROM Autor_has_Hoerbuch,Hoerbuch WHERE Hoerbuch.idHoerbuch = Autor_has_Hoerbuch.Hoerbuch_idHoerbuch GROUP BY Hoerbuch.idHoerbuch) a;"
    res.each_hash {|e|
      stats.avg_autoren_pro_hb = e['avg_aut']
    }
    
    #Durchschnittliche Anzahl der Sprecher pro Hoerbuch
    res = @con.query "SELECT AVG(a.res) as avg_spr FROM (SELECT COUNT(Sprecher_idSprecher) AS res FROM Sprecher_has_Hoerbuch,Hoerbuch WHERE Hoerbuch.idHoerbuch = Sprecher_has_Hoerbuch.Hoerbuch_idHoerbuch GROUP BY Hoerbuch.idHoerbuch) a;"
    res.each_hash {|e|
      stats.avg_sprecher_pro_hb = e['avg_spr']
    }
    
    #Durchschnittliche Anzahl der Tags pro Hoerbuch
    res = @con.query "SELECT AVG(a.res) as avg_tag FROM (SELECT COUNT(Tag_idTag) AS res FROM Tag_has_Hoerbuch,Hoerbuch WHERE Hoerbuch.idHoerbuch = Tag_has_Hoerbuch.Hoerbuch_idHoerbuch GROUP BY Hoerbuch.idHoerbuch) a;"
    res.each {|e|
      stats.avg_tags_pro_hb = e[0]
    }
    
    #Durchschnittliche Anzahl Hoerbuecher pro Autor
    res = @con.query "SELECT AVG(a.res) as avg_hb_aut FROM (SELECT COUNT(Hoerbuch_idHoerbuch) AS res FROM Autor_has_Hoerbuch,Autor WHERE Autor.idAutor = Autor_has_Hoerbuch.Autor_idAutor GROUP BY Autor.idAutor) a;"
    res.each_hash {|e|
      stats.avg_hb_pro_autor = e['avg_hb_aut']
    }
    
    #Durchschnittliche Anzahl Hoerbuecher pro Sprecher
    res = @con.query "SELECT AVG(a.res) as avg_hb_spr FROM (SELECT COUNT(Hoerbuch_idHoerbuch) AS res FROM Sprecher_has_Hoerbuch,Sprecher WHERE Sprecher.idSprecher = Sprecher_has_Hoerbuch.Sprecher_idSprecher GROUP BY Sprecher.idSprecher) a;"
    res.each_hash {|e|
      stats.avg_hb_pro_sprecher = e['avg_hb_spr']
    }
    
    #Durchschnittliche Anzahl Hoerbuecher pro Tag
    res = @con.query "SELECT AVG(a.res) as avg_hb_tag FROM (SELECT COUNT(Hoerbuch_idHoerbuch) AS res FROM Tag_has_Hoerbuch,Tag WHERE Tag.idTag = Tag_has_Hoerbuch.Tag_idTag GROUP BY Tag.idTag) a;"
    res.each_hash {|e|
      stats.avg_hb_pro_tag = e['avg_hb_tag']
    }
    return stats
  end
  
  def update_sprecher hb_id, sprecher
    #alte sprecher aus der zwischentabelle löschen
    @con.query "DELETE FROM Sprecher_has_Hoerbuch where Hoerbuch_idHoerbuch = " + s(hb_id)
    #sprecher aufräumen
    clean_sprecher
    #für jeden sprecher schauen ob er schon existiert, wenn nicht neu anlegen
    sprecher.each {|e|
      gibt = false
      res = @con.query "SELECT Sprecher.idSprecher from Sprecher where name = '" + e + "';"
      res.each_hash {|f| gibt = true}
      if !gibt
        #Sprecher anlegen
        @con.query "INSERT INTO Sprecher(name) VALUES('" + e + "');"
      end
      #id des sprechers rausfinden, in die zwischentabelle schreiben
      @con.query "INSERT INTO Sprecher_has_Hoerbuch VALUES(" + s(hb_id) + ",(SELECT Sprecher.idSprecher FROM Sprecher WHERE Sprecher.name = '" + e + "'))"
    }
  end
  
  def update_autor hb_id, autor
    #alte autoren aus der zwischentabelle löschen
    @con.query "DELETE FROM Autor_has_Hoerbuch where Hoerbuch_idHoerbuch = " + s(hb_id)
    #autoren aufräumen
    clean_autoren
    #für jeden sprecher schauen ob er schon existiert, wenn nicht neu anlegen
    autor.each {|e|
      gibt = false
      res = @con.query "SELECT Autor.idAutor FROM Autor WHERE name = '" + e + "';"
      res.each_hash {|f| gibt = true}
      if !gibt
        #Sprecher anlegen
        @con.query "INSERT INTO Autor(name) VALUES('" + e + "');"
      end
      #id des sprechers rausfinden, in die zwischentabelle schreiben
      @con.query "INSERT INTO Autor_has_Hoerbuch VALUES((SELECT Autor.idAutor FROM Autor WHERE Autor.name = '" + e + "')," + s(hb_id) + ");"
      #@con.query "INSERT INTO Autor_has_Hoerbuch VALUES(" + s(hb_id) + ",(SELECT LAST_INSERT_ID());"
    }
  end
  
  def update_titel hb_id, titel
    @con.query "UPDATE Hoerbuch SET titel = '" + s(titel) + "' WHERE Hoerbuch.idHoerbuch = " + s(hb_id)
  end
  
  def add_tag hb_id, tag
    tag = s(tag)
    #gibts den tag schon? wenn ja id in die zwischentabelle schreiben, wenn nich neu anlegen
    gibt = false
    res = @con.query "SELECT Tag.idTag as id FROM Tag where tag='" + tag + "';"
    res.each_hash {|e| gibt = true}
    @con.query "INSERT INTO Tag(tag) VALUES('" + tag + "');" if !gibt
    @con.query "INSERT INTO Tag_has_Hoerbuch VALUES((SELECT Tag.idTag FROM Tag WHERE Tag.tag = '" + tag + "')," + s(hb_id) + ");"
  end

  def remove_tag hb_id, tag
    #tag aus zwischentabelle löschen
    @con.query "DELETE FROM Tag_has_Hoerbuch where Tag_has_Hoerbuch.Hoerbuch_idHoerbuch = '" + s(hb_id) + "' AND Tag_has_Hoerbuch.Tag_idTag = (SELECT Tag.idTag FROM Tag WHERE Tag.tag = '" + s(tag) + "');"
    #tags aufräumen
    clean_tags
  end
  
  def clean_autor
    @con.query 'DELETE FROM Autor WHERE idAutor NOT IN (SELECT Autor_has_Hoerbuch.Autor_idAutor FROM Autor_has_Hoerbuch);'
  end
  
  def clean_sprecher
    @con.query 'DELETE FROM Sprecher WHERE idSprecher NOT IN (SELECT Sprecher_has_Hoerbuch.Sprecher_idSprecher FROM Sprecher_has_Hoerbuch);'
  end
  
  def clean_autoren
    @con.query 'DELETE FROM Autor WHERE idAutor NOT IN (SELECT Autor_has_Hoerbuch.Autor_idAutor FROM Autor_has_Hoerbuch);'
  end
  
  def clean_tags
    @con.query 'DELETE FROM Tag WHERE idTag NOT IN (SELECT Tag_has_Hoerbuch.Tag_idTag FROM Tag_has_Hoerbuch)'
  end
  
  def remove_file file_id
    @con.query 'DELETE FROM datei WHERE id=' + s(file_id) + ';'
  end
  
  def remove_path path_id
    @con.query 'DELETE FROM pfad WHERE id=' + s(path_id) + ';'
  end
  
  def remove_title title
    @con.query 'DELETE FROM titel WHERE id=' + s(title) + ';'
  end
  
  def remove_zw_hb hb_id, table
    @con.query 'DELETE FROM ' + table + ' WHERE hoerbuch=' + s(hb_id) + ';'
  end
  
  def remove_hb hb_id
    #gibts die Autor(en) in noch nem andren Hoerbuch?
    res = @con.query "SELECT Autor_has_Hoerbuch.Autor_idAutor as autor FROM Autor_has_Hoerbuch WHERE Autor_has_Hoerbuch.Hoerbuch_idHoerbuch = " + s(hb_id)
    res.each_hash {|aut|
      #autor und hoerbuch aus zwischentabelle löschen
      @con.query "DELETE FROM Autor_has_Hoerbuch where Hoerbuch_idHoerbuch = " + s(hb_id) + " and Autor_idAutor = " + s(aut['autor'])
      #für jeden autor schauen, ob er noch irgendwo existiert
      hb_res = @con.query "SELECT Autor_has_Hoerbuch.Hoerbuch_idHoerbuch FROM Autor_has_Hoerbuch WHERE Autor_has_Hoerbuch.Autor_idAutor = " + aut['autor']
      gibt = false
      hb_res.each_hash {|e| gibt = true}
      if !gibt
        #Autor löschen
        @con.query "DELETE FROM Autor WHERE Autor.idAutor = " + s(aut['autor'])
      end
    }
    
    #gibts den Sprecher in noch nem andren Hoerbuch?
    res = @con.query "SELECT Sprecher_has_Hoerbuch.Sprecher_idSprecher as spr FROM Sprecher_has_Hoerbuch WHERE Sprecher_has_Hoerbuch.Hoerbuch_idHoerbuch = " + s(hb_id)
    res.each_hash {|spr|
      #sprecher und hoerbuch aus zwischentabelle löschen
      @con.query "DELETE FROM Sprecher_has_Hoerbuch where Hoerbuch_idHoerbuch = " + s(hb_id) + " and Sprecher_idSprecher = " + s(spr['spr'])
      #für jeden sprecher schauen, ob er noch irgendwo existiert
      hb_res = @con.query "SELECT Sprecher_has_Hoerbuch.Hoerbuch_idHoerbuch FROM Sprecher_has_Hoerbuch WHERE Sprecher_has_Hoerbuch.Sprecher_idSprecher = " + spr['spr']
      gibt = false
      hb_res.each_hash {|e| gibt = true}
      if !gibt
        #Autor löschen
        @con.query "DELETE FROM Sprecher WHERE Sprecher.idSprecher = " + s(spr['spr'])
      end
    }
    
    #gibts den Tag noch woanders?
    res = @con.query "SELECT Tag_has_Hoerbuch.Tag_idTag as tag FROM Tag_has_Hoerbuch WHERE Tag_has_Hoerbuch.Hoerbuch_idHoerbuch = " + s(hb_id)
    res.each_hash {|tag|
      #tag und hoerbuch aus zwischentabelle löschen
      @con.query "DELETE FROM Tag_has_Hoerbuch where Hoerbuch_idHoerbuch = " + s(hb_id) + " and Tag_idTag = " + s(tag['tag'])
      #für jeden tag schauen, ob er noch irgendwo existiert
      hb_res = @con.query "SELECT Tag_has_Hoerbuch.Hoerbuch_idHoerbuch FROM Tag_has_Hoerbuch WHERE Tag_has_Hoerbuch.Tag_idTag = " + s(tag['tag'])
      gibt = false
      hb_res.each_hash {|e| gibt = true}
      if !gibt
        #tag löschen
        @con.query "DELETE FROM Tag WHERE Tag.idTag = " + s(tag['tag'])
      end
    }
    
    @con.query "DELETE FROM Hoerbuch where Hoerbuch.idHoerbuch = " + s(hb_id)
  end
  
  def remove_formate hb_id
    @con.query "DELETE FROM Format where Hoerbuch_idHoerbuch = " + s(hb_id) + ";"
  end
  
  def count table
    @con.query 'SELECT COUNT(*) FROM ' + s(table)
  end
  
  def update col, val_new, val_old
    @con.query 'UPDATE ' + s(col) + ' SET ' + s(col) + '="' + s(val_new) + '" WHERE ' + s(col) + '="' + s(val_old) + '";'
  end
  
  def update_hb col, hb_id, val_new
    @con.query 'UPDATE hoerbuecher SET ' + s(col) + '=' + s(val_new) + ' WHERE id=' + s(hb_id) + ";"
  end
  
  def update_zw table, col, val_new, val_old, hb_id
    #puts 'UPDATE ' + s(table) + ' SET ' + s(col) + "='" + s(val_new) + "' WHERE hoerbuch=" + s(hb_id) + " AND " + s(col) + "=" + s(val_old) + ';'
    @con.query 'UPDATE ' + s(table) + ' SET ' + s(col) + "=" + s(val_new) + " WHERE hoerbuch=" + s(hb_id) + " AND " + s(col) + "=" + s(val_old) + ';'
  end
  
  def ins table, col, val
    pst = @con.prepare 'INSERT INTO ' + s(table) + '(' + s(col) + ') VALUES(?)'
    pst.execute s(val)
    #puts 'INSERT INTO ' + s(table) + '(' + s(col) + ') VALUES(' + s(val) + ')'
  end
  
  def ins_zw table, col1, col2, val1, val2
    #wird benutzt, um Autoren/Sprecher in die zwischentabelle zu schreiben
    #val2 ist das array mit den Autoren/Sprechern drin
    pst = @con.prepare 'INSERT INTO ' + s(table) + '(' + s(col1) + ',' + s(col2) + ') VALUES(?, ?)'
    val2.each {|e|
      #puts 'INSERT INTO ' + s(table) + '(' + s(col1) + ',' + s(col2) + ') VALUES(' + s(val1) + ',' + s(e) + ')'
      pst.execute val1, e
    }
  end
  
  def get table, col, val
    @con.query 'SELECT * FROM ' + s(table) + ' WHERE ' + s(col) + '="' + s(val) + '";'
  end
  
  def ins_hb title, path, rating
    pst = @con.prepare 'INSERT INTO Hoerbuch(titel, pfad, bewertung) VALUES(?, ?, ?)'
    pst.execute title, path, rating
    #id des hoerbuchs zurückgeben
    id_res = @con.query 'SELECT LAST_INSERT_ID();'
    hb_id = 0
    id_res.each {|e| hb_id = e[0]}
    return hb_id.to_i
  end
  
  def ins_file path, title, length, size, number, album, interpret, year, genre
    pst = @con.prepare 'INSERT INTO datei(pfad, titel, laenge, groesse, nummer, album, interpret, jahr, genre) VALUES(?, ?, ?, ?, ?, ?, ?, ?, ?)'
    pst.execute s(path), s(title), i(length), i(size), i(number), i(album), i(interpret), i(year), i(genre)
  end
  
  def ins_file_zw hb_id, file_id
    pst = @con.prepare 'INSERT INTO dateien(hoerbuch, datei) VALUES(?, ?)'
    pst.execute file_id, hb_id
  end
  
  def up_pos hb_id, pos
    @con.query 'UPDATE Hoerbuch SET position=' + s(pos) + ' WHERE idHoerbuch = ' + s(hb_id) + ';'
  end
  
  def get_last_pos hb_id
    pos = -1
    res = @con.query 'SELECT position as pos FROM Hoerbuch WHERE idHoerbuch=' + hb_id + ';'
    res.each_hash {|e|
      pos = e['pos']
    }
    return pos
  end
  
  def get_all table
    @con.query 'SELECT * FROM ' + table
  end
  
  def ins_format hoerbuch_id, format
    #format anlegen
    pst = @con.prepare 'INSERT INTO Format(Hoerbuch_idHoerbuch,format) VALUES(?,?)'
    pst.execute hoerbuch_id, format.format
    #id des formats bestimmen
    id_res = @con.query 'SELECT LAST_INSERT_ID();'
    format_id = 0
    id_res.each {|e| format_id = e[0].to_i}
    #puts format_id
    
    #cds anlegen
    #ueber die cds iterieren
    format.cds.each {|cd_akt|
      nummer = cd_akt.nummer
      pfad = cd_akt.pfad
      #cd in die datenbank schreiben
      pst = @con.prepare 'INSERT INTO CD(nummer,pfad,Format_IdFormat) VALUES(?,?,?)'
      pst.execute nummer, pfad, format_id
      #id der datei bestimmen
      id_res = @con.query 'SELECT LAST_INSERT_ID();'
      cd_id = 0
      id_res.each {|e| cd_id = e[0].to_i}
      
      #dateien anlegen
      #ueber die dateien iterieren
      cd_akt.dateien.each {|datei_akt|
        #datei in die datenbank schreiben
        pst = @con.prepare 'INSERT INTO Datei(nummer,pfad,CD_IdCD,groesse,laenge) VALUES(?,?,?,?,?)'
        pst.execute datei_akt.nummer, datei_akt.pfad, cd_id, datei_akt.groesse, datei_akt.laenge
      }
    }
  end
end