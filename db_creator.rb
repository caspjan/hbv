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
    @con.query "CREATE TABLE `Autor` (
      `idAutor` int(11) NOT NULL AUTO_INCREMENT,
      `name` varchar(45) DEFAULT NULL,
      PRIMARY KEY (`idAutor`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8"
    @con.query "CREATE TABLE `Sprecher` (
      `idSprecher` int(11) NOT NULL AUTO_INCREMENT,
      `name` varchar(45) NOT NULL,
      PRIMARY KEY (`idSprecher`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8"
    @con.query "CREATE TABLE `Tag` (
      `idTag` int(11) NOT NULL AUTO_INCREMENT,
      `tag` varchar(100) NOT NULL,
      PRIMARY KEY (`idTag`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8"
    @con.query "CREATE TABLE `Hoerbuch` (
      `idHoerbuch` int(11) NOT NULL AUTO_INCREMENT,
      `pfad` varchar(500) NOT NULL,
      `bewertung` varchar(45) DEFAULT NULL,
      `titel` varchar(100) NOT NULL,
      `position` int(11) DEFAULT '0',
      PRIMARY KEY (`idHoerbuch`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8"
    @con.query "CREATE TABLE `Tag_has_Hoerbuch` (
      `Tag_idTag` int(11) NOT NULL,
      `Hoerbuch_idHoerbuch` int(11) NOT NULL,
      PRIMARY KEY (`Tag_idTag`,`Hoerbuch_idHoerbuch`),
      KEY `fk_Tag_has_Hoerbuch_Hoerbuch1_idx` (`Hoerbuch_idHoerbuch`),
      KEY `fk_Tag_has_Hoerbuch_Tag1_idx` (`Tag_idTag`),
      CONSTRAINT `fk_Tag_has_Hoerbuch_Hoerbuch1` FOREIGN KEY (`Hoerbuch_idHoerbuch`) REFERENCES `Hoerbuch` (`idHoerbuch`) ON DELETE NO ACTION ON UPDATE NO ACTION,
      CONSTRAINT `fk_Tag_has_Hoerbuch_Tag1` FOREIGN KEY (`Tag_idTag`) REFERENCES `Tag` (`idTag`) ON DELETE NO ACTION ON UPDATE NO ACTION
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8"
    @con.query "CREATE TABLE `Autor_has_Hoerbuch` (
      `Autor_idAutor` int(11) NOT NULL,
      `Hoerbuch_idHoerbuch` int(11) NOT NULL,
      PRIMARY KEY (`Autor_idAutor`,`Hoerbuch_idHoerbuch`),
      KEY `fk_Autor_has_Hoerbuch_Hoerbuch1_idx` (`Hoerbuch_idHoerbuch`),
      KEY `fk_Autor_has_Hoerbuch_Autor_idx` (`Autor_idAutor`),
      CONSTRAINT `fk_Autor_has_Hoerbuch_Autor` FOREIGN KEY (`Autor_idAutor`) REFERENCES `Autor` (`idAutor`) ON DELETE CASCADE ON UPDATE NO ACTION,
      CONSTRAINT `fk_Autor_has_Hoerbuch_Hoerbuch1` FOREIGN KEY (`Hoerbuch_idHoerbuch`) REFERENCES `Hoerbuch` (`idHoerbuch`) ON DELETE NO ACTION ON UPDATE NO ACTION
     ) ENGINE=InnoDB DEFAULT CHARSET=utf8"
    @con.query "CREATE TABLE `Sprecher_has_Hoerbuch` (
      `Hoerbuch_idHoerbuch` int(11) NOT NULL,
      `Sprecher_idSprecher` int(11) NOT NULL,
      PRIMARY KEY (`Hoerbuch_idHoerbuch`,`Sprecher_idSprecher`),
      KEY `fk_Hoerbuch_has_Sprecher_Sprecher1_idx` (`Sprecher_idSprecher`),
      KEY `fk_Hoerbuch_has_Sprecher_Hoerbuch1_idx` (`Hoerbuch_idHoerbuch`),
      CONSTRAINT `fk_Hoerbuch_has_Sprecher_Hoerbuch1` FOREIGN KEY (`Hoerbuch_idHoerbuch`) REFERENCES `Hoerbuch` (`idHoerbuch`) ON DELETE NO ACTION ON UPDATE NO ACTION,
      CONSTRAINT `fk_Hoerbuch_has_Sprecher_Sprecher1` FOREIGN KEY (`Sprecher_idSprecher`) REFERENCES `Sprecher` (`idSprecher`) ON DELETE CASCADE ON UPDATE NO ACTION
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8"
    @con.query "CREATE TABLE `Format` (
      `idFormat` int(11) NOT NULL AUTO_INCREMENT,
      `Hoerbuch_idHoerbuch` int(11) NOT NULL,
      `format` varchar(45) NOT NULL,
      PRIMARY KEY (`idFormat`,`Hoerbuch_idHoerbuch`),
      KEY `fk_Format_Hoerbuch1_idx` (`Hoerbuch_idHoerbuch`),
      CONSTRAINT `fk_Format_Hoerbuch1` FOREIGN KEY (`Hoerbuch_idHoerbuch`) REFERENCES `Hoerbuch` (`idHoerbuch`) ON DELETE CASCADE ON UPDATE NO ACTION
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8"
    @con.query "CREATE TABLE `CD` (
      `idCD` int(11) NOT NULL AUTO_INCREMENT,
      `nummer` varchar(45) DEFAULT NULL,
      `pfad` varchar(500) DEFAULT NULL,
      `Format_idFormat` int(11) NOT NULL,
      PRIMARY KEY (`idCD`,`Format_idFormat`),
      KEY `fk_CD_Format1_idx` (`Format_idFormat`),
      CONSTRAINT `fk_CD_Format1` FOREIGN KEY (`Format_idFormat`) REFERENCES `Format` (`idFormat`) ON DELETE CASCADE ON UPDATE NO ACTION
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8"
    @con.query "CREATE TABLE `Datei` (
      `idDatei` int(11) NOT NULL AUTO_INCREMENT,
      `pfad` varchar(500) DEFAULT NULL,
      `CD_idCD` int(11) NOT NULL,
      `nummer` varchar(45) NOT NULL,
      `groesse` int(11) NOT NULL,
      `laenge` int(11) NOT NULL,
      PRIMARY KEY (`idDatei`,`CD_idCD`),
      KEY `fk_Datei_CD1_idx` (`CD_idCD`),
      CONSTRAINT `fk_Datei_CD1` FOREIGN KEY (`CD_idCD`) REFERENCES `CD` (`idCD`) ON DELETE CASCADE ON UPDATE NO ACTION
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8"
    
  end
end