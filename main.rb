require_relative 'hoerbuch'
require_relative 'verwaltung'
require_relative 'einstellung_parser'

verw = Verwaltung.new
res = verw.suche_autor "Lina"
res.each {|e| puts e.to_s}