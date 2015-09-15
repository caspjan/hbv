class DB_Creator
  def initialize einst
    @einst = einst
    @con = Mysql.new @einst.host, @einst.user, @einst.passwd
  end
  
  def create_db
    @con.query 'CREATE DATABASE IF NOT EXISTS ' + @einst.db + ';'
  end
  
  def create_tables
    @con.query 'USE ' + @einst.db
    @con.query 'CREATE TABLE `autor` (`id` int(11) NOT NULL AUTO_INCREMENT, `autor` text NOT NULL, UNIQUE KEY `id` (`id`)) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=latin1'
    @con.query 'CREATE TABLE `autoren` (`hoerbuch` int(11) NOT NULL, `autor` int(11) NOT NULL) ENGINE=InnoDB DEFAULT CHARSET=latin1'
    @con.query 'CREATE TABLE `hoerbuecher` (`id` int(11) NOT NULL AUTO_INCREMENT, `titel` int(11) NOT NULL, `pfad` int(11) NOT NULL, `position` INT(11) NOT NULL, `bewertung` INT(11) NOT NULL, UNIQUE KEY `id_2` (`id`), KEY `id` (`id`)) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=latin1'
    @con.query 'CREATE TABLE `pfad` (`id` int(11) NOT NULL AUTO_INCREMENT, `pfad` text NOT NULL, UNIQUE KEY `id` (`id`)) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=latin1'
    @con.query 'CREATE TABLE `sprecher` (`id` int(11) NOT NULL AUTO_INCREMENT, `sprecher` text NOT NULL, UNIQUE KEY `id` (`id`)) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=latin1'
    @con.query 'CREATE TABLE `sprechers` (`hoerbuch` int(11) NOT NULL, `sprecher` int(11) NOT NULL) ENGINE=InnoDB DEFAULT CHARSET=latin1'
    @con.query 'CREATE TABLE `titel` (`id` int(1) NOT NULL AUTO_INCREMENT, `titel` text NOT NULL, UNIQUE KEY `id` (`id`)) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=latin1'
    @con.query 'CREATE TABLE `bewertung` (`id` int(11) NOT NULL AUTO_INCREMENT, `bewertung` int(11) NOT NULL, PRIMARY KEY (`id`)) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=latin1'
    @con.query 'CREATE TABLE `datei` ( `id` int(11) NOT NULL AUTO_INCREMENT, `pfad` text NOT NULL, `titel` text NOT NULL, `laenge` int(11) NOT NULL, `groesse` int(11) NOT NULL, `interpret` int(11) NOT NULL, `jahr` int(11) NOT NULL, `genre` int(11) NOT NULL, `album` int(11) NOT NULL, `nummer` int(11) NOT NULL, PRIMARY KEY (`id`), UNIQUE KEY `id` (`id`), KEY `id_2` (`id`)) ENGINE=InnoDB DEFAULT CHARSET=latin1'
    @con.query 'CREATE TABLE `dateien` ( `hoerbuch` int(11) NOT NULL, `datei` int(11) NOT NULL, UNIQUE KEY `cd` (`hoerbuch`,`datei`)) ENGINE=InnoDB DEFAULT CHARSET=latin1'
    @con.query 'CREATE TABLE `datei_album` ( `id` int(11) NOT NULL AUTO_INCREMENT, `album` int(11) NOT NULL, PRIMARY KEY (`id`), UNIQUE KEY `id` (`id`), KEY `id_2` (`id`)) ENGINE=InnoDB DEFAULT CHARSET=latin1'
    @con.query 'CREATE TABLE `datei_genre` ( `id` int(11) NOT NULL AUTO_INCREMENT, `genre` int(11) NOT NULL, PRIMARY KEY (`id`), UNIQUE KEY `id` (`id`), KEY `id_2` (`id`)) ENGINE=InnoDB DEFAULT CHARSET=latin1'
    @con.query 'CREATE TABLE `datei_interpret` ( `id` int(11) NOT NULL AUTO_INCREMENT, `interpret` text NOT NULL, PRIMARY KEY (`id`), UNIQUE KEY `id` (`id`), KEY `id_2` (`id`)) ENGINE=InnoDB DEFAULT CHARSET=latin1'
    @con.query 'CREATE TABLE `datei_jahr` ( `id` int(11) NOT NULL AUTO_INCREMENT, `jahr` int(11) NOT NULL, PRIMARY KEY (`id`), UNIQUE KEY `id` (`id`), KEY `id_2` (`id`)) ENGINE=InnoDB DEFAULT CHARSET=latin1'
  end
end