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
  attr_accessor:anz_formate
  attr_accessor:anz_hb_pro_format
  
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
    @anz_formate = 0
    @anz_hb_pro_format = Hash.new
  end
  
  def to_h
    res = Hash.new
    res[:hb_ges] = @hb_ges
    res[:dateien_ges] = @dateien_ges
    res[:size_ges] = @size_ges
    res[:laenge_ges] = @laenge_ges
    res[:bw_avg] = @bw_avg
    res[:tags_ges] = @tags_ges
    res[:avg_autoren_pro_hb] = @avg_autoren_pro_hb
    res[:avg_sprecher_pro_hb] = @avg_sprecher_pro_hb
    res[:avg_hb_pro_autor] = @avg_hb_pro_autor
    res[:avg_hb_pro_sprecher] = @avg_hb_pro_sprecher
    res[:avg_tags_pro_hb] = @avg_tags_pro_hb
    res[:avg_hb_pro_tag] = @avg_hb_pro_tag
    res[:db_size] = @db_size
    res[:avg_format_pro_hb] = @avg_format_pro_hb
    res[:avg_hb_pro_format] = @avg_hb_pro_format
    res[:anz_formate] = @anz_formate
    res[:anz_hb_pro_format] = @anz_hb_pro_format
    return res
  end
end