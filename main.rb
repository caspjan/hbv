require_relative 'hoerbuch'
require_relative 'verwaltung'
require_relative 'einstellung_parser'

verw = Verwaltung.new
puts verw.gibt_sprecher? 'Lina Sprecher'