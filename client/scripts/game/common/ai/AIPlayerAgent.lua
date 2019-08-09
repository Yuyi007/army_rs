
class('AIPlayerAgent', function(self, env, fighter)
end, AIAgent)

local m = AIPlayerAgent

function m:init()
  AIAgent.init(self)
  self:initSearchRange()
  self:initForTemplate()
end

function m:initSearchRange()
  self.extra["search_range"] = 99999
end

function m:initForTemplate()
	local faction = self.fighter.model.faction

  logd('AIPlayerAgent faction:%s', peek(faction))

	self.aiProfile = cfg.player_aiprofiles['temps'][faction]

	--触发信号标记位，有信号，相应位置为true
	self.extra["signals"] = {}
	for i,v in pairs(self.aiProfile.triggers) do
    table.insert(self.extra["signals"], false)
  end

  --已经触发的信号,经过配置权重排序，不包括正在执行的信号
  self.extra["signaleds"] = {}
  --当前信号,每次只取signaleds中的第一个来执行
  self.extra["cur_signal"] = 0

  --触发器分类
  self.triggers = {}
  for i,v in pairs(self.aiProfile.triggers) do
    self.triggers[v.category] = self.triggers[v.category] or {}
    table.insert(self.triggers[v.category], {cfg = v, index = i, weight = v.weight})
  end

  --注册触发器(定时的除外)
  self.handleHPChange = function()
    if not self.triggers['hp'] then return end
    local trigged = false
    for i,v in pairs(self.triggers['hp']) do
      local key = "hp_rate_triggerd_"..v.cfg.rate
      if not self.extra[key] then
        local p =  self.fighter:getModel():hpPercent()
        if v.cfg.rate >= p then
          self:arrangeSignals(v.index)
          self.extra[key] = true
          trigged = true
        end
      end
    end

    if trigged then
      self.env.aic:manualStep(self.btid)
    end
  end

  self.handleHitted = function(attackerInfo)
    local triggers = self.triggers['hit']
  	if triggers then
      local totalWeight = 0
      each(function(tri) totalWeight = totalWeight + tri.weight end, triggers)
      local i = 1
      if totalWeight == 0 then
        i = math.random(#triggers)
      else
        i = MathUtil.randomByWeight(totalWeight, triggers)
      end
      local trigger = triggers[i]
      if trigger then
        local s = math.random(1000)
        if s <= trigger.cfg.odd then
          self:arrangeSignals(trigger.index)
          self.env.aic:manualStep(self.btid)
        end
      end
  	end
	end

	self.fighter:signal('change_hp'):add(self.handleHPChange)
	self.fighter:signal('hitted'):add(self.handleHitted)
end

function m:clearSignals()
  self.fighter:signal('change_hp'):remove(self.handleHPChange)
  self.fighter:signal('hitted'):remove(self.handleHitted)
end

function m:exit()
  self:clearSignals()
  self:cleanupSkillQueue()
  AIAgent.exit(self)
end

--interface of attributes

--end attributes

--interface of bd

--interface of agent
m.mnhs = {}
table.merge(AIAgent.mnhs, m.mnhs)



--[[
    方法: ply_has_trigger
    别名: Ply 有触发？
    描述: 是否有触发器触发了
    参数: 无
]]
m.mnhs["ply_has_trigger"] = "triggered?"
function m:ply_has_trigger(node)
  if #self.extra["signaleds"] > 0 then
    return m.success
  end
  return m.fail
end

--[[
    方法: ply_get_signaled_trigger
    别名: Ply 获取一个有信号的触发器
    描述: 获取一个有信号的触发器，
          从排序过的信号队列中取出第一个信号，作为当前工作信号
    参数: 无
]]
m.mnhs["ply_get_signaled_trigger"] = "signal?"
function m:ply_get_signaled_trigger(node)
  if #self.extra["signaleds"] == 0 then
    return m.fail
  end
  self.extra["cur_trigger"] = self.extra["signaleds"][1]

  if aidbg.debug then
    aidbg.log(0, "[PLAYER] Get signaled trigger index:%s trigger:%s", inspect(self.extra["cur_trigger"]), inspect(self.aiProfile.triggers[self.extra["cur_trigger"]]))
  end

  return m.success
end

function m:reset_cur_signal()
  local i = self.extra["cur_trigger"]
  self.extra["cur_trigger"] = nil
  if i then
    self.extra["signals"][i] = false
    if self.aiProfile.triggers[i].category == "timing" then
      local key = "trigger_tm_start"..i
      local now = engine.time()
      self.extra[key] = now
    end
  end
  return m.success
end


--终止当前ai的时候需要清除的数据，比如技能序列, trigger触发状态, 目标
function m:_clear_ply_data()
	self:bd_set_target(nil)
end

--[[
    方法: ply_proc_player_input
    别名: Ply 玩家输入
    描述: 玩家有输入的时候，需要清除当前ai过程的临时数据
         玩家输入是指，玩家主动移动角色或者释放技能（不包括助战）
    参数: 无
]]
m.mnhs["ply_proc_player_input"] = "player_input"
function m:ply_proc_player_input(node)
  --自己死亡不执行后续ai动作
  if self:_is_dead() then
  	self:_clear_ply_data()
    return m.success
  end

  if not self.fighter then
  	self:_clear_ply_data()
    return m.success
  end

  if self.fighter.keyState.hasInput then
  	self:_clear_ply_data()
    return m.success
  end

  return m.fail
end

function m:_check_consume_item_condition(tid, index)
  if self.fighter.id ~= md.chief.id then return false end

  local mod = self.fighter:getModel()
  local cfgItem = cfg.items[tid]
  if cfgItem.usages['hp'] then
    if mod:curAttrReachMax('hp') then
      return false
    end
  end

  if cfgItem.usages['rage'] then
    if mod:curAttrReachMax('rage') then
      return false
    end
  end

  if cfgItem.usages['combo'] then
    if mod:curAttrReachMax('combo') then
      return false
    end
  end

  if index == 1 then
  	local p = mod:hpPercent()
  	if p > 0.6 then
  		return false
  	-- else
   --    local ftue_id = cc.scene.campaignType and cc.scene.campaignType.ftue_id or nil
   --    if ftue_id and (ftue_id == 'ftue_pve_04' or ftue_id == 'ftue_pve_05') then
   --      return false
   --    end
    end
  end

  if index == 2 then
		if cfgItem.bufflist then
			for _,v in pairs(cfgItem.bufflist) do
				if mod:buffExist(v) then
					return false
				end
			end
      local ftue_id = cc.scene.campaignType and cc.scene.campaignType.ftue_id or nil
      if ftue_id and (ftue_id == 'ftue_pve_02') then
        return false
      end
		end
  end

  return true
end


--[[
    方法: ply_check_use_items
    别名: Ply 使用药品
    描述: 检查是否满足药品使用条件，如果满足就使用药品
    参数: 无
]]
m.mnhs["ply_check_use_items"] = "use_item"
function m:ply_check_use_items(node)
  if self.fighter and self.fighter.id ~= md.chief.id then
    return m.success
  end

  local curHero = md:curHero()
  local slotItems = curHero.equip_container.containers.item
  for i=1,2 do
  	local info 	= slotItems[i]
  	local tid 	= info['tid']
  	local count = info['num']
  	if tid and count > 0 then
  		local cdOk = cc.itemConsumeManager:alreadyCoolDown(tid)
  		if cdOk then
        local key = "_last_consume_"..tostring(i)
        local now = stime()
        self[key] = self[key] or now
        --发送间隔要大于1s 不然服务器还没返回 又发送 浪费
        if (now - self[key]) >= 1 then
    			local usable = self:_check_consume_item_condition(tid, i)
    			if usable then
  		  		sm:playSound('ui013')
  		  		local action = ActionFactory.makeConsumeItem()
  			    local data = action.data
  			    data.id = tid
  			    data.tid = tid
  			    data.count = 1
  			    data.slotIndex = i
  			    self:sendAction(action)

            self[key] = now

  			    if aidbg.debug then
  			      aidbg.log(0, "[PLAYER] <color='#bb3925'>吃药</color>: %s slot:%s", inspect(tid), inspect(i))
  			    end
  		  	end
        end
	  	end
  	end
  end

  return m.success
end


--[[
    方法: ply_search_target
    别名: Ply 搜索目标
    描述: 搜索目标，boss优先，最近的小怪次之，如果boss霸体忽略
    参数: 无
]]
m.mnhs["ply_search_target"] = "target"
function m:ply_search_target(node)
	self:bd_set_target(nil)

	if not self.fighter then return m.fail end

	local pos = self.fighter:position()
	local target = nil
  local dist = nil

  local sides = cc.enemySides(self.fighter.side)
  local batiTarget = nil
  for _, side in pairs(sides) do
    for k, v in cc.iterHeroes(side) do
      if not v:destroyedOrDead() then
      	if v.config.is_boss then
      		if not v:isBati() then
	      		target = v
          else
            batiTarget = v
	      	end
      		break
      	else
      		local pos1 = v:position()
	        local dist = MathUtil.dist2(pos, pos1)

	        if not dist then
	          dist = dist
	          target = v
	        end

	        if dist >= dist then
	          target = v
	          dist = dist
	        end
      	end
      end
    end

    if target then
    	break
    end
  end

  if target then
    self:bd_set_target(target)
    return m.success
  else
    if batiTarget then
      self:bd_set_target(batiTarget)
      return m.success
    end
    return m.fail
  end
end

--[[
    方法: ply_cur_sig_changed
    别名: Ply 当前的信号有变？
    描述: 信号触发的技能，如果不是立刻释放的话，在移动过程中，
          如果当前信号变成别的信号了，该方法用于检测这种信号变化
    参数: 无
]]
m.mnhs["ply_cur_sig_changed"] = "sig_changed?"
function m:ply_cur_sig_changed(node)
  local i = self.extra["cur_trigger"]
  if self:isCurSignal(i) then
    return m.fail
  end
  return m.success
end

function m:isCurSignal(index)
  local i = self.extra['signaleds'][1]
  if not i then return false end
  return i == index
end


function m:arrangeSignals(index)
  if self.extra["signals"][index] then
    return
  end --已经有信号了不进入信号队列
  self.extra["signals"][index] = true
  if table.contains(self.extra["signaleds"], index) then
    return
  end --已在队列不重入

  if aidbg.debug then
    aidbg.log(0, "[PLAYER][%s] <color='#9ed6ed'>信号触发</color> index:%s trigger:<color='#24b93d'>%s</color>", inspect(self.fighter.id), inspect(index), inspect(self.aiProfile.triggers[index].category))
  end

  table.insert(self.extra["signaleds"], index)
  table.sort(self.extra["signaleds"], function(a, b)
      --已经在释放技能的永远排在第一个
      if a == self.inAttackingTrigger then return true end
      if b == self.inAttackingTrigger then return false end
      return self.aiProfile.triggers[a].weight > self.aiProfile.triggers[b].weight
    end)
end

--[[
    方法: ply_check_signals
    别名: Ply 检查并设置当前的信号
    描述: 模板模式下的自动战斗ai,通过该方法来集中检测触发条件，
          1.如果某个条件触发了，就标记相应的信号为true,
          2.并将该信号送入待处理信号队列，并根据配置的权重进行排序，
          3.后续处理在队列不为空的时候，总是取第一个信号出来处理，
          4.处理完毕后，标记相应的信号为false
          5.除了定时触发外，触发时机改为被动等待signal通知，得到事件通知后，
            主动驱动一次ai step
    参数: 无
]]
m.mnhs["ply_check_signals"] = "CKSignals"
function m:ply_check_signals(node)
	if self.triggers['timing'] then
    for i,v in pairs(self.triggers['timing']) do
      local now = engine.time()
      local keyTime = "trigger_tm_start"..v.index
      self.extra[keyTime] = self.extra[keyTime] or now
      local dt = now - self.extra[keyTime]

      local keyInterval = "trigger_interval"..v.index
      local interval = self.extra[keyInterval]
      if not interval then
        local rgn = v.cfg.interval_rgn
        if rgn then
          local offset = math.random(rgn[2] - rgn[1])
          interval = rgn[1] + offset
        else
          interval = v.cfg.interval
        end
        self.extra[keyInterval] = interval
      end

      if dt >= interval then
        self:arrangeSignals(v.index)
        self.extra[keyTime] = now
      end
    end
  end
	return m.success
end

--[[
    方法: ply_set_cur_trigger_skill
    别名: Ply 设置当前触发的技能
    描述: 设置当前触发的技能
    参数: 无
]]
m.mnhs["ply_set_cur_trigger_skill"] = "triSkill?"
function m:ply_set_cur_trigger_skill(node)
	local i = self.extra["cur_trigger"]
	if aidbg.debug then
    aidbg.log(0,"[PLAYER] signaleds:%s", inspect(self.extra["signaleds"]))
  end
	if not i then
    return m.fail
  end

  local profile = self.aiProfile.triggers[i]
  local skills = profile.skills
  if not skills or #skills == 0 then
    return m.fail
  end

 	local sid = nil
  if profile.queued then
    sid = skills[1].sid
    self:bd_set_skill_queue(skills)
  else
    self:bd_set_skill_queue(nil)
    local i = 1
    if profile.total_weight == 0 then
      i = math.random(#profile.skills)
    else
      i = MathUtil.randomByWeight(profile.total_weight, profile.skills)
    end
    sid = profile.skills[i].sid
  end

  self:bd_set_cur_skill(sid)

  return m.success
end

--[[
    方法: ply_trigger_queued_attack
    别名: Ply 触发连续攻击
    描述: 如果没有队列的技能就释放之前设置的技能；
          如果有队列的技能则释放之前队列起来的技能列表，当前技能不释放，直接设空；
          任何一个技能不能释放就打断整个序列；
          如果过程中发生被击打断的情况，返回成功；
          如果到了切招点可以释放后续技能，就释放；
          所有技能释放完成后返回成功
    参数: 无
]]
m.mnhs["ply_trigger_queued_attack"] = "ply多段攻击"
function m:ply_trigger_queued_attack(node)
  local function clear()
  	if aidbg.debug then
      aidbg.log(0, "[PLAYER]<color='#bb3925'>多段攻击完成后删除trigger</color>: %s", inspect(self.extra["signaleds"][1]))
    end
    table.remove(self.extra["signaleds"], 1)
    self:reset_cur_signal()
    self.inAttackingTrigger = nil
    self.fighter.keyState:resetSignalVars()
  end

  if self:_is_dead() then
    self:cleanupSkillQueue()
    return m.fail
  end

  local target = self:_check_get_target()
  if not target then
    clear()
    self:cleanupSkillQueue()
    return m.fail
  end

  if target:destroyedOrDead() then
    clear()
    self:cleanupSkillQueue()
    return m.fail
  end

  local skills = self:bd_get_skill_queue()
  if not skills or #skills == 0 then
    local suc = self:ply_trigger_attack(node)
    if suc == m.fail then
      clear()
      self:cleanupSkillQueue()
    end
    return suc
  end

  if self:bd_get_sq_end()  then
    clear()
    self:cleanupSkillQueue()
    return m.success
  end

  self:bd_set_cur_skill(nil)
	local i = self:bd_get_sq_index() or 1
  if i == 1 then
    self:bd_set_sq_index(1)
    --如果不能释放 直接pass
    local sid = skills[1]
    if not self:doQueuedSkill(1) then
      clear()
      self:cleanupSkillQueue()
      return m.fail
    end

    if aidbg.debug then
      aidbg.log(0, "[PLAYER][%s] <color='#ff7e20'>触发队列攻击开始</color>, skills: %s", inspect(self.fighter.id), inspect(skills))
    end
    --进入真正释放技能的trigger才置顶不可切换
    self.inAttackingTrigger = self.extra["cur_trigger"]

    self:bd_set_sq_index(2)
    self:bd_set_sq_end(false)
    self:scheduleSkillQueue()
    return m.running
  else
  	return m.running
  end
end


--[[
    方法: ply_trigger_attack
    别名: Ply 单一攻击
    描述: 释放触发信号释放的技能，内部检测是否可施法，如果不能会一直等到可以施法为止，
         但是如果施法过程中，被击等原因造成施法不能的过程中，有其他权重更高的技能被触发
         那么，本次施法将被打断（返回成功），信号不清除，仍然在
    参数: 无
]]
m.mnhs["ply_trigger_attack"] = "ply攻击"
function m:ply_trigger_attack(node)
	local function clear()
		if aidbg.debug then
      aidbg.log(0, "[PLAYER]<color='#bb3925'>单一攻击完成后删除trigger</color>: %s", inspect(self.extra["signaleds"][1]))
    end

    table.remove(self.extra["signaleds"], 1)
    self:reset_cur_signal()
    self.inAttackingTrigger = nil
    self:bd_set_skill_start(nil)
    self:bd_set_cur_skill(nil)
    self.fighter.keyState:resetSignalVars()
	end

	if self:_is_dead() then
    clear()
    return m.fail
  end

  local sid = self:bd_get_cur_skill()
  if not sid then
    clear()
    return m.fail
  end

  local target = self:_check_get_target()
  if not target then
    clear()
    return m.fail
  end

  if target:destroyedOrDead() then
    clear()
    return m.fail
  end

  local ks = self.fighter.keyState
  local startTime = self:bd_get_skill_start()
  if not startTime then
  	self.inAttackingTrigger = self.extra["cur_trigger"]
  	local pos2 = target:position()
    local pos1 = self.fighter:position()
    local dir = Vector3.Normalized(pos2 - pos1)
    self.fighter:setForward(dir)

    local action = SkillActionFactory.make(self.fighter, sid)
    if not self.fighter:canCast() or not self.fighter.model:canCast(action.data.tid) then
      clear()
      return m.fail
    end

    self:sendAction(action)
    if aidbg.debug then
      aidbg.log(0, "[PLAYER][%s] <color='#bb3925'>释放单一技能</color>: %s", inspect(self.fighter.id), inspect(sid))
    end

    self:bd_set_skill_start(engine.time())
    ks:resetSignalVars()
    return m.running
  end

  if ks.skillEnter then
    self:applySkillMovement(sid)
    ks:resetSigVarByName('skillEnter')
  else
    clear()
    return m.success
  end

  if ks.skillExit then
    clear()
    return m.success
  end

  if ks.interupted then
    clear()
    return m.success
  end

  --如果没有exit和打断 就等技能时间解套
  local stype = cfg.skills[sid]
  local duration = self:getClipTime(stype.anim_type)
  local elapseTime = engine.time() - startTime
  if elapseTime >= duration then
    clear()
    return m.success
  end

  return m.running
end

--[[
    方法: ply_queued_attack
    别名: ply 普通的多段攻击
    描述: 如果没有队列的技能就释放之前设置的技能；
          如果有队列的技能则释放之前队列起来的技能列表，当前技能不释放，直接设空；
          任何一个技能不能释放就打断整个序列；
          如果过程中发生被击打断的情况，返回成功；
          如果到了切招点可以释放后续技能，就释放；
          所有技能释放完成后返回成功
    参数: 无
]]
m.mnhs["ply_queued_attack"] = "普通多段攻击"
function m:ply_queued_attack(node)
	if self:_is_dead() then
    self:cleanupSkillQueue()
    return m.fail
  end

  local target = self:_check_get_target()
  if not target then
    self:cleanupSkillQueue()
    return m.fail
  end

  if target:destroyedOrDead() then
    self:cleanupSkillQueue()
    return m.fail
  end

  local skills = self:bd_get_skill_queue()
  if not skills or #skills == 0 then
    local suc = self:_ply_single_attack(node)
    if suc == m.fail then
      self:cleanupSkillQueue()
    end
    return suc
  end

  if self:bd_get_sq_end() then
    self:cleanupSkillQueue()
    return m.success
  end

  self:bd_set_cur_skill(nil)
  local i = self:bd_get_sq_index() or 1
  if i == 1 then
    self:bd_set_sq_index(1)
    local sid = skills[1].sid
    if not self:doQueuedSkill(1) then
    	self:cleanupSkillQueue()
      return m.fail
    end

    if aidbg.debug then
      aidbg.log(0, "[PLAYER][%s] <color='#ff7e20'>普通队列攻击开始</color>, skills: %s", inspect(self.fighter.id), inspect(skills))
    end

    self:bd_set_sq_index(2)
    self:bd_set_sq_end(false)
    self:scheduleSkillQueue()

    return m.running
  else
    return m.running
  end
end

function m:_ply_single_attack(node)
	local function clear()
    self:bd_set_cur_skill(nil)
    self:bd_set_move_speed(nil)
    self:bd_set_tm_start(nil)
    self:cleanupSkillQueue()
    self.fighter.keyState:resetSignalVars()
  end

  if self:_is_dead() then
    clear()
    return m.fail
  end

  local sid = self:bd_get_cur_skill()
  if not sid then
    clear()
    return m.fail
  end

  local target = self:_check_get_target()
  if not target then
    clear()
    return m.fail
  end

  if target:destroyedOrDead() then
    clear()
    return m.fail
  end

  local ks = self.fighter.keyState
  local startTime = self:bd_get_tm_start()
  if not startTime then
  	local action = SkillActionFactory.make(self.fighter, sid)
    if not self:_can_cast(action.data.tid) then
      clear()
      return m.fail
    end

    self:sendAction(action)
    if aidbg.debug then
      aidbg.log(0, "[PLAYER][%s] <color='#ffc500'>普通单一攻击</color>: %s", inspect(self.fighter.id), inspect(sid))
    end

    self:bd_set_tm_start(engine.time())
    ks:resetSignalVars()
    return m.running
  end

  if ks.skillEnter then
    self:applySkillMovement(sid)
    ks:resetSigVarByName('skillEnter')
  else
    clear()
    return m.success
  end

  if ks.skillExit then
    clear()
    return m.success
  end

  if ks.interupted then
    clear()
    return m.success
  end

  --如果没有exit和打断 就等技能时间解套
  local stype = cfg.skills[sid]
  local duration = self:getClipTime(stype.anim_type)
  local elapseTime = engine.time() - startTime
  if elapseTime >= duration then
    clear()
    return m.success
  end

  return m.running
end

function m:_get_wushuang_skill()
	local faction = self.fighter.model.faction
	local role = cfg.roledes[faction]
	return role['wushuang_sid']
end

--[[
    方法: ply_check_assist_skill
    别名: ply 检测释放助战技能
    描述: 如果当前怪物中有boss，自身没有技能组在排队释放，
         并且助战可用的情况下，释放助战技能
    参数: 无
]]
m.mnhs["ply_check_assist_skill"] = "助战"
function m:ply_check_assist_skill(node)
  if self.fighter and self.fighter.id ~= md.chief.id then
    return m.fail
  end

  local now = stime()
  self._last_check_assist_time = self._last_check_assist_time or now
  --固定间隔10s检测一次
  if now - self._last_check_assist_time < 10 then
    return m.fail
  end

  self._last_check_assist_time = now

  local target = self:_check_get_target()
  if not target then
    return m.fail
  end

  if self:_is_dead() then
    return m.fail
  end

  if cc.scene and
    (cc.scene.curSceneType == 'grouppve' or
    cc.scene.curSceneType == 'dungeonpve') then

    if cc.allPeers and #cc.allPeers > 1 then
      local n = math.random(100)
      if n > 33 then
        return m.fail
      end
    end
  end

  local sides = cc.enemySides(self.fighter.side)
  if not sides then
    return m.fail
  end

  local hasBoss = false
  for i,v in pairs(sides) do
    for j,e in cc.iterHeroes(v) do
      local profile = cfg.enemies[e.config.tid]
      if profile.is_boss then
        hasBoss = true
        break
      end
    end
  end

  if not hasBoss then
    return m.fail
  end

  if not cc.combatUI or not cc.combatUI.combatAssistSlot then
    return m.fail
  end

  --确保第一次要等boss出现10s后才放
  self._last_assist_time = self._last_assist_time or now
  if now - self._last_assist_time < 10 then
    return m.fail
  end
  self._last_assist_time = now
  cc.combatUI.combatAssistSlot:doAssist(false)

  return m.success
end

--[[
    方法: ply_check_wushuang_skill
    别名: ply 检测释放无双技能
    描述: 如果怒气满了，达到了无双技能释放条件，就立刻释放
    参数: 无
]]
m.mnhs["ply_check_wushuang_skill"] = "无双"
function m:ply_check_wushuang_skill(node)
	if self:_is_dead() then
    return m.fail
  end

  local target = self:_check_get_target()
  if not target then
    return m.fail
  end

  local sid = self:_get_wushuang_skill()
  if not sid then
  	return m.fail
  end

  local action = SkillActionFactory.make(self.fighter, sid)
  if not self.fighter:canCast() or not self.fighter.model:canCast(action.data.tid) then
    return m.fail
  end
  self:sendAction(action)
  if aidbg.debug then
    aidbg.log(0, "[PLAYER][%s] <color='#bb3925'>无双技能</color>: %s", inspect(self.fighter.id), inspect(sid))
  end

  return m.success
end


function m:_get_serial_skills()
	if not self.serialSkills then
		local normals, bufs = {}, {}
		self.serialSkills = {normals = normals, bufs = bufs}

		local skillSet = self.fighter.model.skillSet
		local faction = self.fighter.model.faction
		local serials = cfg.player_aiprofiles.temps[faction]['normal_serials']
		local checks = cfg.player_aiprofiles.skills

		for _, serial in pairs(serials) do
			-- logd(">>>>serial:%s", inspect(serial))
			-- logd(">>>>skillSet:%s", inspect(skillSet))
			local req_buf = serial['req_buf']
			local skills = serial['skills']
			local usable = true
			local realSkills = {}
			for _, skill in pairs(skills) do
				local sid = skill['sid']
				local realSid = sid
				if checks[sid] then
					local cat = skill['cat']
					if cat == 'rune' then
						local runes = cfg.skills[sid]['runes']
						local find = false
            if table.contains(skillSet.fist_up_set, sid) then
              find = true
            else
              for _, tid in pairs(runes) do
                if table.contains(skillSet.fist_up_set, tid) then
                  find = true
                  realSid = tid
                  break
                end
              end
            end

						if not find then
							usable = false
							break
						end

					elseif cat == 'level' then
						local find = false
            if table.contains(skillSet.fist_up_set, sid) then
              find = true
            else
  						local cfgSkill = cfg.skills[sid]
  						while(cfgSkill) do
  							local id = cfgSkill.tid
  							if table.contains(skillSet.foot_set, id) then
  								find = true
  								realSid = id
  								break
  							end
  							cfgSkill = cfg.skills[cfgSkill.next_id]
  						end
            end

						if not find then
              -- logd(">>>>usable 222")
							usable = false
							break
						end

					else
						if not table.contains(skillSet.fist_up_set, sid) and skillSet.fist_down ~= sid then
							usable = false
							break
						end
					end
				end

				table.insert(realSkills, {sid = realSid, last_hit = skill['last_hit'], weight = skill['weight']})
			end

			if usable then
				local d = {skills = realSkills,
									 queued = serial.queued,
									 weight = serial.weight,
									 total_weight = serial.total_weight}

				if serial['req_buf'] then
					d['req_buf'] = serial['req_buf']
					table.insert(bufs, d)
				else
					table.insert(normals, d)
				end
			end
		end
	end
	return self.serialSkills
end

--[[
    方法: ply_set_normal_skills
    别名: ply 过滤出当前可用的技能序列
    描述: 根据当前配置的技能，检查所有支持的技能连技中可用的
    		 形成一个可用集合，然后再根据当前的情况来过滤一些不可用的
    		 例如：御剑无双后技能替换的效果，需要检查当前身上的无双buff，然后将原来的技能集合替换成无双下的技能连技
    参数: 无
]]
m.mnhs["ply_set_normal_skills"] = "普通技能"
function m:ply_set_normal_skills(node)
	if self:_is_dead() then
    return m.fail
  end

  if self:_proc_fire_sum_skill() then
    return m.success
  end

	self.usables = self.usables or {}
	table.clear(self.usables)

  local serials = self:_get_serial_skills()
  local weight = 0
  local normals = serials.normals
  local bufs = serials.bufs
  for _, serial in pairs(bufs) do
  	local req_buf = serial['req_buf']
		if self.fighter.model:buffExist(req_buf) then
			table.insert(self.usables, serial)
			weight = weight + serial['weight']
		end
  end

  if weight <= 0 then
  	for _, serial in pairs(normals) do
  		table.insert(self.usables, serial)
  		weight = weight + serial['weight']
  	end
  end

  -- logd(">>>>weight:%s usables:%s", inspect(weight), inspect(self.usables))
  local i = MathUtil.randomByWeight(weight, self.usables)
  local serial = self.usables[i]
  -- serial =  {
  --   queued = false,
  --   skills = { {
  --       sid = "ski3021200",
  --       weight = 0
  --     } },
  --   total_weight = 0
  -- }
  -- logd("quit serial:%s", inspect(serial))
  local skills = serial.skills
	local sid = nil
  if serial.queued then
    sid = skills[1].sid
    self:bd_set_skill_queue(skills)
  else
    local i = 1
    if #skills > 1 then
      if serial.total_weight == 0 then
        i = math.random(#skills)
      else
        i = MathUtil.randomByWeight(serial.total_weight, skills)
      end
    end
    sid = skills[i].sid
  end

  self:bd_set_cur_skill(sid)

	return m.success
end


--写死狐妖没有召唤出普通狐狸 就召唤一次
local summons = {"ene8100019","ene9000000","ene9000001","ene9000002","ene9000003"}
function m:_proc_fire_sum_skill()
  -- logd(">>>>self.fighter.model.faction:%s", inspect(self.fighter.model.faction))
  if self.fighter.model.faction == 'fire' then
    local sumSid = 'ski2220041'
    if not self.fighter.model:canCast(sumSid) then
      return false
    end

    local noneSums = (#self.fighter.minionsMgr.minions_pids == 0 )
    local sumDied = true
    for _, tid in pairs(summons) do
      if self.fighter.minionsMgr.minions_num[tid] ~= 0 then
        sumDied = false
        break
      end
    end

    if noneSums or sumDied and self:_can_cast(sumSid) then
      self:bd_set_cur_skill(sumSid)
      return true
    end
  end
  return false
end
