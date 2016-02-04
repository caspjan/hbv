#!/bin/env ruby
require_relative 'require'

class Main
  def initialize
    @args = Slop.parse { |o|
    o.string '-a', '--author', 'the author to search for'
    o.string '-s', '--speaker', 'the speaker to search for'
    o.string '-t', '--title', 'the title to search for'
    o.integer '-b', '--rating', 'print all audiobooks with rating (0-10)'
    o.string '-tag', '--tag', 'the tag to search for'
    o.array '-i', '--insert', 'insert new audiobook into database; title,author:author2,speaker:speaker2,path,rating,tag1:tag2:tag3.. (NO spaces)'
    o.on '-h', '--help', 'display this help' do
      puts o
    end
    o.bool '-cdb', '--clear-db', 'clear whole database'
    o.bool '-f', '--force', "don't ask"
    o.string '-r', '--remove', '[id] remove audiobook from database'
    o.string '-id', '--get-id', '[id] get audiobook by id'
    o.bool '-fd', '--full-dump', 'print all Audiobooks in database'
    o.string '--files', 'print all files of the audiobook with given format. Example: --files mp3'
    o.bool '--init-db', 'create all needed tables'
    o.bool '--stats', 'print stats'
    o.bool '-ga', '--get-authors', 'print all authors and the number of audiobooks.'
    o.bool '-gs', '--get-speaker', 'print all speaker and the number of audiobooks.'
    o.bool '-gb', '--get-basedir', 'Basispfad der Hörbuchsammlung ausgeben'
    o.array '-ua', '--update-author', 'update the author of audiobook. First argument is the id of audiobook, second is the new authors.'
    o.array '-us', '--update-speaker', 'update the speaker of audiobook. First argument is the id of audiobook, second is the new speakers.'
    o.array '-ut', '--update-title', 'update the title of audiobook. First argument is the id of audiobook, second is the new title.'
    o.array '-up', '--update-path', 'update the path of audiobook. First argument is the id of audiobook, second is the new path.'
    o.array '-at', '--add-tag', 'add tag to audiobook. First arg is the id of audiobook, second is new tag'
    o.array '-rt', '--remove-tag', 'remove tag from audiobook. First arg is the id of audiobook, second is tag to remove'
    o.array '-p', '--play', 'play audiobook. Needs ID of audiobook, start and end. Example: "-p 1,0,3600": Play the first hour of the audiobook. Same as "-p 1,0,1h". Time can be in Hours (h), minutes (m). Standard is seconds. Example: "-p 1,1h23m45,5000". Same as "-p 1,1h23m45s,5000". * Can be used to mark the end: "-p 1,0,*". Plays from start to end. r means resume form last postion Example: "-p 1,r,*"'
    } 
    
    einst_pars = Einstellung_Parser.new '/home/jan/Dokumente/Programmierzeug/Hoerbuch/hoerbuch.conf'
    @einst = einst_pars.einst
    
    if @args[:'init-db']
      begin
        dbc = DB_Creator.new @einst
        dbc.create_db
        dbc.create_tables
        puts "done."
      rescue Mysql::Error => e
        if e.errno == 1044
          puts "Zugriff für User " + @einst.user + " verweigert."
          exit 1
        else
          puts e
        end
      end
    end
    
    @verw = Verwaltung.new @einst
    @ausg = Ausgabe.new @einst
    
    def sure?
      if @args[:force]
        return true
      end
      puts 'Are you sure? (Y/n)'
      r = STDIN.gets.chomp
      r.eql? 'Y' or r.eql? 'y'
    end
    
    def files? hb_id
      if @args[:files]
        @dateien = @verw.get_dateien(hb_id, @args[:files])
        return @dateien
      else
        return nil
      end
    end
    
    def size? hb_id
      if @einst.format.include? "%g"
        return @verw.get_hb_size hb_id
      else
        return nil
      end
    end
    
    def laenge? hb_id
      if @einst.format.include? "%l"
        return @verw.get_hb_laenge hb_id
      else
        return nil
      end
    end 
    
    if @args[:ga]
      @ausg.autoren_aus @verw.get_autoren
    end
    
    if @args[:gs]
      @ausg.sprecher_aus @verw.get_sprecher
    end
    
    if @args[:gb]
      puts @einst.basedir
    end
    
    
    if @args[:p]
      #checken, ob das array die richtige laenge hat
      p = @args[:p]
      if p.length == 3
        hb = @verw.get_hb p[0]
        if !hb.nil?     
          id = p[0]
          start = 0
          ende = 0
          2.times {|i| 
            #sekunden bestimmen
            i += 1
            if p[i].include? 'h' 
              teile = p[i].split 'h'
              sek = teile[0].to_i*3600
              h = true
            elsif p[i].include? 'H'
              teile = p[i].split 'H'
              sek = teile[0].to_i*3600
              h = true
            end
            
            if p[i].include? 'm'
              teile1 = teile[1].split 'm'
              sek += teile1[0].to_i*60
              m = true
            elsif p[i].include? 'M'
              teile1 = teile[i].split 'M'
              sek += teile1[0].to_i*60
              m = true
            end
            
            if p[i].include? 's' or p[1].include? 'S'
              s = teile1[i].chop if !teile1.nil?
              s = teile[i].chop if teile1.nil?
              sek += s.to_i
              sek = p[i].chop if teile.nil?
              s = true
            end
            
            if !h and !m and !s
              sek = p[i].to_s
            end
            
            start = sek if i == 1
            ende = sek if i == 2
          }
          start = @verw.get_last_pos id
          if p[2].eql? '*'
            ende = @verw.get_hb_laenge @verw.get_dateien p[0]
          end
          t1 = Thread.new {
            @verw.play id, start.to_i, ende.to_i
            Thread.current['fertig'] = true
          }
          pos = start.to_i
          while t1['fertig'].nil?
            pos += 5
            sleep 5
            if !t1['fertig'].nil?
              @verw.up_pos id, pos
            end
          end
          t1.join
          @verw.up_pos id, ende
        else
          puts 'Nothing found.'
        end
      else
        #puts @args
      end
    end
    
    if @args[:at]
      #checken, ob das array die richtige laenge hat
      at = @args[:at]
      if at.length == 2
        #altes Hoerbuch ausgeben
        id = at[0]
        tag = at[1]
        hb = @verw.get_hb id
        if !hb.nil?
          puts 'Altes Hoerbuch:'
          @ausg.aus hb, files?(hb.id), size?(hb.id), laenge?(hb.id)
          hb_new = hb.clone
          hb_new.tags = hb.tags << tag
          #neues Hoerbuch ausgeben
          @ausg.aus hb_new, files?(hb.id), size?(hb.id), laenge?(hb.id)
          if sure?
            @verw.add_tag at[0], at[1]
          end
        end
      end
    end

    if @args[:rt]
      #checken, ob das array die richtige laenge hat
      rt = @args[:rt]
      if rt.length == 2
        #altes Hoerbuch ausgeben
        id = rt[0]
        tag = rt[1]
        hb = @verw.get_hb id
        if !hb.nil?
          puts 'Altes Hoerbuch:'
          @ausg.aus hb, files?(hb.id), size?(hb.id), laenge?(hb.id)
          hb_new = hb.clone
          hb_new.tags.delete tag
          #neues Hoerbuch ausgeben
          @ausg.aus hb_new, files?(hb.id), size?(hb.id), laenge?(hb.id)
          if sure?
            @verw.remove_tag rt[0], rt[1]
          end
        end
      end
    end

    if @args[:ua]
      #checken, ob das array die richtige laenge hat
      ua = @args[:ua]
      if ua.length == 2
        #altes Hoerbuch ausgeben
        id = ua[0]
        hb = @verw.get_hb id
        if !hb.nil?
          puts 'Altes Hoerbuch:'
          @ausg.aus hb, files?(hb.id), size?(hb.id), laenge?(hb.id)
          hb_new = hb.clone
          hb_new.autor = ua[1].split ':'
          puts 'Neues Hoerbuch:'
          @ausg.aus hb_new, files?(hb.id), size?(hb.id), laenge?(hb.id)
          if sure?
            @verw.update_autor id, hb_new.autor
          end
        else
          puts 'Nothing found.'
        end
      end
    end
    
    if @args[:ut]
      #checken, ob das array die richtige laenge hat
      ut = @args[:ut]
      if ut.length == 2
        #altes Hoerbuch ausgeben
        id = ut[0]
        hb = @verw.get_hb id
        if !hb.nil?
          puts 'Altes Hoerbuch:'
          @ausg.aus hb, files?(hb.id), size?(hb.id), laenge?(hb.id)
          hb_new = hb.clone
          hb_new.titel = ut[1]
          puts 'Neues Hoerbuch:'
          @ausg.aus hb_new, files?(hb.id), size?(hb.id), laenge?(hb.id)
          if sure?
            @verw.update_titel id, hb_new.titel
          end
        else
          puts 'Nothing found.'
        end
      end
    end
    
    if @args[:up]
      #checken, ob das array die richtige laenge hat
      up = @args[:up]
      if up.length == 2
        #checken, ob es den pfad gibt
        pfad = @einst.basedir + up[1]
        if Pathname(pfad).exist?
          #altes Hoerbuch ausgeben
          id = up[0]
          hb = @verw.get_hb id
          if !hb.nil?
            hb_new = hb.clone
            hb_new.pfad = up[1]
            if hb.eql? hb_new        
              puts 'Altes Hoerbuch:'
              @ausg.aus hb, files?(hb.id), size?(hb.id), laenge?(hb.id)
              puts 'Neues Hoerbuch:'
              @ausg.aus hb_new, files?(hb.id), size?(hb.id), laenge?(hb.id)
              if sure?
                @verw.update_pfad id, hb_new.pfad
              end
            else
              puts 'Da hat sich nix geändert.'
            end
          else
            puts 'Das angegebene Hörbuch gibts ned!'
          end
        else
          puts "Den Ordner gibts ned!"
        end
      end
    end
    
    if @args[:us]
      #checken, ob das array die richtige laenge hat
      us = @args[:us]
      if us.length == 2
        #altes Hoerbuch ausgeben
        id = us[0]
        hb = @verw.get_hb id
        if !hb.nil?
          puts 'Altes Hoerbuch:'
          @ausg.aus hb, files?(hb.id), size?(hb.id), laenge?(hb.id)
          hb_new = hb.clone
          hb_new.sprecher = us[1].split ':'
          puts
          puts 'Neues Hoerbuch:'
          @ausg.aus hb_new, files?(hb.id), size?(hb.id), laenge?(hb.id)
          if sure?
            #@verw.change id, 'sprecher', hb_new.sprecher, hb.sprecher
            @verw.update_sprecher id, hb_new.sprecher
          end
        else
          puts 'Nothing found.'
        end
      end
    end
    
    if @args[:stats]
      @ausg.stats_aus @verw.get_stats
    end
    
    if @args[:fd]
      res = @verw.full_dump
      res.each {|e| @ausg.aus e, files?(e.id), size?(e.id), laenge?(e.id)}
    end
    
    if @args[:remove]
      id = @args[:remove]
      res = @verw.get_hb id
      if !res.nil?
        @ausg.aus res, files?(res.id.to_i), size?(id), laenge?(id)
        if sure?
          @verw.hoerbuch_loeschen id
        end
      else
        puts "Nothing found."
      end
    end
    
    if @args[:id]
      res = @verw.get_hb @args[:id]
      if !res.nil?
          @ausg.aus res, files?(@args[:id]), size?(@args[:id]), laenge?(@args[:id])
      else
        puts "Nothing found."
      end
    end
    
    if @args[:author]
      res = @verw.suche_autor @args[:author]
      res.each {|f| @ausg.aus f, files?(f.id), size?(f.id), laenge?(f.id) }
    end
    
    if @args[:tag]
      res = @verw.suche_tag @args[:tag]
      res.each {|f| @ausg.aus f, files?(f.id), size?(f.id), laenge?(f.id) }
    end
    
    
    if @args[:title]
      res = @verw.suche_titel @args[:title]
      res.each {|e| @ausg.aus e, files?(e.id), size?(e.id), laenge?(e.id)}
    end
    
    if @args[:speaker]
      res = @verw.suche_sprecher @args[:speaker]
      res.each {|f| @ausg.aus f, files?(f.id), size?(f.id), laenge?(f.id) }
    end
    
    if @args[:rating]
      res = @verw.suche_bewertung @args[:rating]
      res.each {|e| @ausg.aus e, files?(e.id), size?(e.id), laenge?(e.id) }
    end
    
    if @args[:cdb]
      if sure?
        @verw.clear_tables
        puts 'done.'
      else
        puts 'cancelled.'
      end
    end
    
    if @args[:insert]
      ins = @args[:insert]
      if ins.length > 0
        #leerzeichen entfernen
        neu = Array.new
        ins.map! {|f|
          f = f.strip
          neu << f
        }
        ins = neu
        #checken ob es alle parameter gibt
        if ins.length == 6
          #checken ob es den angegebenen Ordner gibt
          pfad = @einst.basedir + ins[3]
          puts pfad
          if Pathname.new(pfad).exist?
            #tags, autoren, sprecher parsen
            tags = ins[5].split ':'
            autoren = ins[1].split ':'
            sprecher = ins[2].split ':'
            
            #neues Hoerbuch erstellen
            hb = Hoerbuch.new 0, ins[0], autoren , sprecher, ins[3], ins[4].to_i, tags
            #neues Hoerbuch ausgeben um zu checken ob alles passt
            @ausg.aus hb, nil, nil, nil
            #benutzereingabe abwarten
            if sure?
              #Hoerbuch an die Verwaltung übergeben
              @verw.hoerbuch_einfuegen hb
            else
              puts 'cancelled.'
            end
          else
            puts "Den Ordner gibts ned."
          end
        else
          puts "falsche Anzahl Argumente"
        end
      end
    end
  end
end
#begin
  Main.new
#rescue Mysql::Error => e
#  #connection refused
#  if e.errno == 2002
#    puts "Konnte nicht zum MySQL server verbinden. Sicher, dass er läuft?"
#  #keine rechte
#  elsif e.errno == 1044
#    puts "Zugriff für User " + @einst.user + " verweigert"
#  end
#  #Datenbank nicht gefunden
#  if e.error.start_with? "Unknown database"
#    puts "Konnte Datenbank nicht finden. Entweder manuell anlegen, oder mit --init-db versuchen."
#  end
#  puts e
#  exit 1
#end