module EventsZhaoxianHelper
  def get_hero_name(tid)
    GameConfig.strings["str_#{tid}_name"] + "-#{tid}" if tid
  end

end
