class('AIEnemyAgent', function(self, env, fighter)
end, AIAgent)

local m = AIEnemyAgent

function m:init()
  AIAgent.init(self)

  self.bd.hitted_count = 0            --记录被击次数
  self.bd.hitted_trigger_count = nil  --被击多少次触发

  self:initSearchRange()
  self:intForTemplate()
end

function m:initHittedReduce()
  local triggers = self.triggers['hit_count']
  if triggers then
    --Hit count trigger only support 1
    local t = triggers[1]
    local c = math.random(t.cfg.cmin, t.cfg.cmax)
    self:bd_set_hitted_trigger_count(c)
  end
end

function m:start_reduce_hitted_count()
  local triggers = self.triggers['hit_count']
  if triggers then
    local t = triggers[1]
    self:stop_reduce_hitted_count()
    if aidbg.debug then
      aidbg.log(0,"[DESIGN] start reduce interval:%s", tostring(t.cfg.interval))
    end
    self.hHitCount = scheduler.schedule(function()
      if aidbg.debug then
        aidbg.log(0, "[DESIGN] dec hit count:%s all:%s", tostring(t.cfg.dec), tostring(self.bd["hitted_count"]))
      end
      self:bd_dec_hitted_count(t.cfg.dec)
    end, t.cfg.interval)
  end
end

function m:stop_reduce_hitted_count()
  if self.hHitCount then
    scheduler.unschedule(self.hHitCount)
    self.hHitCount = nil
  end
end

function m:initSearchRange()
  local tid = self.fighter.config.tid
  local cfgEnemy = cfg.enemies[tid]
  self.extra["search_range"] = cfgEnemy.search_scope
end

function m:intForTemplate()
  local aiid = self.fighter.config.ai_id
  if not aiid:match("^tai") then
    return
  end

  --logd(">>>>>>>aiid"..inspect(aiid))
  self.aiProfile = cfg.aiprofiles[aiid]

  --触发信号标记位，有信号，相应位置为true
  self.extra["signals"] = {}
  for i,v in pairs(self.aiProfile.triggers) do
    table.insert(self.extra["signals"], false)
  end

  --已经触发的信号,经过配置权重排序，不包括正在执行的信号
  self.extra["signaleds"] = {}

  --当前信号,每次只取signaleds中的第一个来执行
  self.extra["cur_signal"] = 0

  --巡逻行为的当前目标点索引
  if self.aiProfile.act_patrol then
    self.extra["cur_patrol"] = 1
  end

  --触发器分类
  self.triggers = {}
  for i,v in pairs(self.aiProfile.triggers) do
    self.triggers[v.category] = self.triggers[v.category] or {}
    table.insert(self.triggers[v.category], {cfg = v, index = i})
  end

  --注册触发器(定时的除外)
  self.handleHPChange = function()
    if not self.triggers['hp'] then return end
    local trigged = false
    for i,v in pairs(self.triggers['hp']) do
      local key = "hp_rate_triggerd_"..v.cfg.rate
      if not self.extra[key] then
        local full_hp =  self.fighter.model:clampedAttr('hp')
        local cur_hp = self.fighter.model:clampedAttr('cur_hp')
        local rate = cur_hp / full_hp
        if v.cfg.rate >= rate then
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

  self.handleFallDown = function()
    if not self.triggers['get_up'] then return end
    local trigged = false
    for i,v in pairs(self.triggers['get_up']) do
      self:arrangeSignals(v.index)
      self.env.aic:manualStep(self.btid)
    end

    if trigged then
      self.env.aic:manualStep(self.btid)
    end
  end

  self.handleHitted = function(attackerInfo)
    if self.triggers['hit'] then
      local triggers = self.triggers['hit']
      local totalWeight = 0
      each(function(v) totalWeight = totalWeight + v.cfg.weight end, triggers)
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
      return
    end

    if self.triggers['hit_count'] then
      local v = self.triggers['hit_count'][1]
      if attackerInfo.atkLua and attackerInfo.atkLua.btype and attackerInfo.atkLua.btype.hit_restore then
        local curCount = self:bd_inc_hitted_count()
        if aidbg.debug then
          aidbg.log(0, "[DESIGN] inc hit count:%s all:%s", tostring(1), tostring(curCount))
        end
        local triCount = self:bd_get_hitted_trigger_count()
        if curCount >= triCount then
          self:bd_dec_hitted_count(triCount)
          self:arrangeSignals(v.index)
          self.env.aic:manualStep(self.btid)
        end
        self:start_reduce_hitted_count()
      end
    end
  end

  self.handleBuffAdd =function(tid)
    if not self.triggers['buff'] then return end
    local trigged = false
    for i,v in pairs(self.triggers['buff']) do
      for j,e in pairs(v.cfg.buffs) do
        -- logd("[buff trigger] check e:%s", inspect(e))
        if e == tid then
           -- logd("[buff trigger] check exist:%s", inspect(e))
           self:arrangeSignals(v.index)
           trigged = true
           break
        end
      end
    end

    if trigged then
      self.env.aic:manualStep(self.btid)
    end
  end

  self.fighter:signal('change_hp'):add(self.handleHPChange)
  self.fighter:signal('fall_down'):add(self.handleFallDown)
  self.fighter:signal('buff_add'):add(self.handleBuffAdd)
  self.fighter:signal('hitted'):add(self.handleHitted)

  self:initHittedReduce()
end

function m:clearSignals()
  self.fighter:signal('change_hp'):remove(self.handleHPChange)
  self.fighter:signal('fall_down'):remove(self.handleFallDown)
  self.fighter:signal('buff_add'):remove(self.handleBuffAdd)
  self.fighter:signal('hitted'):remove(self.handleHitted)
end

function m:exit()
  self:clearSignals()
  self:stop_reduce_hitted_count()

  AIAgent.exit(self)
end

--interface of attributes

--end attributes

--interface of bd
function m:bd_set_strike_time(tm)
  self.bd["strike_time"] = tm
end

function m:bd_get_strike_time(tm)
  return self.bd["strike_time"] or 0
end

function m:bd_set_skill_immediate(immediate)
  immediate = not not immediate
  self.bd["skill_immediate"] = immediate
end

function m:bd_get_skill_immediate(immediate)
  return self.bd["skill_immediate"]
end

function m:bd_set_hover_action(action)
  self.bd["hover_action"] = action
end

function m:bd_get_hover_action()
  return self.bd["hover_action"]
end

function m:bd_set_hitted_trigger_count(c)
  self.bd["hitted_trigger_count"] = c
end

function m:bd_get_hitted_trigger_count()
  return self.bd["hitted_trigger_count"]
end

function m:bd_get_hitted_count()
  return self.bd["hitted_count"]
end

function m:bd_inc_hitted_count()
  self.bd["hitted_count"] = self.bd["hitted_count"] + 1
  return self.bd["hitted_count"]
