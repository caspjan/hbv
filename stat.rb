class Stats
  attr_accessor:hb_ges
  attr_accessor:dateien_ges
  attr_accessor:tags_ges
  attr_accessor:size_ges
  attr_accessor:laenge_ges
  attr_accessor:bw_avg
  attr_accessor:avg_autoren_pro_hb
  attr_accessor:avg_sprecher_pro_hb
  attr_accessor:avg_hb_pro_autor
  attr_accessor:avg_hb_pro_sprecher
  attr_accessor:avg_tags_pro_hb
  attr_accessor:avg_hb_pro_tag
  attr_accessor:db_size
  attr_accessor:avg_format_pro_hb
  attr_accessor:avg_hb_pro_format
  
  def initialize
    @hb_ges = 0
    @dateien_ges = 0
    @size_ges = 0
    @laenge_ges = 0
    @bw_avg = 0.0
    @tags_ges = 0
    @avg_autoren_pro_hb = 0
    @avg_sprecher_pro_hb = 0
    @avg_hb_pro_autor = 0
    @avg_hb_pro_sprecher = 0
    @avg_tags_pro_hb = 0
    @avg_hb_pro_tag = 0
    @db_size = 0
    @avg_format_pro_hb = 0
    @avg_hb_pro_format = 0
  end
end