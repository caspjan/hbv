require_relative 'hoerbuch'
require_relative 'verwaltung'
require_relative 'einstellung_parser'

verw = Verwaltung.new
verw.hoerbuch_einfuegen Hoerbuch.new 0, 'der titel', 'Jan', '/home/jan/ttel', 'Jan Sprecher'