end

function m:bd_dec_hitted_count(c)
  self.bd["hitted_count"] = self.bd["hitted_count"] - c
  if self.bd["hitted_count"] < 0 then
    self.bd["hitted_count"] = 0
  end
end
--interface of agent

m.mnhs = {}


--[[
    方法: random_skill
    别名: 随机选择技能
    描述: 从怪物配置的技能中随机选择一个当前要释放的技能
    参数: 无
]]
m.mnhs["random_skill"] = "随机技能"
function m:random_skill(node)
  local ids = self.fighter.config.skill_list
  if #ids == 0 then
    return m.fail
  end

  local i = math.random(1, #ids)
  local sid = ids[i]
  self:bd_set_cur_skill(sid)
  self:bd_set_cur_skill_info(nil)

  local speed = cfg.skills[sid].move_speed
  self:bd_set_move_speed(speed)
  return m.success
end


--[[
    方法: buffs_exist
    别名: buffs存在否？
    描述: 查询给定的buff列表中的buff，是否存在，有一个存在就返回成功
    参数: arg1 - buff列表，逗号分隔 [string]
]]
m.mnhs["buffs_exist"] = "有buff?"
function m:buffs_exist(node, buffIds)
  if self:_is_dead() then
    return m.fail
  end

  local buffs = string.split(buffIds, ',')
  if #buffs == 0 then return m.fail end

  for i,v in pairs(buffs) do
    if self.fighter.model and
       self.fighter.model:buffExist(v) then
      return m.success
    end
  end

  return m.fail
end

--[[
    方法: tmp_trigger_queued_attack
    别名: Tmp 多段攻击
    描述: 如果没有队列的技能就释放之前设置的技能；
          如果有队列的技能则释放之前队列起来的技能列表，当前技能不释放，直接设空；
          第一个技能需要按照强制释放保证释放成功，然后一直检测排队技能是否可以释放；
          如果过程中发生被击打断的情况，返回成功；
          如果到了切招点可以释放后续技能，就释放；
          所有技能释放完成后返回成功
    参数: 无
]]
m.mnhs["tmp_trigger_queued_attack"] = "tmp多段攻击"
function m:tmp_trigger_queued_attack(node)
  if aidbg.debug then
    aidbg.log(0, "[QSKILL] tmp trigger queuedattack")
  end

  local function clear()
    if aidbg.debug then
      aidbg.log(0, "[DESIGN]<color='#bb3925'>多段攻击完成后删除trigger</color>: %s", inspect(self.extra["signaleds"][1]))
    end
    table.remove(self.extra["signaleds"], 1)
    self:reset_cur_signal(node)
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
  if aidbg.debug then
    aidbg.log(0, "[QSKILL] skills:%s", peek(skills))
  end
  if not skills or #skills == 0 then
    local suc = self:tmp_trigger_attack(node)
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
  self:bd_set_cur_skill_info(nil)
  self:bd_set_move_speed(nil)

  local i = self:bd_get_sq_index() or 1
  if i == 1 then
    self:bd_set_sq_index(1)
    if not self.fighter:canCast()  then
      return m.running
    end

    local sid = skills[1].sid
    local curState = self.fighter.psm.curState
    if not curState:canCast(sid) then
      return m.running
    end

    if not self:doQueuedSkill(1) then
      clear()
      self:cleanupSkillQueue()
      return m.running
    else
      if aidbg.debug then
        aidbg.log(0, "[DESIGN][%s] <color='#ff7e20'>触发队列攻击开始</color>, skills: %s", inspect(self.fighter.id), inspect(skills))
      end
      --进入真正释放技能的trigger才置顶不可切换
      self.inAttackingTrigger = self.extra["cur_trigger"]
    end

    self:bd_set_sq_index(2)
    self:bd_set_sq_end(false)
    self:scheduleSkillQueue()
    return m.running
  else
    return m.running
  end
end

--[[
    方法: tmp_trigger_attack
    别名: Tmp 攻击
    描述: 释放触发信号释放的技能，内部检测是否可施法，如果不能会一直等到可以施法为止，
          但是如果施法过程中，被击等原因造成施法不能的过程中，有其他权重更高的技能被触发
          那么，本次施法将被打断（返回成功），信号不清除，仍然在
    参数: 无
]]
m.mnhs["tmp_trigger_attack"] = "tmp攻击"
function m:tmp_trigger_attack(node)
  local function clear()
    if aidbg.debug then
      aidbg.log(0, "[DESIGN]<color='#bb3925'>单一攻击完成后删除trigger</color>: %s %s", inspect(self.extra["signaleds"][1]), debug.traceback())
    end
    table.remove(self.extra["signaleds"], 1)
    self:reset_cur_signal(node)
    self.inAttackingTrigger = nil
    self:bd_set_skill_start(nil)
    self:bd_set_cur_skill(nil)
    self:bd_set_cur_skill_info(nil)
    self:bd_set_move_speed(nil)
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

    if self:bd_get_face_target() then
      local pos2 = target:position()
      local pos1 = self.fighter:position()
      local dir = Vector3.Normalized(pos2 - pos1)
      self.fighter:setForward(dir)
    end

    if not self.fighter:canCast()  then
      return m.running
    end

    local curState = self.fighter.psm.curState
    if not curState:canCast(sid) then
      return m.running
    end

    local action = SkillActionFactory.make(self.fighter, sid)
    if not self.fighter.model:canCast(action.data.tid) then
      return m.running
    end
    self:sendAction(action)

    if aidbg.debug then
      aidbg.log(0, "[DESIGN][%s] <color='#bb3925'>释放单一技能</color>: %s", inspect(self.fighter.id), inspect(sid))
    end

    self:bd_set_skill_start(engine.time())
    ks:resetSignalVars()
    return m.running
  end

  if ks.interupted then
    clear()
    return m.success
  end

  if ks.skillExit and ks.skillTid == sid then
    clear()
    return m.success
  end

  --如果在ai的下一个step中没有检测到技能释放 就说明没有释放成功
  if not ks.skillEnter then
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

function m:isCurSignal(index)
  local i = self.extra['signaleds'][1]
  -- logd(">>>>>>>index"..inspect(index))
  -- logd(">>>>>>>i"..inspect(i))
  -- logd(">>>>>>>self.extra['signaleds']"..inspect(self.extra['signaleds']))
  if not i then return false end
  return i == index
end

--[[
    方法: tmp_cur_sig_changed
    别名: Tmp 当前的信号有变？
    描述: 信号触发的技能，如果不是立刻释放的话，在移动过程中，
          如果当前信号变成别的信号了，该方法用于检测这种信号变化
    参数: 无
]]
m.mnhs["tmp_cur_sig_changed"] = "sig_changed?"
function m:tmp_cur_sig_changed(node)
  local i = self.extra["cur_trigger"]
  if self:isCurSignal(i) then
    return m.fail
  end
  return m.success
end

function m:arrangeSignals(index)
  if self.extra["signals"][index] then
    if aidbg.debug then
      aidbg.log(0, "[DESIGN][%s] <color='#9ed6ed'>已经触发</color> index:%s trigger:<color='#24b93d'>%s</color>", inspect(self.fighter.id), inspect(index), inspect(self.aiProfile.triggers[index].category))
    end
    return
  end --已经有信号了不进入信号队列
  self.extra["signals"][index] = true
  -- logd(">>>>>>>check index"..inspect(index))
  if table.contains(self.extra["signaleds"], index) then
    if aidbg.debug then
      aidbg.log(0, "[DESIGN][%s] <color='#9ed6ed'>已存在信号触发</color> index:%s trigger:<color='#24b93d'>%s</color>", inspect(self.fighter.id), inspect(index), inspect(self.aiProfile.triggers[index].category))
    end
    return
  end --已在队列不重入

  if aidbg.debug then
    aidbg.log(0, "[DESIGN][%s] <color='#9ed6ed'>信号触发</color> index:%s trigger:<color='#24b93d'>%s</color>", inspect(self.fighter.id), inspect(index), inspect(self.aiProfile.triggers[index].category))
  end

  table.insert(self.extra["signaleds"], index)
  table.sort(self.extra["signaleds"], function(a, b)
      --已经在释放技能的永远排在第一个
      -- if a == self.inAttackingTrigger then return true end
      -- if b == self.inAttackingTrigger then return false end
      return self.aiProfile.triggers[a].weight > self.aiProfile.triggers[b].weight
    end)
  -- logd(">>>>>>>check "..inspect(self.extra["signaleds"]))
end

--[[
    方法: tmp_check_signals
    别名: Tmp 检查并设置当前的信号
    描述: 模板模式下的敌人ai,通过该方法来集中检测触发条件，
          1.如果某个条件触发了，就标记相应的信号为true,
          2.并将该信号送入待处理信号队列，并根据配置的权重进行排序，
          3.后续处理在队列不为空的时候，总是取第一个信号出来处理，
          4.处理完毕后，标记相应的信号为false
          5.除了定时触发外，触发时机改为被动等待signal通知，得到事件通知后，
            主动驱动一次ai step
    参数: 无
]]
m.mnhs["tmp_check_signals"] = "CKSignals"
function m:tmp_check_signals(node)
  if not self.aiProfile then
    return m.fail
  end

  if self:_is_dead() then
    return m.fail
  end

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
        -- logd(">>>>>>>interval"..inspect(interval))
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
    方法: tmp_act_patrol
    别名: Tmp 是否启用巡逻
    描述: 是否启用巡逻
    参数: 无
]]
m.mnhs["tmp_act_patrol"] = "巡逻?"
function m:tmp_act_patrol(node)
  if not self.aiProfile then
    return m.fail
  end

  if self.aiProfile.act_patrol then
    return m.success
  end
  return m.fail
