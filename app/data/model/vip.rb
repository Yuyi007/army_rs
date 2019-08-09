
class Vip
  attr_accessor :level
  attr_accessor :exp

  include Loggable
  include Jsonable

  gen_from_hash
  gen_to_hash

  def initialize
    @level ||= 0
    @exp   ||= 0
  end

  def refresh
    if level > max_level
      self.level = max_level
    end
   # do_level_up while should_level
  end

  def alter_exp(n)
    @exp += n
    org_level = @level
    do_level_up while should_level
    instance.send_daily_vip_buchang(@level)
    instance.update_player if org_level != @level
    instance.sign_in_reward.check_vip_mail
    # if level >= max_level and @exp > level_up_exp then @exp = level_up_exp end
  end

  def do_level_up
    @exp -= level_up_exp
    @level += 1
    check_unlock_apps()
  end

  def should_level
    @level < max_level && @exp >= level_up_exp
  end

  def reach_max_level?
    @level >= max_level
  end


  def level_up_exp
    if level == max_level
      return now_type.consume
    else
      return type(level).consume
    end
  end

  def type(lv)
    tid = GameConfig.vip_levels[lv.to_s]
    if tid.nil?
      d {"error vip_lv:#{lv} has null tid in vips.json"}
      return
    end
    GameConfig.vips[tid]
  end

  def now_type
    type(level)
  end

  def max_level
    GameConfig.vip_levels.size - 1
  end

  def instance
    __owner__
  end

  def model
    instance.model
  end

  def check_unlock_apps
    GameConfig.mobile.each do |x|
      next if x.vip_level_id.nil?
      next if x.vip_level_id != @level
      # instance.record.changed
      instance.record.unlock_apps[x.function] = false
    end
  end



end

