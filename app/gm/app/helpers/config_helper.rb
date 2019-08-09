
# 有关配置的通用函数放在这里

module ConfigHelper

  def hero_display_name tid
    hero = GameConfig.config['heroes'][tid]
    hero ? hero['name'] : 'Unknown'
  end

  def equip_display_name tid
    name_with_tid GameConfig.config['equips'][tid]
  end

  def avatar_display_name id
    name_with_tid GameConfig.config['avatar'][id]
  end

  def name_with_tid cfg
    name = cfg['name']
    tid = cfg['tid']
    "#{name}[#{tid}]"
  end

  def garment_display_name tid
    name_with_tid GameConfig.config['garments'][tid]
  end

  def action_type_display_name type
    ActionDb.action_types[type.to_i]
  end

  def item_display_name tid
    name_with_tid GameConfig.config['items'][tid]
    #name_with_tid GameConfig.config['avatar'][tid]
  end

  def skill_display_name tid
    GameConfig.config['skills'][tid]['name']
  end

  def codex_display_name tid
    GameConfig.config['codexes'][tid]['name']
  end

  def astrolabe_display_name tid
    GameConfig.config['astrolabes'][tid]['name']
  end

  def special_display_name tid
    return tid
  end

  def credits_chongzhi_type_name type
    GameConfig.strings["str_credits_#{type}"]
  end
end