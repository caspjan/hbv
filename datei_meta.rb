require 'taglib'
require_relative 'require'

class Datei_Meta_Parser
  def initialize pfad, nummer
    @pfad = pfad
    @nummer = nummer
  end
  
  def parse
    datei = File.new @pfad
    puts @pfad
    @groesse = datei.size
    @pfad = File.expand_path @pfad
    TagLib::FileRef.open @pfad do |file|
      unless datei.nil?
        properties = file.audio_properties
        @laenge = properties.length
      end
    end
    return Datei.new @nummer, @pfad, @laenge, @groesse
  end
end