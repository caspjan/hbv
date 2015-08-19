require_relative 'require'

class Pfad_Parser
  attr_reader :dateien
  def initialize hb_ordner, einst
    @ordner = hb_ordner
    @einst = einst
  end
  
  def parse
    p = Pathname.new @ordner
    #sind die dateien in cd ordnern, oder einfach lose?
    anz_ges = p.children.count
    cd_count = 0
    p.children.each {|e| 
      o = e.to_s.split '/'
      d = o[-1]
      ['CD', 'cd', 'Cd', 'cD'].each {|f|
        if d.start_with? f
          cd_count += 1
        end
      }
    }
    dateien = Array.new
    if cd_count > anz_ges - 3
      #die dateien aus jedem unterordner in ein array schieben, sortiert nach name
      subfolders = Array.new
      p.children.each {|e| subfolders << e }
      #array sortieren
      subfolders.sort!
      subfolders.each {|e|
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
        #dateien sortieren und sie dem grossen array anhängen
        dateien_tmp.sort!
        dateien += dateien_tmp
        dateien_tmp.clear
      }
    else
      #alle dateien im ordner in das array schieben und sortieren
      p.children.each {|e|
        @einst.datei_endungen.each {|g|
          if e.extname.eql? g
            dateien << e
          end
        }
      }
    end
    return dateien
  end
end