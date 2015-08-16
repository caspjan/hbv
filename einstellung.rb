class Einstellung
  attr_accessor :host
  attr_accessor :user
  attr_accessor :passwd
  attr_accessor :db
  attr_accessor :format
  
  def to_s
    return 'dbhost=' + @host, 'dbuser=' + @user, 'dbpasswd=' + @passwd, 'dbname=' + @db
  end
end