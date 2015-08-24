require_relative 'require'

class DBCon
  def initialize einst
    @einst = einst
    #begin
      @con = Mysql.new @einst.host, @einst.user, @einst.passwd, @einst.db
    #rescue Mysql::Error
      #@con = Mysql.new @einst.host, @einst.user, @einst.passwd
      #raise Datenbank_nicht_da
    #end
  end
  
end