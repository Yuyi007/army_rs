module CdkeysHelper

  def get_name(tid)
    GameConfig.strings["str_#{tid}_name"]
  end

end
