
class SetMainQuestJob < CachedGameDataJob
  def self.perform(_id, _zone, model, qid)
    instance = model.cur_instance
    return false if instance.nil?

    qb = instance.quests
    tracker = qb.main_quest_tracker
    tracker.completed = []
    GameConfig.main_quests.orders.each do |tid|
      tracker.completed << tid
      if tid == qid
        tracker.gen_quest(tid)
        break
      end
    end
    true
  end
end

class UnlockAllSkillsJob < CachedGameDataJob
  def self.perform(_id, _zone, model)
    hero = model.hero
    GameConfig.skills.each do |sid, _skill|
      hero.skills << sid
    end
    true
  end
end

class SendItemJob < CachedGameDataJob
  def self.perform(id, zone, model, tid, count, equip_level = 1)
    Log_.info("check send item job data:#{id} #{zone} #{tid}, #{count}")
    model.cur_instance.add_bonus(tid, count, equip_level) if model.cur_instance
    true
  end
end

class DoDropJob < CachedGameDataJob
  def self.perform(id, zone, model, tid)
    Log_.info("check do drop job data:#{id} #{zone} #{tid}")
    model.cur_instance.do_drop(tid, nil, "do_drop_job") if model.cur_instance
    true
  end
end


class AddStoryQuestJob < CachedGameDataJob
  def self.perform(_id, _zone, model, pid)
    instance = model.cur_instance
    return false unless instance
    qb = instance.quests
    qb.add_story_pkg(pid)
    true
  end
end

class AddBranchQuestJob < CachedGameDataJob
  def self.perform(_id, _zone, model, qid)
    instance = model.cur_instance
    if instance
      qb = instance.quests
      qb.add_branch_quest(qid)
    end
    true
  end
end

class ResetAllQuestJob < CachedGameDataJob
  def self.perform(_id, _zone, model)
    instance = model.cur_instance
    return false unless instance
    instance.quests = QuestBox.new
    true
  end
end

class ClearBagJob < CachedGameDataJob
  def self.perform(id, zone, model)
    Log_.info("check clear bag job data:#{id} #{zone}")
    cur_instance = model.cur_instance
    return false unless cur_instance
    cur_instance.bag.containers = {}
    cur_instance.bag.refresh

    weared_equips = {}
    weared_equips_id = cur_instance.hero.equip_container.containers.normal
    weared_equips_id.each do |v|
      weared_equips[v] = cur_instance.equips[v] if v && cur_instance.equips[v]
    end
    cur_instance.equips = weared_equips

    cur_instance.hero.equip_container.containers.item = Array.new(2, {})

    cur_instance.inventory.refresh
    cur_instance.items = {}
    true
  end
end

class ResetPositionJob < CachedGameDataJob
  def self.perform(id, zone, model)
    Log_.info("reset position job data:#{id} #{zone}")
    cur_instance = model.cur_instance
    return false unless cur_instance
    cur_instance.pos_info.reset
    true
  end
end

class SetCreditJob < CachedGameDataJob
  def self.perform(_id, _zone, model, credits, coins, money)
    # Log_.info("check set credit job data:#{id} #{zone}, #{credits}, #{coins}, #{money}" )
    cur_instance = model.cur_instance
    return false unless cur_instance
    cur_instance.credits = credits
    cur_instance.coins = coins
    cur_instance.money = money
    true
  end
end

class UnlockAllFunctions < CachedGameDataJob
  def self.perform(_id, _zone, model)
    cur_instance = model.cur_instance
    return false unless cur_instance
    GameConfig.mobile.each do |x|
      name = x['function']
      cur_instance.record.unlock_apps[name] = true
    end

    cur_instance.unlock_func_list(GameConfig.functions.keys)

    true
  end
end

class SetEnergyJob < CachedGameDataJob
  def self.perform(_id, _zone, model, energy)
    # Log_.info("check set credit job data:#{id} #{zone}, #{energy}" )
    instance = model.cur_instance
    return false unless instance
    instance.energy = energy
    true
  end
end

class SendAbilityItemsJob < CachedGameDataJob
  def self.perform(_id, _zone, model)
    instance = model.cur_instance
    return false unless instance
    items = GameConfig.items.select { |_tid, item| item.notes }.values
    items.each do |item|
      instance.add_bonus(item.tid, 10)
    end

    true
  end
end

class SendGiftItemsJob < CachedGameDataJob
  def self.perform(_id, _zone, model)
    instance = model.cur_instance
    items = GameConfig.items.select { |_tid, item| item.gift }.values
    items.each do |item|
      instance.add_bonus(item.tid, 10)
    end

    true
  end
end

class SendDebugSuitJob < CachedGameDataJob
  def self.perform(_id, _zone, model)
    instance = model.cur_instance
    ["ite1100101", "ite1110101", "ite1120101", "ite1130101", "ite1140101", "ite1150101", "ite1160101", "ite1170101", "ite1061001","ite1071001","ite1210302","ite1210602","ite1210701","ite1210601",].each do |tid|
      instance.add_bonus(tid, 100)
    end

    true
  end
end