end

--[[
    方法: tmp_set_hover
    别名: Tmp 设置徘徊行为
    描述: 设置徘徊行为
          如果敌人倒地：
          如果徘徊行为1和2中只有一个设置就必出，如果两个都有就随机一个
          hover行为设置在 bd的key hover_action中
          返回成功
          如果敌人未倒地：
          返回失败
          如果未设置徘徊：
          返回失败
    参数: 无
]]
m.mnhs["tmp_set_hover"] = "设置徘徊"
function m:tmp_set_hover(node)
  if not self.aiProfile then
    return m.fail
  end

  if not self.aiProfile.act_hover then
    if aidbg.debug then
      -- aidbg.log(0, "[HOVER] profile no act hover")
    end
    return m.fail
  end

  local target = self:_check_get_target()
  if not target then
    if aidbg.debug then
      aidbg.log(0, "[HOVER] no garget")
    end
    return m.fail
  end

  if target:statebit() ~= cfg.statebits.land then
    if aidbg.debug then
      aidbg.log(0, "[HOVER] target statebit is not land :%s", tostring(target:statebit()))
    end
    return m.fail
  end

  if self.aiProfile.hov_keep and self.aiProfile.hov_egar then
    local i = math.random(2)
    self:bd_set_hover_action(i)
  else
    if self.aiProfile.hov_keep then
      self:bd_set_hover_action(1)
    end

    if self.aiProfile.hov_egar then
      self:bd_set_hover_action(2)
    end
  end
  if aidbg.debug then
    aidbg.log(0, "[HOVER] set hover action :%s", tostring(self:bd_get_hover_action()))
  end
  return m.success
end

--[[
    方法: tmp_hover_test
    别名: Tmp hover行为测试
    描述: 根据行为名字判定该行为是否可执行【away egar】
    参数: arg1 - 行为名 【away | egar】 [string]
]]
m.mnhs["tmp_hover_test"] = "hov?"
function m:tmp_hover_test(node, action)
  local set = self:bd_get_hover_action()
  if aidbg.debug then
    aidbg.log(0, "[HOVER] hover test set:%s action:%s", tostring(set), tostring(action))
  end

  if (action == "egar" and set == 1 ) or
    (action == "away" and set == 2) then
    if aidbg.debug then
      aidbg.log(0, "[HOVER] hover test success")
    end
    return m.success
  end
  return m.fail
end

--[[
    方法: tmp_act_random_walk
    别名: Tmp 是否启用随机移动
    描述: 是否启用随机移动
    参数: 无
]]
m.mnhs["tmp_act_random_walk"] = "随机移动?"
function m:tmp_act_random_walk(node)
  if not self.aiProfile then
    return m.fail
  end
  if self.aiProfile.act_random_walk then
    return m.success
  end
  return m.fail
end

--[[
    方法: tmp_act_stand
    别名: Tmp 是否启用呆立
    描述: 是否启用呆立
    参数: 无
]]
m.mnhs["tmp_act_stand"] = "呆立?"
function m:tmp_act_stand(node)
  if not self.aiProfile then
    return m.fail
  end
  if self.aiProfile.act_stand then
    return m.success
  end
  return m.fail
end

--[[
    方法: tmp_act_animation
    别名: Tmp 是否启用随机休闲
    描述: 是否启用随机休闲
    参数: 无
]]
m.mnhs["tmp_act_animation"] = "随机休闲?"
function m:tmp_act_animation(node)
  if not self.aiProfile then
    return m.fail
  end
  if self.aiProfile.act_amin then
    return m.success
  end
  return m.fail
end

