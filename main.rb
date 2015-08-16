#!/bin/env ruby
require 'slop'
require_relative 'verwaltung'
require_relative 'ausgabe'

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
    o.array '-i', '--insert', 'insert new audiobook into database; title,author,speaker,path (NO spaces)'
    o.on '-h', '--help', 'display this help' do
      puts o
    end
    o.bool '-cdb', '--clear-db', 'clear whole database'
    o.bool '-f', '--force', "don't ask"
    o.string '-r', '--remove', '[id] remove audiobook from database'
    o.string '-id', '--get-by-id', '[id] get audiobook by id'
    o.bool '-fd', '--full-dump', 'print all Audiobooks in database'
    }
  
    
    
    if @args[:fd]
      res = @verw.full_dump
      res.each {|e| @ausg.aus e }
    end
    
    def sure?
      if @args[:force]
        return true
      end
      puts 'Are you sure? (Y/n)'
      r = STDIN.gets.chomp
      r.eql? 'Y' or r.eql? 'y'
    end
    
    if @args[:remove]
      id = @args[:remove]
      res = @verw.get_hb id
      if !res.nil?
        @ausg.aus res
        if sure?
          @verw.hoerbuch_loeschen Hoerbuch.new id, nil, nil, nil, nil
        end
      else
        puts "Nothing found."
      end
    end
    
    if @args[:id]
      res = @verw.get_hb @args[:id]
      if !res.nil?
        @ausg.aus res
      else
        puts "Nothing found."
      end
    end
    
    if @args[:author]
      res = @verw.suche_autor @args[:author]
      res.each {|e| @ausg.aus e }
    end
    
    if @args[:title]
      res = @verw.suche_titel @args[:title]
      res.each {|e| @ausg.aus e}
    end
    
    if @args[:speaker]
      res = @verw.suche_sprecher @args[:speaker]
      res.each {|e| @ausg.aus e }
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
      if ins.length == 4
        hb = Hoerbuch.new 0, ins[0], Array.new << ins[1] , Array.new << ins[2], ins[3] 
        @ausg.aus hb
        if sure?
          @verw.hoerbuch_einfuegen hb
        else
          puts 'cancelled.'
        end
      end
    end
  end
end
Main.new