module InstanceAlter
  #消耗/获取金币必须通过此接口
  def alter_coins(num, reason = nil)
    @coins += num
    @coins
  end

  #消耗/获取碎片必须通过此接口
  def alter_fragments(num, reason = nil)
    @fragments += num
    @fragments
  end

  #钻石充值币
  def alter_credits(num, reason = nil)
    model.chief.alter_credits(num)
  end

  def level_up_exp
    GameConfig.levelup[@level.to_s].need_exp
  end

  def levelup?
    max_lv = GameConfig.max_level
    @level < max_lv && @exp >= level_up_exp
  end

  #经验
  def alter_exp(num, reason = nil)
    old_exp = @exp
    @exp += num
    level_up = levelup?
    while levelup? do 
      @exp -= level_up_exp
      @level += 1
    end

    diff_exp = @exp - old_exp
    if @level >= GameConfig.max_level
      @exp = 0
      diff_exp = old_exp 
    end

    [diff_exp, level_up]
  end


  def add_bonus(tid, count = 1, reason = nil)
    case tid
    when /^ite/     #物品
      add_item(tid, count, reason)
    when /^avatar/  #部件
      add_avatar(tid, 1, reason)
    when /^deco/    #装饰
      add_decoration(tid, 1, reason)
    when /^paint/   #水贴
      add_paint(tid, 1, reason)
    end
  end

  def add_item(tid, count, reason = nil)
    t = GameConfig.get_type(tid)
    return [] if t.nil?
    if t.func_cat == 'currency' 
      ret = { :tid => tid,
              :count => count}
      case t.add_attr
      when 'credits'
        alter_credits(count, reason)
      when 'coins'
        alter_coins(count, reason)
      when 'fragments'
        alter_fragments(count, reason)
      when 'exp'
        count, level_up = alter_exp(count, reason)
        ret[:exp] = count
        ret[:level] = @level if level_up
      end
      ret
    else
      item = @items[tid] || Item.new(tid)
      item.count += count
      @items[tid] = item
      item
    end
  end

  def calculate_settlement(data, pid, exp_mul = 1, coins_mul = 1)
    exp, coins    = 0

    award_coins   = 5      #排名奖励金币
    mul           = 1      #排名奖励金币倍数，失败为1，胜利为2
    team          = 0      #组队经验加成，失败为0，胜利为5
    goal          = 0      #进球金币加成，每一个加5

    exp_base      = 12     #基础经验系数，失败为12，胜利为18
    coins_base    = 4      #基础金币系数，失败为4，胜利为6

    duration     = (data.duration / 60.0).round(1)
    winner        = data.winner
    reason        = 'combat_fail'
    # side_zero    = data.stats[0].pstats
    # side_one    = data.stats[1].pstats
    # side_zero.sort!{|a, b| b.mvp_score <=> a.mvp_score}
    # side_one.sort!{|a, b| b.mvp_score <=> a.mvp_score}

    side = nil
    data.stats.each do |sideStats|
      sideStats.pstats.each do |stat|
        if stat.pid == pid
          side = sideStats.side
          if side == winner
          	team = stat.team * 5
            mul = 2
            exp_base = 18
            coins_base = 6
            reason = 'combat_success'
          end
          goal = stat.goal
          break
        end
      end
    end

    side_hash    = data.stats[side].pstats
    side_hash.sort!{|a, b| b.mvp_score <=> a.mvp_score}
    side_hash.each do |player|
      award_coins = award_coins - 1
      if player.pid == pid
        break
      end
    end

    exp   = ([exp_base * duration, 172].min * exp_mul + team).round()
    coins = ([coins_base * duration, 52].min * coins_mul + award_coins * mul + goal * 5).round()

    alter_coins(coins, reason)
    alter_exp(exp, reason)

    # puts(">>>>>>>exp_base :#{exp_base},  duration :#{duration},  exp_mul :#{exp_mul},  team :#{team},  exp :#{exp}")
    # puts(">>>>>>>coins_base :#{coins_base},  duration :#{duration},  exp_mul :#{coins_mul},  award_coins :#{award_coins},  mul :#{mul},  coins :#{coins}")

    return exp, coins
  end

  def sell_items(tid, count, reason)
  	item = @items[tid]
  	if item
      num = item.operate(count)
      profile = GameConfig.items[tid]
	    price = profile.sell_price
	    sell_id = profile.sell_type

	    gain = price * num
	    get = {}
	    get.count = gain
	    get.tid = sell_id
	    add_item(sell_id, gain, reason)

      @items.delete(tid) if item.count <= 0
	    return get
	  end
  end

  def use_items(tid, count)
    profile = GameConfig.items[tid]
  	item = @items[tid]
    gift = false
    attr_list = profile.add_attr
    if attr_list
    	if item
	      result, detail, equipped_data = @avatar_data.redeem_item(attr_list, profile.useable_dur, count)
	      if result
	        num = item.operate(count)

          gift = {}
          gift.count = num
          gift.tid = tid
          gift.detail = []
          gift.detail << detail.to_hash
          if equipped_data
            gift.equipped_data = equipped_data.to_hash
          end
	      end
	    end
    end
    return gift
  end
end