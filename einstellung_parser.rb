require_relative 'einstellung'

class Einstellung_Parser
  attr_reader :einst
  def initialize pfad
    @einst = Einstellung.new
    @datei = File.new pfad, "r"
    
    @datei.each {|e|
      #zeilenumbruch vom String entfernen
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
        when 'format'
          @einst.format = f[1]
        when 'datei_format'
          @einst.datei_format = f[1]
        when 'datei_groesse'
          @einst.datei_groesse = f[1]
        when 'datei_endungen'
          @einst.datei_endungen = f[1].split ','
          #punkt vor endung einfuegen
          @einst.datei_endungen.map! {|g|
            g.chomp!
            g.prepend '.'
          }
        when 'hb_groesse'
          @einst.hb_groesse = f[1]
        when 'stats_format'
          @einst.stats_format = f[1]
        when 'player'
          @einst.player = f[1]
        when 'basedir'
          if !f[1].end_with? '/'
            @einst.basedir = f[1] + '/'
          else
            @einst.basedir = f[1]
          end
        end
      end
      }
  end
end