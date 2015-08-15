require 'slop'
require_relative 'verwaltung'

args = Slop.parse { |o|
  o.string '-a', '--author', 'the author to search for'
  o.string '-s', '--speaker', 'the speaker to search for'
  o.string '-t', '--title', 'the title to search for'
  o.string '-f', '--format', 'output format. Available variables: %id, %t (title), %a (author), %s (speaker), %p (path).'
  o.array '-i', '--insert', 'insert new audiobook into database; title,author,speaker,path (NO spaces)'
  o.on '-h', '--help', 'display this help' do
    puts o
  end
  o.bool '-cdb', '--clear-db', 'clear whole databse'
  }

verw = Verwaltung.new

if args[:author]
  res = verw.suche_autor args[:author]
  res.each {|e| puts e.to_s }
end

if args[:title]
  res = verw.suche_titel args[:title]
  res.each {|e| puts e.to_s}
end

if args[:speaker]
  res = verw.suche_sprecher args[:speaker]
  res.each {|e| puts e.to_s }
end

if args[:cdb]
  verw.clear_tables
  puts "alles tot"
end


ins = args[:insert]
if ins.length > 0
  hb = Hoerbuch.new 0, 'titel', ['autor'], 'pfad', ['sprecher']
  verw.hoerbuch_einfuegen hb
end