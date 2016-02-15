require_relative 'require'

class Pfad_Parser
  attr_reader :dateien
  
  def initialize hb_ordner, einst
    @einst = einst
    @ordner = @einst.basedir + '/' + hb_ordner
  end
  
  def parse
    p = Pathname.new @ordner
    
    formate = Array.new
      #format bestimmen
      p.each_child {|format|
        if @einst.datei_endungen.include? format.basename.to_s.prepend "."
          if format.directory?
            format_tmp = Format.new format.basename.to_s
            #die dateien aus jedem unterordner in ein array schieben, sortiert nach name
            subfolders = Array.new
            #alle ordner unterhalb des format-Ordners in eine liste schieben
            format.each_child {|e| subfolders << e if e.directory?}
            #array sortieren
            subfolders.sort!
            subfolders.each_with_index {|e,i|
              #alle dateien im unterordner einlesen
              dateien_tmp = Array.new
              e.entries.each {|f|
                f = e.join f
                @einst.datei_endungen.each {|g|
                  if f.extname.eql? g
                    dateien_tmp << f
                  end
                }
              }
              #dateien sortieren
              dateien_tmp.sort!
              #fuer jeden pfad im dateien_tmp array ein Datei-Objekt erstellen
              dateien_obj_tmp = Array.new
              dateien_tmp.each_with_index {|pfad,nummer|
                dm = Datei_Meta_Parser.new pfad.to_s, nummer+1
                dateien_obj_tmp << dm.parse
              }
              
              #für jede Datei das Basisverzeichnis wieder entfernen
              dateien_obj_tmp.each {|f|
                f.pfad.gsub! @einst.basedir, ''
              }
              #nummer der CD ermitteln
              nummer = i+1
              #hoerbuch_id ist noch unbekannt
              hoerbuch_id = 0
              id = 0
              #neue CD anlegen
              cd_temp = CD.new id, nummer, hoerbuch_id, e.to_s.gsub(@einst.basedir, ''), format.to_s, dateien_obj_tmp
              format_tmp.add_cd cd_temp
            }
            formate << format_tmp
          end
        end
      }
    return formate
  end
end