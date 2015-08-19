#!/bin/env ruby
require_relative 'require'

class Main
  def initialize
    einst_pars = Einstellung_Parser.new '/home/jan/Dokumente/Programmierzeug/Hoerbuch/hoerbuch.conf'
    @einst = einst_pars.einst
    
    @verw = Verwaltung.new @einst
    @ausg = Ausgabe.new @einst
    
    @args = Slop.parse { |o|
    o.string '-a', '--author', 'the author to search for'
    o.string '-s', '--speaker', 'the speaker to search for'
    o.string '-t', '--title', 'the title to search for'
    o.integer '-b', '--rating', 'print all audiobooks with rating (0-10)'
    o.array '-i', '--insert', 'insert new audiobook into database; title,author,speaker,path,rating (NO spaces)'
    o.on '-h', '--help', 'display this help' do
      puts o
    end
    o.bool '-cdb', '--clear-db', 'clear whole database'
    o.bool '-f', '--force', "don't ask"
    o.string '-r', '--remove', '[id] remove audiobook from database'
    o.string '-id', '--get-by-id', '[id] get audiobook by id'
    o.bool '-fd', '--full-dump', 'print all Audiobooks in database'
    o.bool '--files', 'print all files of the audiobook'
    o.bool '--init-db', 'create all needed tables'
    } 
    
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
        return @verw.get_dateien hb_id
      else
        return nil
      end
    end
    
    if @args[:'init-db']
      @verw.init_db
      puts "done."
    end
    
    if @args[:fd]
      res = @verw.full_dump
      res.each {|e| @ausg.aus e, files?(e.id) }
    end
    
    if @args[:remove]
      id = @args[:remove]
      res = @verw.get_hb id
      if !res.nil?
        @ausg.aus res, files?(res.id.to_i)
        if sure?
          @verw.hoerbuch_loeschen Hoerbuch.new id, nil, nil, nil, nil, nil
        end
      else
        puts "Nothing found."
      end
    end
    
    if @args[:id]
      res = @verw.get_hb @args[:id]
      if !res.nil?
        @ausg.aus res, files?(@args[:id])
      else
        puts "Nothing found."
      end
    end
    
    if @args[:author]
      res = @verw.suche_autor @args[:author]
      res.each {|e| @ausg.aus e, files?(e.id) }
    end
    
    if @args[:title]
      res = @verw.suche_titel @args[:title]
      res.each {|e| @ausg.aus e, files?(e.id)}
    end
    
    if @args[:speaker]
      res = @verw.suche_sprecher @args[:speaker]
      res.each {|e| @ausg.aus e, files?(e.id) }
    end
    
    if @args[:rating]
      res = @verw.suche_bewertung @args[:rating]
      res.each {|e| @ausg.aus e, files?(e.id) }
    end
    
    
    if @args[:cdb]
      if sure?
        @verw.clear_tables
        puts 'done.'
      else
        puts 'cancelled.'
      end
    end
    
    ins = @args[:insert]
    if ins.length > 0
      ins.map! {|e|
        e.rstrip!
        e.lstrip!
      }
      ins.each {|e|
        puts e
      }
      if ins.length == 5
        if Pathname.new(ins[3]).exist?
          hb = Hoerbuch.new 0, ins[0], Array.new << ins[1] , Array.new << ins[2], ins[3], ins[4].to_i
          @ausg.aus hb, nil
          if sure?
            @verw.hoerbuch_einfuegen hb
          else
            puts 'cancelled.'
          end
        else
          puts "Den Ordner gibts ned."
        end
      end
    end
  end
end
Main.new