class Einstellung
  attr_accessor :host
  attr_accessor :user
  attr_accessor :passwd
  attr_accessor :db
  attr_accessor :format
  attr_accessor :datei_format
  attr_accessor :datei_groesse
  
  def to_s
    return 'dbhost=' + @host, 'dbuser=' + @user, 'dbpasswd=' + @passwd, 'dbname=' + @db
  end
end