--[[
    方法: tmp_time2_animate
    别名: Tmp 随机休闲时间到
    描述: 随机休闲时间到
    参数: 无
]]
m.mnhs["tmp_time2_animate"] = "休闲"
function m:tmp_time2_animate(node)
  if not self.aiProfile then
    return m.fail
  end

  local now = engine.time()
  if not self.extra["random_anim_interval"] then
    local tmMin = math.round(self.aiProfile.anim_tm_span[1] * 100)
    local tmMax = math.round(self.aiProfile.anim_tm_span[2] * 100)
    self.extra["random_anim_interval"]  = math.random(tmMin, tmMax) / 100
    self.extra["random_anim_start"] = now
  end

  local dt = now - self.extra["random_anim_start"]
  if dt >= self.extra["random_anim_interval"]  then
    self.extra["random_anim_start"]  = now
    return m.success
  end

  return m.fail
end

--[[
    方法: tmp_play_animations
    别名: Tmp 播放随机休闲动作
    描述: 播放随机休闲动作
    参数: 无
]]
m.mnhs["tmp_play_animations"] = "休闲"
function m:tmp_play_animations(node)
  if not self.aiProfile then
    return m.fail
  end

  local tmStart = self:bd_get_tm_start()
  local tmSpan = self:bd_get_tm_span()
  if not tmStart then
    local anims = self.aiProfile.anim_names
    local i = math.random(#anims)
    local clip = anims[i]

    if not clip then
      return m.success
    end

    if not self.fighter:hasAnim(clip) then
      return m.success
    end

    self.fighter:playAnim(clip, 0)
    local tmSpan = self:getClipTime(clip)
    if not tmSpan then
      logd("[AI_IDLE] play animation error:"..tostring(clip))
    end
    local tmStart = engine.time()
    self:bd_set_tm_start(tmStart)
    self:bd_set_tm_span(tmSpan)
    return m.running
  end

  if not tmSpan then
    return m.success
  end

  local now = engine.time()
  local pastTm = now - tmStart
  if pastTm >= tmSpan then
    self:bd_set_tm_start(nil)
    self:bd_set_tm_span(nil)
    return m.success
  end

  return m.running
end



--[[
    方法: tmp_set_movement_patrol
    别名: Tmp 设置移动到当前巡逻目标点
    描述: 模板模式下的巡逻行为，通过该方法，设定移动目标为当前巡逻路径的目标点
          巡逻路径是循环的，循环路径不包含怪物当前位置点（比如脱离战斗时候的坐标点）
    参数: 无
]]
m.mnhs["tmp_set_movement_patrol"] = "patrol点"
function m:tmp_set_movement_patrol(node)
  if not self.aiProfile then
    return m.fail
  end

  if self:_is_dead() then
    return m.fail
  end

  local i = self.extra["cur_patrol"]
  local pt = self.aiProfile.patrol_pts[i]
  local posDst = Vector3(pt[1], 0, pt[3])
  local posSrc =  Vector3.new(self.fighter:position())
  local dir = Vector3.new(Vector3.Normalized(posDst - posSrc))
  local dist2 = MathUtil.dist2(posSrc, posDst)
  local tmStart = engine.time()
  self:bd_set_move_speed(self.aiProfile.patrol_speed)
  self:bd_set_movement(dir, 10, tmStart, posSrc, dist2)

  return m.success
end

--[[
    方法: tmp_check_patrol
    别名: Tmp 检测巡逻点到达
    描述: 模板模式下的巡逻行为，通过该方法检测当前的巡逻目标点是否已经到达？
          如果到达了，就向前推进一个巡逻点
    参数: 无
]]
m.mnhs["tmp_check_patrol"] = "CKPatrol"
function m:tmp_check_patrol(node)
  if not self.aiProfile then
    return m.fail
  end

  if self:_is_dead() then
    return m.fail
  end

  local i = self.extra["cur_patrol"]
  local pt = self.aiProfile.patrol_pts[i]
  local posSrc = self.fighter:position()
  local posDst = Vector3(pt[1], 0, pt[3])
  local dist2 = MathUtil.dist2(posSrc, posDst)
  if dist2 <= 0.5 then
    i = i + 1
    if i > #self.aiProfile.patrol_pts then
      i = 1
    end
    self.extra["cur_patrol"] = i
  end

  return m.success
end

--[[
    方法: tmp_set_random_movement
    别名: Tmp 设置随机移动
    描述: 模板模式下的随机移动行为
    参数: 无
]]
m.mnhs["tmp_set_random_movement"] = "随机移动"
function m:tmp_set_random_movement(node)
  if not self.aiProfile then
    return m.fail
  end

  if self:_is_dead() then
    return m.fail
  end

  local sid = self.fighter.summon_pid
  if not sid then
    return m.fail
  end

  local partner = self.env.cc.findHero(sid)
  if not partner then
    return m.fail
  end

  local center = partner:position()

  local r = self.aiProfile.random_walk_radius
  r = math.round(r * 100)
  local x = center[1] + math.random(-r, r) / 100
  local z = center[3] + math.random(-r, r) / 100

  local ptEnd = Vector3(x, 0, z)
  local dir = Vector3.new(Vector3.Normalize(ptEnd))
  local ptStart = Vector3.new(center)
  local dist2 = MathUtil.dist2(ptStart, ptEnd)
  local tmStart = engine.time()

  self:bd_set_move_speed(self.aiProfile.random_walk_speed)
  self:bd_set_movement(dir, 10, tmStart, ptStart, dist2)

  return m.success
end

--[[
    方法: tmp_set_strike_skill
    别名: Tmp 设置普攻技能
    描述: 设置普攻技能
    参数: 无
]]
m.mnhs["tmp_set_strike_skill"] = "普攻技能"
function m:tmp_set_strike_skill(node)
  if not self.aiProfile then
    return m.fail
  end

  if self:_is_dead() then
    return m.fail
  end

  local skills = self.aiProfile.strike_skills
  local weight = self.aiProfile.total_weight
  -- logd(">>>>>>>weight"..self.fighter.id..":"..inspect(weight))
  -- logd(">>>>>>>skills"..self.fighter.id..":"..inspect(skills))

  if not skills or #skills == 0 then
    loge("[策划同学] [%s]普攻技能数量不要超过一个", inspect(self.aiProfile.tid))
    return m.fail
  end

  if weight == 0 and #skills ~= 1 and not self.aiProfile.strike_queued then
    loge("[策划同学] [%s]普攻技能队列的，但是权重为0是啥意思呢?", inspect(self.aiProfile.tid))
    return m.fail
  end

  local sid = nil
  if self.aiProfile.strike_queued then
    sid = skills[1].sid
    self:bd_set_skill_queue(skills)
  else
    local i = 1
    if #skills > 1 then
      i = MathUtil.randomByWeight(weight, skills)
    end
    sid = skills[i].sid
  end

  if sid == 'all' then
    local ids = self.fighter.config.skill_list
    if #ids == 0 then
      return m.fail
    end

    local i = math.random(1, #ids)
    sid = ids[i]
  end
  -- logd(">>>>>>>skills[i].sid"..self.fighter.id..":"..inspect(skills[i].sid))
  self:bd_set_face_target(self.aiProfile.strkie_face_target)

  local old_sid = self:bd_get_cur_skill(sid)
  self:bd_set_cur_skill(sid)
  if old_sid ~= sid then
    self:bd_set_cur_skill_info(self.aiProfile.clear_cd)
  end
  local speed = cfg.skills[sid].move_speed
  self:bd_set_move_speed(speed)

  return m.success
end

--[[
    方法: tmp_is_strikeable
    别名: Tmp 普攻CD到？
    描述: 普攻冷却时间到了没
    参数: 无
]]
m.mnhs["tmp_is_strikeable"] = "普攻cd?"
function m:tmp_is_strikeable(node)
  local lastTime = self:bd_get_strike_time()
  local now = stime()
  local span = now - lastTime
  local cd = self.fighter.config.strike_cd -- self.aiProfile.strike_cd
  if span < cd then
    return m.fail
  end

  return m.success
end


--[[
    方法: tmp_set_strike_time
    别名: Tmp 记录普攻技能时间
    描述: 记录普攻技能时间
    参数: 无
]]
m.mnhs["tmp_set_strike_time"] = "rc普攻tm"
function m:tmp_set_strike_time(node)
  local now = stime()
  self:bd_set_strike_time(now)
  return m.success
end


--[[
    方法: tmp_set_egar_movement
    别名: Tmp 设置比划移动
    描述: 设置以目标为中心，模板配置的环形区域内的随机点为目标点
    参数: 无
]]
m.mnhs["tmp_set_egar_movement"] = "比划"
function m:tmp_set_egar_movement(node)
  if not self.aiProfile then
    return m.fail
  end

  if self:_is_dead() then
    return m.fail
  end

  local target = self:_check_get_target()
  if not target then
    return m.fail
  end

  if not self.aiProfile.egar_range then
    return m.fail
  end

  local ptCenter = target:position()
  local rMin = self.aiProfile.egar_range[1]
  local rMax = self.aiProfile.egar_range[2]
  local x,z = self:_randomPosition(rMin, rMax, target.radius)
  local ptDst = Vector3(ptCenter[1] + x, ptCenter[2], ptCenter[3] + z)
  local ptSrc = Vector3.new(self.fighter:position())

  local dir = Vector3.new(Vector3.Normalized(ptDst - ptSrc))
  local dist2 = MathUtil.dist2(ptSrc, ptDst)
  local tmStart = engine.time()

  self:bd_set_move_speed(self.aiProfile.egar_speed)
  self:bd_set_movement(dir, 10, tmStart, ptSrc, dist2)
  return m.success
end

--[[
    方法: tmp_set_away_movement
    别名: Tmp 设置远离移动
    描述: 按照模板配置的远离距离和半径设置移动目标点
    参数: 无
]]
m.mnhs["tmp_set_away_movement"] = "远离"
function m:tmp_set_away_movement(node)
  if not self.aiProfile then
    return m.fail
  end

  if self:_is_dead() then
    return m.fail
  end

  local target = self:_check_get_target()
  if not target then
    return m.fail
  end

  local ptTarget = target:position()
  local ptSrc = Vector3.new(self.fighter:position())
  local curDist = MathUtil.distance(ptSrc, ptTarget)
  if not self.aiProfile.keep_dist then
    return m.success
  end

  if curDist >= (self.aiProfile.keep_dist) then
    return m.fail
  end

  local r = math.round(self.aiProfile.keep_radius * 100)
  local x, z = ptTarget[1], ptTarget[3]
  local offset = math.random(0, r) / 100
  local distance = self.aiProfile.keep_dist
  if ptSrc[1] < ptTarget[1] then
    distance = -distance
    offset = -offset
  end
  x = x + distance + offset
  z = z + math.random(-r, r) / 100

  local ptDst = Vector3(x, 0, z)
  local dir = Vector3.new(Vector3.Normalized(ptDst - ptSrc))
  local dist2 = MathUtil.dist2(ptSrc, ptDst)

  --test hit wall
  if self:_hit_something(dir, 1)  then --默认小于1m的距离内有墙就反方向移动
    dir[1]    = -dir[1]
    ptDst[1]  = ptTarget[1] - distance - offset
    dist2 = MathUtil.dist2(ptSrc, ptDst)
  end

  local tmStart = engine.time()
  self:bd_set_move_speed(self.aiProfile.keep_speed)
  self:bd_set_movement(dir, 10, tmStart, ptSrc, dist2, false)

  return m.success
end

--[[
    方法: tmp_away_enough
    别名: Tmp 远离满足
    描述: 按照模板配置的远离距离是否到达
    参数: 无
]]
m.mnhs["tmp_away_enough"] = "远离"
function m:tmp_away_enough(node)
  if not self.aiProfile then
    return m.fail
  end

  if self:_is_dead() then
    return m.fail
  end

  local ptSrc = self.fighter:position()
  local ptTarget = target:position()
  local dist =  MathUtil.distance(ptSrc, ptTarget)
  if dist >= self.aiProfile.keep_dist or 0 then
    return m.success
  end

  return m.fail
end

--[[
    方法: tmp_set_close_movement
    别名: Tmp 设置靠近友方
    描述: 按照模板配置靠近最近的友方
    参数: 无
]]
m.mnhs["tmp_set_close_movement"] = "靠近"
function m:tmp_set_close_movement(node)
  if not self.aiProfile then
    return m.fail
  end

  if self:_is_dead() then
    return m.fail
  end

  local posMe = self.fighter:position()
  local minst = nil
  local target = nil
  for i,v in cc.iterHeroes(self.fighter.side) do
    if v.id ~= self.fighter.id then
      local pos = v:position()
      local dist2 = MathUtil.dist2(posMe, pos)
      minst = minst or dist2
      target = target or v
      if minst > dist2 then
        minst = dist2
        target = v
      end
    end
  end

  if not target then
    return m.fail
  end

  local rMin = self.aiProfile.close_range[1]
  local rMax = self.aiProfile.close_range[2]

  local x,z = self:_randomPosition(rMin, rMax, target.radius)

  local ptCenter = target:position()
  local ptDst = Vector3(ptCenter[1] + x, ptCenter[2], ptCenter[3] + z)
  local ptSrc = Vector3.new(posMe)

  local dir = Vector3.new(Vector3.Normalized(ptDst - ptSrc))
  local dist2 = MathUtil.dist2(ptSrc, ptDst)
  local tmStart = engine.time()
  self:bd_set_move_speed(self.aiProfile.close_speed)
  self:bd_set_movement(dir, 10, tmStart, ptSrc, dist2, false)
  return m.success
end

--[[
    方法: tmp_has_trigger
    别名: Tmp 有触发？
    描述: 是否有触发器触发了
    参数: 无
]]
m.mnhs["tmp_has_trigger"] = "triggered?"
function m:tmp_has_trigger(node)
  if #self.extra["signaleds"] > 0 then
    return m.success
  end
  return m.fail
end

--[[
    方法: tmp_get_signaled_trigger
    别名: Tmp 获取一个有信号的触发器
    描述: 获取一个有信号的触发器，
          从排序过的信号队列中取出第一个信号，作为当前工作信号
    参数: 无
]]
m.mnhs["tmp_get_signaled_trigger"] = "signal?"
function m:tmp_get_signaled_trigger(node)
  if #self.extra["signaleds"] == 0 then
    return m.fail
  end
  -- logd(">>>>>>>self.extra['signaleds'][1]"..inspect(self.extra['signaleds'][1]))
  self.extra["cur_trigger"] = self.extra["signaleds"][1]
  -- logd("[buff trigger] %s Get signaled trigger index:%s trigger:%s", tostring(self.fighter.id), inspect(self.extra["cur_trigger"]), inspect(self.aiProfile.triggers[self.extra["cur_trigger"]]))

  if aidbg.debug then
    aidbg.log(0, "[DESIGN] Get signaled trigger index:%s trigger:%s", inspect(self.extra["cur_trigger"]), inspect(self.aiProfile.triggers[self.extra["cur_trigger"]]))
  end
  --Signal remove process after skill release successful

  return m.success
end

function m:reset_cur_signal(node)
  local i = self.extra["cur_trigger"]
  -- logd("[buff trigger] reset signal i:%s", tostring(self.fighter.id), inspect(i))
  -- aidbg.logPath(node)
  self.extra["cur_trigger"] = nil
  if i then
    self.extra["signals"][i] = false
    if self.aiProfile.triggers[i].category == "timing" then
      local key = "trigger_tm_start"..i
      local now = engine.time()
      self.extra[key] = now
    end
  end
  self:bd_set_skill_immediate(false)

  return m.success
end

--[[
    方法: tmp_is_cur_skill_expired
    别名: Tmp 当前技能是否已超时
    描述: 当前的技能是否已经超时
    参数: 无
]]
m.mnhs["tmp_is_cur_skill_expired"] = "当前的技能是否已经超时"
function m:tmp_is_cur_skill_expired(node)
  local info = self:bd_get_cur_skill_info()
  if info == nil then
    return m.fail
  end
  if info.cd == nil then
    return m.fail
  end
  local now = engine.time()
  if now - info.tm > info.cd then
    return m.success
  end
  return m.fail
end

--[[
    方法: tmp_clear_trigger_skill
    别名: Tmp 清除超时的trigger skill
    描述: 清除超时的trigger skill
    参数: 无
]]
m.mnhs["tmp_clear_trigger_skill"] = "清除超时的trigger skill"
function m:tmp_clear_trigger_skill(node)
  local function clear()
    if aidbg.debug then
      aidbg.log(0, "[DESIGN]<color='#bb3925'>检查到技能超时后删除trigger</color>: %s", inspect(self.extra["signaleds"][1]))
    end
    table.remove(self.extra["signaleds"], 1)
    self:reset_cur_signal(node)
    self.inAttackingTrigger = nil
    self.fighter.keyState:resetSignalVars()
  end
  clear()
  self:cleanupSkillQueue()
  self:bd_set_cur_skill(nil)
  self:bd_set_move_speed(nil)
  self:bd_set_cur_skill_info(nil)
  return m.success
end

--[[
    方法: tmp_clear_strike_skill
    别名: Tmp 清除超时的普攻
    描述: 清除超时的普攻
    参数: 无
]]
m.mnhs["tmp_clear_strike_skill"] = "清除超时的普攻"
function m:tmp_clear_strike_skill(node)
  self:cleanupSkillQueue()
  self:bd_set_cur_skill(nil)
  self:bd_set_move_speed(nil)
  self:bd_set_cur_skill_info(nil)
  local now = stime()
  self:bd_set_strike_time(now)
  return m.success
end


--[[
    方法: tmp_set_cur_trigger_skill
    别名: Tmp 设置当前触发的技能
    描述: 设置当前触发的技能
    参数: 无
]]
m.mnhs["tmp_set_cur_trigger_skill"] = "triSkill?"
function m:tmp_set_cur_trigger_skill(node)
  local i = self.extra["cur_trigger"]
  if aidbg.debug then
    aidbg.log(0,"[DESIGN] 设置当前触发的技能 index:%s signaleds:%s", inspect(i), inspect(self.extra["signaleds"]))
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
    local si = math.random(#profile.skills)
    sid = profile.skills[si]
    if sid == 'all' then
      local ids = self.fighter.config.skill_list
      if #ids == 0 then
        return m.fail
      end

      local i = math.random(1, #ids)
      sid = ids[i]
    end
  end

  local old_sid = self:bd_get_cur_skill()
  self:bd_set_skill_immediate(profile.immediate)
  self:bd_set_cur_skill(sid)

  self:bd_set_face_target(profile.face_target)

  if old_sid ~= sid then
    self:bd_set_cur_skill_info(profile.clear_cd)
  end

  local speed = cfg.skills[sid].move_speed
  self:bd_set_move_speed(speed)

  return m.success
end

--[[
    方法: tmp_is_trigger_skill_immediatly
    别名: Tmp 是否立刻释放
    描述: 当前触发的技能是否需要立刻释放
    参数: 无
]]
m.mnhs["tmp_is_trigger_skill_immediatly"] = "immediate?"
function m:tmp_is_trigger_skill_immediatly(node)
  local immediate = self:bd_get_skill_immediate()
  -- logd(">>>>>>>immediate"..inspect(immediate))
  if immediate then
    return m.success
  end
  return m.fail
end

--[[
    方法: tmp_far_from_summoner
    别名: Tmp 是否需要靠近主人
    描述: 是否离召唤者太远,需要靠近主人，或者没有目标，并且在主人周边最大半径以外
    参数: 无
]]
m.mnhs["tmp_far_from_summoner"] = "far?"
function m:tmp_far_from_summoner(node)
  if not self.aiProfile then
    return m.fail
  end

  local dist2 = self:attr_summoner_dist2()
  local d = self.aiProfile.sum_dist or 5
  local d2 = d * d
  if d2 < dist2 then
    return m.success
  end

  local target = self:_check_get_target()
  if not target then
    local maxDist = self.aiProfile.sum_dist_max
    if maxDist and dist2 >= (maxDist * maxDist) then
      return m.success
    end
  end

  return m.fail
end

--[[
    方法: tmp_set_movement_assist_summoner
    别名: Tmp 设置移动朝辅助位置
    描述: 移动到辅助技能可以释放的召唤者最近的位置，以便释放辅助技能
    参数: 无
]]
m.mnhs["tmp_set_movement_assist_summoner"] = "mvasmer?"
function m:tmp_set_movement_assist_summoner(node)
  if not self.aiProfile then
    return m.fail
  end

  local sid = self.fighter.summon_pid
  if not sid then
    return m.fail
  end

  local summoner = self.env.cc.findHero(sid)
  if not summoner then
    return m.fail
  end

  local sid = self:bd_get_cur_skill()
  if not sid then
    return m.fail
  end

  local s = cfg:skill(sid)
  local rgn = s["use_dist"]

  local pos2 = summoner:position()
  local pos1 = self.fighter:position()

  if pos1[1] > pos2[1] then
    pos2[1] = pos2[1] + rgn + summoner.radius - 0.3
  else
    pos2[1] = pos2[1] - rgn - summoner.radius + 0.3
  end

  local dir = Vector3.new(Vector3.Normalized(pos2 - pos1))
  local dist = MathUtil.dist2(pos1, pos2)
  local tmStart = engine.time()
  self:bd_set_move_speed(self.aiProfile.assist_speed)
  self:bd_set_movement(dir, 10, tmStart, Vector3.new(pos1), dist)

  return m.success
end

--[[
    方法: tmp_set_movement_to_summoner
    别名: Tmp 设置移动朝召唤出自己的单位
    描述: 移动到模板配置的玩家周围环形位置
    参数: 无
]]
m.mnhs["tmp_set_movement_to_summoner"] = "mv2smer?"
function m:tmp_set_movement_to_summoner(node)
  if not self.aiProfile then
    return m.fail
  end

  local sid = self.fighter.summon_pid
  if not sid then
    return m.fail
  end

  local summoner = self.env.cc.findHero(sid)
  if not summoner then
    return m.fail
  end

  local rMin = self.aiProfile.sum_dist_min or 5
  local rMax = self.aiProfile.sum_dist_max or 10

  local x,z = self:_randomPosition(rMin, rMax, summoner.radius)
  local ptCenter = summoner:position()
  local ptDst = Vector3(ptCenter[1] + x, ptCenter[2], ptCenter[3] + z)
  local ptSrc = Vector3.new(self.fighter:position())
  local dir = Vector3.new(Vector3.Normalized(ptDst - ptSrc))
  local dist = MathUtil.dist2(ptSrc, ptDst)

  self:bd_set_move_speed(self.aiProfile.assist_close_speed)
  self:bd_set_movement(dir, 0, 0, ptSrc, dist, false)
  return m.success
end

--[[
    方法: tmp_act_assist
    别名: Tmp 是否启用辅助
    描述: 是否启用辅助
    参数: 无
]]
m.mnhs["tmp_act_assist"] = "辅助?"
function m:tmp_act_assist(node)
  if not self.aiProfile then
    return m.fail
  end
  if self.aiProfile.act_assist then
    return m.success
  end
  return m.fail
end

--[[
    方法: tmp_set_assist_skill
    别名: Tmp 设置辅助技能
    描述: 设置辅助技能
    参数: 无
]]
m.mnhs["tmp_set_assist_skill"] = "辅助技能"
function m:tmp_set_assist_skill(node)
  if not self.aiProfile then
    return m.fail
  end

  if self:_is_dead() then
    return m.fail
  end

  local skills = self.aiProfile.assist_skills
  local i = math.random(#skills)
  local sid = skills[i]
  self:bd_set_cur_skill(sid)
  self:bd_set_cur_skill_info(nil)

  local speed = cfg.skills[sid].move_speed
  self:bd_set_move_speed(speed)

  return m.success
end

--[[
    方法: tmp_act_static
    别名: Tmp 是否启用原地不动
    描述: 是否启用原地不动，不随玩家移动更改朝向
    参数: 无
]]
m.mnhs["tmp_act_static"] = "待命?"
function m:tmp_act_static(node)
  if not self.aiProfile then
    return m.fail
  end
  if self.aiProfile.act_static then
    return m.success
  end
  return m.fail
end

--[[
    方法: tmp_act_hold
    别名: Tmp 是否启用原地待命
    描述: 是否启用原地待命
    参数: 无
]]
m.mnhs["tmp_act_hold"] = "待命?"
function m:tmp_act_hold(node)
  if not self.aiProfile then
    return m.fail
  end
  if self.aiProfile.act_hold then
    return m.success
  end
  return m.fail
end


--[[
    方法: tmp_hold_static
    别名: Tmp 原地不动一段时间
    描述: 原地不动一段时间，也不随玩家改变方向
    参数: 无
]]
m.mnhs["tmp_hold_static"] = "原地待命"
function m:tmp_hold_static(node)
  if not self.aiProfile then
    return m.fail
  end

  if self:_is_dead() then
    return m.fail
  end

  local tmSpan, tmStart = self:bd_get_hold_static()
  if not tmStart then
    tmStart = engine.time()
    tmSpan = self.aiProfile.static_tm_span
    self:bd_set_hold_static(tmSpan, tmStart)

    if self.aiProfile.static_anim_set then
      local i = math.random(#self.aiProfile.static_anim_set)
      local anim = self.aiProfile.static_anim_set[i]
      self.fighter:setForceIdleAnimation(anim)
    end

    local action = ActionFactory.makeIdle()
    action:setMoveData(self.fighter)
    self:sendAction(action)
  end

  local now = engine.time()
  local elapse = now - tmStart
  if elapse < tmSpan then
    return m.running
  else
    self:bd_set_hold_static(nil, nil)
    return m.success
  end
end


--[[
    方法: tmp_hold_place
    别名: Tmp 原地待命一段时间
    描述: 原地待命一段时间
    参数: 无
]]
m.mnhs["tmp_hold_place"] = "原地待命"
function m:tmp_hold_place(node)
  if not self.aiProfile then
    return m.fail
  end

  if self:_is_dead() then
    return m.fail
  end

  local tmSpan, tmStart = self:bd_get_hold_place()
  if not tmStart then
    -- logd(">>>>>>>hold start")
    tmStart = engine.time()
    tmSpan = self.aiProfile.hold_tm_span
    self:bd_set_hold_place(tmSpan, tmStart)

    if self.aiProfile.hold_anim_set then
      local i = math.random(#self.aiProfile.hold_anim_set)
      local anim = self.aiProfile.hold_anim_set[i]
      -- logd(">>>>>>>anim"..inspect(anim))
      self.fighter:setForceIdleAnimation(anim)
    end

    local action = ActionFactory.makeIdle()
    action:setMoveData(self.fighter)
    self:sendAction(action)
  end

  local now = engine.time()
  local elapse = now - tmStart
  if elapse < tmSpan then
    local faceDir = self.fighter:forward()
    local target = self:_check_get_target()
    if target then
      local ptTar = target:position()
      local ptSrc = self.fighter:position()
      local dir = Vector3.Normalized(ptTar - ptSrc)
      local a = dir[1] - faceDir[1]
      if a < -1 or a >= 1 then
        local action = ActionFactory.makeTurn()
        action:setMoveData(self.fighter, ptSrc, dir, dir)
        self:sendAction(action)
        -- self.fighter:setForward(dir)
      end
    end
    return m.running
  else
    -- logd(">>>>>>>hold complete")
    self:bd_set_hold_place(nil, nil)
    return m.success
  end
end


table.merge(AIAgent.mnhs, m.mnhs)



--internal method
--name 支持:
--strike  主动攻击
--egar    比划不出手，在敌人周围晃悠
--keep    远离敌人
--close   靠近最近的队友
--static  原地不动
--assist  辅助技能
--hold    原地待命
function m:getWeight(name)
  if name == "strike" then
    if not self.aiProfile.act_strike then return 0 end
    return self.aiProfile.strike_weight or 0
  elseif name == "egar" then
    if not self.aiProfile.act_egar then return 0 end
    if not self.aiProfile.egar_range then return 0 end
    return self.aiProfile.egar_weight or 0
  elseif name == "keep" then
    if not self.aiProfile.act_keep then return 0 end
    if not self.aiProfile.keep_dist then return 0 end
    if not self.aiProfile.keep_radius then return 0 end
    return self.aiProfile.keep_weight or 0
  elseif name == "close" then
    if not self.aiProfile.act_close then return 0 end
    if not self.aiProfile.close_range then return 0 end
    if #self.aiProfile.close_range == 0 then return 0 end
    return self.aiProfile.close_weight or 0
  elseif name == "assist" then
    if not self.aiProfile.act_assist then return 0 end
    return self.aiProfile.assist_weight or 0
  elseif name == "hold" then
    if not self.aiProfile.act_hold then return 0 end
    return self.aiProfile.hold_weight or 0
  elseif name == 'static' then
    if not self.aiProfile.act_static then return 0 end
    return self.aiProfile.static_weight or 0
  end
end

--[[
    方法: tmp_set_buffor_as_target
    别名: Tmp 携带buff者为目标
    描述: 设置携带有特定buff者为目标
    参数: 无
]]
m.mnhs["tmp_set_buffor_as_target"] = "buffor为目标"
function m:tmp_set_buffor_as_target(node)
  if not self.aiProfile then
    return m.fail
  end

  local buffTid = self.aiProfile['ovsrv_buff']
  if not buffTid then
    return m.fail
  end

  if self:_is_dead() then
    return m.fail
  end

   local targetId = nil
  local sides = cc.enemySides(self.fighter.side)
  for i,v in pairs(sides) do
    targetId = cc.getAiObsrvBuffTarget(buffTid, v)
    if targetId then
      break
    end
  end

  if not targetId then
    return m.fail
  end

  local target = cc.findHero(targetId)
  self:bd_set_target(target)
  if aidbg.debug then
    aidbg.log(0, "With buff["..tostring(buffTid).."] target setted", aidbg.INFO)
  end
  return m.success
end

--[[
    方法: tmp_set_attacker_as_target_probably
    别名: Tmp 概率攻击者为目标
    描述: 如果没有目标就设置攻击者为目标
          如果有目标，根据配置的概率，将最后一次攻击的单位设置为目标单位
    参数: 无
]]
m.mnhs["tmp_set_attacker_as_target_probably"] = "atker为目标probably"
function m:tmp_set_attacker_as_target_probably(node)
  if not self.aiProfile then
    return m.fail
  end

  if self:_is_dead() then
    return m.fail
  end

  local target = self:bd_get_target()
  local attacker = self:bd_get_attacker()
  if attacker then
    if target then
      local rate = self.aiProfile.att_rate or 100
      local r = math.random(1000)
      if r <= rate then
        self:bd_set_target(attacker)
        return m.success
      end
    else
      self:bd_set_target(attacker)
      return m.success
    end
  end

  return m.fail
end

--[[
    方法: tmp_search_summon_target
    别名: Tmp 召唤物目标锁定
    描述: 在召唤单位和召唤者最大距离内 查找离召唤者最近的敌人设置为目标
    参数: 无
]]
m.mnhs["tmp_search_summon_target"] = "召唤物目标锁定"
function m:tmp_search_summon_target(node)
  if not self.env or not self.fighter then
    if aidbg.debug then
      aidbg.log(0, "Invalid env!!!", aidbg.ERROR)
    end
    return m.fail
  end

  local sid = self.fighter.summon_pid
  if not sid then
    if aidbg.debug then
      aidbg.log(0, "Fighter is not summoned", aidbg.ERROR)
    end
    return m.fail
  end

  self.summoner = self.summoner or self.env.cc.findHero(sid)
  if not self.summoner then
    if aidbg.debug then
      aidbg.log(0, "There is no summoner", aidbg.ERROR)
    end
    return m.fail
  end

  local sum = self.aiProfile.sum_dist or 5
  local sum2 = sum * sum
  local pos = self.summoner:position()

  local nearest = nil
  local nearest_dist = nil

  local sides = cc.enemySides(self.fighter.side)
  for _, side in pairs(sides) do
    for k, v in cc.iterHeroes(side) do
      local pos1 = v:position()
      local dist2 = MathUtil.dist2(pos, pos1)
      --Distance between summoned entity and enemy should less than range in profile,
      --distance between summoner and enemy should less than follow distance in profile,
      --or else the summoned entity will run between summoner and target
      if dist2 <= sum2 then
        if not nearest_dist then
          nearest_dist = dist2
          nearest = v
        end

        if nearest_dist >= dist2 then
          nearest_dist = dist2
          nearest = v
        end
      end
    end
  end

  if not nearest then
    aidbg.log(0, "...no target for pet")
    return m.success
  end

  self:bd_set_target(nearest)
  return m.success
end

function m:_decorateMoveAction(act, faceTarget, dir, overrideJsDir, dist, action)
  local pos = self.fighter:position()
  local faceDir = Vector3.new(dir)
  if faceTarget then
    local target = self:_check_get_target()
    if target then
      local posTarget = target:position()
      faceDir = Vector3.new(Vector3.Normalized(posTarget - pos))
    end
  end
  local realDir = overrideJsDir or dir
  action:setMoveData(self.fighter, pos, realDir, faceDir)
  action:setVector3(action, 'posStart', pos)

  action.distance = math.sqrt(dist)
  local data = action.data
  data.cmd = act

  local speed = self:bd_get_move_speed()
  if speed then
    data.speed = speed
  end

  return action
end
