require_relative 'einstellung'

class Einstellung_Parser
  attr_reader :einst
  def initialize pfad
    @einst = Einstellung.new
    @datei = File.new pfad, "r"
    
    @datei.each {|e|
      e.chomp!
      #kommentar ignorieren
      if !e.start_with? '#'
        f = e.split '='
        case f[0]
        when 'dbhost'
          @einst.host = f[1]
        when 'dbname'
          @einst.db = f[1]
        when 'dbuser'
          @einst.user = f[1]
        when 'dbpasswd'
          @einst.passwd = f[1]
        end
      end
      }
  end
end