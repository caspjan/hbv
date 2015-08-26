require_relative 'require'

class DBCon
  def initialize einst
    @einst = einst
    @con = Mysql.new @einst.host, @einst.user, @einst.passwd, @einst.db
  end
  
  def s i
    i.to_s
  end
  
  def get_hb_id hb_id
    @con.query 'SELECT * FROM hoerbuecher WHERE id=' + s(hb_id) + ';'
  end
  
  def get_titel_id titel_id
    @con.query 'SELECT * FROM titel WHERE id=' + s(titel_id) + ';'
  end
  
  def get_bewertung_id bw_id
    @con.query 'SELECT * FROM bewertung WHERE id=' + s(bw_id) + ';'
  end
  
  def get_pfad_id pfad_id
    @con.query 'SELECT * FROM pfad WHERE id=' + s(pfad_id) + ';'
  end
  
  def get_autor_zw_hb hb_id
    @con.query 'SELECT * FROM autoren WHERE hoerbuch=' + s(hb_id) + ';'
  end
  
  def get_autor_id autor_id
    @con.query 'SELECT * FROM autor WHERE id=' + s(autor_id) + ';'
  end
  
  def get_sprecher_zw_hb hb_id
    @con.query 'SELECT * FROM sprechers WHERE hoerbuch=' + s(hb_id) + ';'
  end
  
  def get_sprecher_zw_sprecher sprecher_id
    @con.query 'SELECT * FROM sprechers WHERE sprecher=' + s(sprecher_id) + ';'
  end
  
  def get_sprecher_id sprecher_id
    @con.query 'SELECT * FROM sprecher WHERE id=' + s(sprecher_id) + ';'
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
  
  def suche_sprecher speaker
    @con.query "SELECT * FROM sprecher WHERE sprecher LIKE '%" + s(speaker) + "%';"
  end
  
  def suche_autor author
    @con.query "SELECT * FROM autor WHERE autor LIKE '%" + s(author) + "%';"
  end
  
  def get_autor_zw_autor author_id
    @con.query 'SELECT * FROM autoren WHERE autor=' + s(author_id) + ';'
  end
  
  def suche_titel title
    @con.query "SELECT * FROM titel WHERE titel LIKE '%" + s(title) + "%';"
  end
  
  def get_hb_titel_id title_id
    @con.query "SELECT * FROM hoerbuecher WHERE titel=" + s(title_id) + ";"
  end
  
  def get_datei_zw_hb hb_id
    @con.query 'SELECT * FROM dateien WHERE hoerbuch=' + s(hb_id) + ';'
  end
  
  def get_datei file_id
    @con.query 'SELECT * FROM datei WHERE id=' + s(file_id) + ';'
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
    res = @con.query 'SHOW TABLE STATUS FROM ' + @einst.db + ' WHERE Name="' + table + '";'
    id = 0
    res.each_hash {|e| id = e['Auto_increment'].to_i}
    return id
  end
  
  def clean_file_table table
    #alles einlesen
    res = @con.query 'SELECT * FROM ' + table
    res.each_hash {|e|
      exists = false
      #überprüfen, ob die id des whatever in der tabelle datei steht
      datei = @con.query 'SELECT * FROM datei WHERE ' + table + '=' + e['id'] + ';'
      datei.each {|f| exists = true}
      #wenn nicht, loschen
      if !exists
        #löschen
        @con.query 'DELETE FROM ' + table + ' WHERE id=' + e['id'] + ';'
      end
    }
  end
  
  def clean_zw_table table
    #alles einlesen
    res = @con.query 'SELECT * FROM ' + table
    res.each_hash {|e|
      zw_table = 'sprechers' if table.eql? 'sprecher'
      zw_table = 'autoren' if table.eql? 'autor'
      exists = false
      #überprüfen, ob die id in der zwischentabelle steht
      verkn = @con.query 'SELECT * FROM ' + zw_table + ' WHERE ' + table + '=' + e['id'] + ';'
      verkn.each {|f| exists = true}
      #wenn nicht, loschen
      if !exists
        #löschen
        @con.query 'DELETE FROM sprecher WHERE id=' + e['id'] + ';'
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
  
  def remove_file file_id
    @con.query 'DELETE FROM datei WHERE id=' + file_id + ';'
  end
  
  def remove_path path_id
    @con.query 'DELETE FROM pfad WHERE id=' + path_id + ';'
  end
  
  def remove_title title
    @con.query 'DELETE FROM titel WHERE id=' + title + ';'
  end
  
  def remove_zw_hb hb_id, table
    @con.query 'DELETE FROM ' + table + ' WHERE hoerbuch=' + hb_id + ';'
  end
  
  def remove_hb_id hb_id
    @con.query 'DELETE FROM hoerbuecher WHERE id=' + hb_id + ';'
  end
end