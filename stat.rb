class Stats
  attr_accessor :hb_ges
  attr_accessor :dateien_ges
  attr_accessor :size_ges
  attr_accessor :laenge_ges
  attr_accessor :bw_durchschn
  attr_accessor :bewertungen
  
  def initialize
    @hb_ges = 0
    @dateien_ges = 0
    @size_ges = 0
    @laenge_ges = 0
    @bw_durchschn = 0.0
    @bewertungen = Hash.new
  end
end