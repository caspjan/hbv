require 'taglib'
require_relative 'hoerbuch_datei'

class Datei_Meta_Parser
  def initialize datei, nummer
    @datei = datei
    @hb_datei = Hoerbuch_Datei.new
    @hb_datei.nummer = nummer
  end
  
  def parse
    @hb_datei.groesse = @datei.size
    @hb_datei.pfad = @datei.expand_path
    TagLib::FileRef.open @datei.to_s do |fileref|
      unless fileref.null?
        tag = fileref.tag
        @hb_datei.titel = tag.title
        @hb_datei.interpret = tag.artist
        @hb_datei.album = tag.album
        @hb_datei.jahr = tag.year
        @hb_datei.genre = tag.genre
  
        properties = fileref.audio_properties
        @hb_datei.laenge = properties.length
      end
    end
    return @hb_datei
  end
end