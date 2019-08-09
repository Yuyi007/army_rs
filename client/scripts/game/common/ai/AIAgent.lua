--[[
  env: table {
                scene,
                aic,
                cc,
                ...
              }
]]
class('AIAgent', function(self, env, fighter)
  self.env = env
  self.fighter = fighter
  self.bd = nil
  self.variables = nil
  self.extra  = nil
  self.destroyed = false
end)

local m = AIAgent
local unity = unity


m.success = 0
m.fail = 1
m.running = 2


function m:init()
  --黑板
  self.bd = {
      attacker = nil,               --当前攻击者
      target = nil,                 --追逐或攻击目标

      move_dir = nil,               --移动方向
      move_tm_span =  nil,          --移动时间
      move_tm_start =  nil,         --移动开始时间

      hold_tm_span = nil,           --待命时间
      hold_tm_start = nil,          --待命开始时间

      cur_skil = nil,               --当前使用技能

      tm_start = nil,               --延时计时
      tm_span = nil,                --延时间隔
      interval_timer = {},          --计时间隔
      interval_delta = {},          --累计计时

      skill_start = nil,            --技能开始时间
    }

  --自定义变量表
  self.variables = {}

  --扩展属性
  self.extra = {}
end

function m:exit()
  local h = self:bd_get_move_handle()
  if h then
    scheduler.unschedule(h)
    h = nil
  end

  local h = self:bd_get_sq_handle()
  if h then
    scheduler.unschedule(h)
    h = nil
  end

  self:cancelCheckSkillMove()
  self.env = nil
  self.fighter = nil
  self.destroyed = true
end

function m:sendAction(action)
  if self.fighter.destroyed then return end
  -- self.fighter:sendMessage(self.fighter.id, action)
  action:retain()
  self.fighter.aiActions = self.fighter.aiActions or {}
  local aiActions = self.fighter.aiActions
  aiActions[#aiActions+1] = action
end

--interface of attributes
--[[
    属性:  hp
    描述:  血量
    只读:  true
]]
function m:attr_hp()
  return self.fighter.model:clampedAttr('cur_hp')
end

--[[
    属性:  hp_max
    描述:  血量最大容量
    只读:  true
]]
function m:attr_hp_max()
  return self.fighter.model:clampedAttr('hp')
end

--[[
    属性:  attack_range
    描述:  攻击半径
    只读:  false
]]
function m:attr_attack_range()
  if not self.extra.attack_range then
    local sid = self:bd_get_cur_skill()
    if not sid then
      return 0.5
    end

    local s = cfg:skill(sid)
    return tonumber(s["use_dist"])
  end
  return tonumber(self.extra.attack_range)
end

--[[
    属性:  search_range
    描述:  搜索敌人半径
          如果有设置过半径，就用设置过得
          如果没有设置过就用怪物配置的(只对怪物有用，如果索引不到怪物，返回 0)
    只读:  false
]]
function m:attr_search_range()
  return self.extra.search_range
end

function m:get_default_search_range()
  return self.extra.search_range
end

function m:attr_set_search_range(rgn)
  self.extra.search_range = rgn
end

function m:attr_set_sattack_range(rgn)
  self.extra.attack_range = rgn
end

--[[
    属性:  summoner_dist2
    描述:  和召唤者之间的距离平方，如果没有召唤者，返回-1
    只读:  true
]]
function m:attr_summoner_dist2()
  local sid = self.fighter.summon_pid
  if not sid then
    return -1
  end

  self.summoner = self.summoner or self.env.cc.findHero(sid)
  local posSrc = self.fighter:position()
  local dist2 = 0
  if self.summoner then
    local posDst = self.summoner:position()
    dist2 = MathUtil.dist2(posSrc, posDst)
  end
  return dist2
end

--获取自己的属性xls con
function m:attr_row_getter(name)
  return self.fighter.model:clampedAttr(name)
end

--获取目标的属性
function m:attr_target_row_getter(name)
  local target = self:bd_get_target()
  if not target then
    return nil
  end

  local attr =  string.sub(name, 8, name.length)
  return target.model:clampedAttr(attr)
end

--[[
    属性:  target_dist
    描述:  与目标的距离
    只读:  true
]]
function m:attr_target_dist()
  local target = self:_check_get_target()
  if not target then
    return 0
  end

  local pos = self.fighter:position()
  local pos1 = target:position()
  local dist = MathUtil.distance(pos, pos1)

  return dist
end
--end attributes

--interface of bd
function m:bd_get_target()
  local target = self.bd["target"]

  if target and target:isCloaking() then
    self.bd['target'] = nil
  end

  return self.bd["target"]
end

function m:bd_set_target(target)
  if target and target:isCloaking() then
    logd('bd_set_target cloaking %s', target.id)
    target = nil
  end
  self.bd["target"] = target
end

function m:bd_get_attacker()
  return self.fighter.keyState:getLastAttacker()
end

function m:bd_set_face_target(faceTarget)
  self.bd['face_target'] = faceTarget
end

function m:bd_get_face_target()
  return self.bd['face_target']
end

function m:bd_clear_attacker(atker)
  self.fighter.keyState:clearLastAttacker()
end

function m:bd_set_movement(dir, tmSpan, tmStart, ptStart, dist, hitEenemyStop)
  --logd(">>>>>>>debug.traceback()"..(debug.traceback()))
  if aidbg.debug then
    -- inspection eats cpu
    aidbg.log(0, string.format("bd_set_movement dir:%s, tmSpan:%s, tmStart:%s, ptStart:%s, dist:%s",
      inspect(dir), inspect(tmSpan), inspect(tmStart), tostring(ptStart), inspect(dist)))
  end
  self.bd["move_dir"] = dir
  self.bd["move_tm_span"] = tmSpan
  self.bd["move_tm_start"] = tmStart
  self.bd["move_dist"] = dist
  self.bd["move_start"] = ptStart
  self.bd["hit_enemy_stop"] = hitEenemyStop
end

function m:bd_get_movement()
  return self.bd["move_dir"],
        self.bd["move_tm_span"],
        self.bd["move_tm_start"],
        self.bd["move_start"],
        self.bd["move_dist"],
        self.bd["hit_enemy_stop"]
end


function m:bd_get_hold_place()
  return self.bd["hold_tm_span"], self.bd["hold_tm_start"]
end

function m:bd_set_hold_place(tmSpan, tmStart)
  self.bd["hold_tm_span"] = tmSpan
  self.bd["hold_tm_start"] = tmStart
end

function m:bd_get_hold_static()
  return self.bd["static_tm_span"], self.bd["static_tm_start"]
end

function m:bd_set_hold_static(tmSpan, tmStart)
  self.bd["static_tm_span"] = tmSpan
  self.bd["static_tm_start"] = tmStart
end

function m:bd_get_cur_skill()
  return self.bd["cur_skil"]
end

function m:bd_set_cur_skill(skill)
  self.bd["cur_skil"] = skill
end

function m:bd_set_cur_skill_info(cd)
  if cd == nil then
    self.bd["cur_skil_info"] = nil
  else
    self.bd["cur_skil_info"] = {cd=cd, tm=engine.time()}
  end
end

function m:bd_get_cur_skill_info()
  return self.bd["cur_skil_info"]
end


function m:bd_get_tm_start()
  return self.bd["tm_start"]
end

function m:bd_set_tm_start(start)
  self.bd["tm_start"] = start
end

function m:bd_get_tm_span()
  return self.bd["tm_span"]
end

function m:bd_set_tm_span(span)
  self.bd["tm_span"] = span
end

function m:bd_get_interval(key)
  return self.bd["interval_timer"][key]
end

function m:bd_set_interval(key, value)
  self.bd["interval_timer"][key] = value
  if not value then
    self.bd["interval_delta"][key] = nil
  end
end

function m:bd_interval_tick(key)
  local ivs = self.bd["interval_timer"]
  local dt = self.bd["interval_delta"]
  local now = engine.time()
  dt[key] = dt[key] or now

  if now - dt[key] >= ivs[key] then
    dt[key] = now
    return true
  end
  return false
end

function m:bd_get_skill_start()
  return self.bd["skill_start"]
end

function m:bd_set_skill_start(start)
  self.bd["skill_start"] = start
end

function m:bd_set_skill_queue(skills)
  self.bd["queued_skills"] = skills
end

function m:bd_get_skill_queue()
  return self.bd["queued_skills"]
end

function m:bd_set_sq_index(i)
  self.bd["queued_skill_index"] = i
end

function m:bd_get_sq_index()
  return self.bd["queued_skill_index"]
end

function m:bd_set_sq_handle(h)
  self.bd["queued_skill_handler"] = h
end

function m:bd_get_sq_handle()
  return self.bd["queued_skill_handler"]
end

function m:bd_set_sq_end(b)
  self.bd["queued_skill_end"] = b
end

function m:bd_get_sq_end()
  return self.bd["queued_skill_end"]
end

function m:bd_set_move_end(b)
  self.bd["move_end"] = b
end

function m:bd_get_move_end()
  return self.bd["move_end"]
end

function m:bd_set_move_handle(h)
  self.bd["move_handler"] = h
end

function m:bd_get_move_handle()
  return self.bd["move_handler"]
end

function m:bd_set_move_speed(speed)
  self.bd["move_speed"] = speed
end

function m:bd_get_move_speed()
  if self.bd["move_speed"] then
    local scale = self.fighter:getModel():getWalkSpeedScale()
    return self.bd["move_speed"] * scale
  end
  return nil
end

--interface of agent

m.mnhs = {}
--[[
    方法: is_target_dead
    别名: 目标是否死亡
    描述: 检查目标是否死亡
    参数: 无
]]
m.mnhs["is_target_dead"] = "目标死亡"
function m:is_target_dead(node)
  local target = self:_check_get_target()
  if not target then
    return m.success
  end

  if target:destroyedOrDead() then
    return m.success
  end

  return m.fail
end

function m:_is_dead()
  if self.fighter:destroyedOrDead() then
    return true
  end

  return false
end

--[[
    方法: clear_target
    别名: 清除目标
    描述: 清除目标
    参数: 无
]]
m.mnhs["clear_target"] = "清除目标"
function m:clear_target(node)
  self:bd_set_target(nil)
  return m.success
end

--[[
    方法: set_attack_range
    别名: 设置攻击距离
    描述: 设置ai攻击目标的半径
    参数: arg1 - 半径大小 [float]
  ]]
m.mnhs["set_attack_range"] = "设攻击rgn"
function m:set_attack_range(node, range)
  self.extra.attack_range = range
  return m.success
end

--[[
    方法: has_target
    别名: 是否有目标
    描述: 查看是否设置了攻击目标
    参数: 无
  ]]
m.mnhs["has_target"] = "是否有目标"
function m:has_target(node)
  local target = self:bd_get_target()
  if target ~= nil then
    return m.success
  end

  return m.fail
end

--[[
    方法: set_attacker_as_target
    别名: 设置攻击者为目标
    描述: 将最后一次攻击的单位设置为目标单位
    参数: 无
]]
m.mnhs["set_attacker_as_target"] = "atker为目标"
function m:set_attacker_as_target(node)
  local attacker = self:bd_get_attacker()
  if not attacker then
    if aidbg.debug then
      aidbg.log(0, "...set_attacker_as_target fail", aidbg.ERROR)
    end
    return m.fail
  end

  self:bd_set_target(attacker)
  if aidbg.debug then
    aidbg.log(0, "...set_attacker_as_target success")
  end
  return m.success
end

--[[
    方法: is_attacked
    别名: 是否被攻击过
    描述: 是否有人攻击过自己（通过判断上一次攻击的单位实现，所以如果已经清除了上次攻击单位，就会返回失败）
    参数: 无
]]
m.mnhs["is_attacked"] = "被打了？"
function m:is_attacked(node)
  local a = self.fighter.keyState:getLastAttacker()
  if a then
    return m.success
  else
    return m.fail
  end
end

--[[
    方法: clear_last_attacker
    别名: 清除攻击者
    描述: 将上次攻击自己的单位清除
    参数: 无
]]
m.mnhs["clear_last_attacker"] = "清atker"
function m:clear_last_attacker(node)
  self:bd_clear_attacker()
  return m.success
end

--[[
    方法: set_search_range
    别名: 设置搜索距离
    描述: 设置ai搜索目标的半径
    参数: arg1 - 半径大小 [float]
  ]]
m.mnhs["set_search_range"] = "设搜索rgn"
function m:set_search_range(node, range)
  self.extra.search_range = range
  return m.success
end

--[[
    方法: has_target_in_search_range
    别名: 可否搜索到目标
    描述: 根据配置的搜索半径搜索，返回是否可以搜索到目标
    参数: 无
]]
m.mnhs["has_target_in_search_range"] = "搜到目标？"
function m:has_target_in_search_range(node)
  if not self.env or not self.fighter then
    if aidbg.debug then
      aidbg.log(0, "Invalid env!!!", aidbg.ERROR)
    end
    return m.fail
  end

  local range = self:attr_search_range()
  local pos = self.fighter:position()
  local range2 = range * range
  local sides = cc.enemySides(self.fighter.side)
  for _, side in pairs(sides) do
    for k, v in cc.iterHeroes(side) do
      local pos1 = v:position()
      local dist2 = MathUtil.dist2(pos, pos1)
      -- logd(">>>>>>>v.id"..inspect(v.id))
      -- logd(">>>>>>>self.fighter.id"..inspect(self.fighter.id))
      -- logd(">>>>>>pos1.x"..inspect(pos1.x))
      -- logd(">>>>>>>pos.x"..inspect(pos.x))
      -- logd(">>>>>>pos1.z"..inspect(pos1.z))
      -- logd(">>>>>>>pos.z"..inspect(pos.z))
      -- logd(">>>>>>>dist"..inspect(dist))
      -- logd(">>>>>>>range"..inspect(range))
      if dist2 <= range2 then
        if aidbg.debug then
          aidbg.log(0, "...has_target_in_search_range success", aidbg.WARNING)
        end
        return m.success
      end
    end
  end

  if aidbg.debug then
    aidbg.log(0, "...has_target_in_search_range fail")
  end

  return m.fail
end

--[[
    方法: set_hp_lowest_as_target
    别名: 血量最少为目标
    描述: 把血量最少的target设置为目标
    参数: 无
]]
m.mnhs["set_hp_lowest_as_target"] = "血少为目标"
function m:set_hp_lowest_as_target(node)
  if not self.env then
    if aidbg.debug then
      aidbg.log(0, "Invalid env!!!", aidbg.ERROR)
    end
    return m.fail
  end

  local lowest = nil
  local lpercent = nil
  local sides = cc.enemySides(self.fighter.side)
  for _, side in pairs(sides) do
    for k, v in cc.iterHeroes(side) do
      if not v:destroyedOrDead() then
        local p  = v.model:hpPercent()

        if not lpercent then
          lpercent = p
          lowest = v
        end

        if lpercent >= dist then
          lowest = v
          lpercent = dist
        end
      end
    end
  end

  if lowest then
    self:bd_set_target(lowest)
    if aidbg.debug then
      aidbg.log(0, "...set_hp_lowest_as_target success")
    end
    return m.success
  else
    if aidbg.debug then
      aidbg.log(0, "...set_hp_lowest_as_target fail")
    end
    return m.fail
  end
end

--[[
    方法: set_nearest_as_target
    别名: 设置最近者为目标
    描述: 把距离最近的target设置成目标
    参数: 无
]]
m.mnhs["set_nearest_as_target"] = "最近为目标"
function m:set_nearest_as_target(node)
  if not self.env then
    if aidbg.debug then
      aidbg.log(0, "Invalid env!!!", aidbg.ERROR)
    end
    return m.fail
  end

  local pos = self.fighter:position()
  local nearest = nil
  local nearest_dist = nil

  local sides = cc.enemySides(self.fighter.side)
  for _, side in pairs(sides) do
    for k, v in cc.iterHeroes(side) do
      if not v:destroyedOrDead() then
        local pos1 = v:position()
        local dist = MathUtil.dist2(pos, pos1)

        if not nearest_dist then
          nearest_dist = dist
          nearest = v
        end

        if nearest_dist >= dist then
          nearest = v
          nearest_dist = dist
        end
      end
    end
  end

  if nearest then
    self:bd_set_target(nearest)
    if aidbg.debug then
      aidbg.log(0, "...set_nearest_as_target success")
    end
    return m.success
  else
    if aidbg.debug then
      aidbg.log(0, "...set_nearest_as_target fail")
    end
    return m.fail
  end
end


function m:_check_get_target()
  local target = self:bd_get_target()
  if not target then
    if aidbg.debug then
      aidbg.log(0, "no target fail!")
    end
    return nil
  end
  --check target dead
  local ret = self.env.cc.findEntity(target.id)
  if not ret then
    if aidbg.debug then
      aidbg.log(0, "target dead return fail!")
    end
    return nil
  end

  return target
end

--[[
    方法: force_idle
    别名: 停止移动
    描述: 停止移动,如果本身在idle就直接放回成功
    参数: 无
]]
m.mnhs["force_idle"] = "force_idle"
function m:force_idle(node)
  if self:_is_dead() then
    return m.fail
  end

  if self.fighter.psm.curState.name == "idle" then
    return m.success
  end

  local action = ActionFactory.makeIdle()
  action:setMoveData(self.fighter)
  self:sendAction(action)
  return m.success
end

--[[
    方法: hold_static
    别名: 原地不动
    描述: 原地不懂一段时间，并且不转向敌人
    参数: arg1 - 待命时间，单位秒 [float]
]]
m.mnhs["hold_static"] = "hold_static"
function m:hold_static(node, tmSpan)
  if self:_is_dead() then
    return m.fail
  end
  local span, tmStart = self:bd_get_hold_static()
  tmSpan = span or tmSpan
  if not tmStart then
    tmStart = engine.time()
    self:bd_set_hold_static(tmSpan, tmStart)

    local action = ActionFactory.makeIdle()
    action:setMoveData(self.fighter)
    self:sendAction(action)
  end

  local now = engine.time()
  local span = now - tmStart
  if span < tmSpan then
    return m.running
  else
    self:bd_set_hold_static(nil, nil)
    return m.success
  end
end

--[[
    方法: hold_place
    别名: 原地待命
    描述: 原地待命一段时间
    参数: arg1 - 待命时间，单位秒 [float]
]]
m.mnhs["hold_place"] = "hold_place"
function m:hold_place(node, tmSpan)
  if self:_is_dead() then
    return m.fail
  end
  local span, tmStart = self:bd_get_hold_place()
  tmSpan = span or tmSpan
  if not tmStart then
    tmStart = engine.time()
    self:bd_set_hold_place(tmSpan, tmStart)

    local action = ActionFactory.makeIdle()
    action:setMoveData(self.fighter)
    self:sendAction(action)
  end

  local now = engine.time()
  local span = now - tmStart
  if span < tmSpan then
    if aidbg.debug then
      aidbg.log(0, "...hold_place running")
    end

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
      end
    end
    return m.running
  else
    if aidbg.debug then
      aidbg.log(0, "...hold_place success")
    end
    self:bd_set_hold_place(nil, nil)
    return m.success
  end
end

--[[
    方法: set_random_movement
    别名: 设置随机移动
    描述: 生成随机的移动方向和移动时间
    参数: arg1 - 随机时间范围最小值 单位秒 精确到小数后两位 [float]
          arg2 - 随机时间范围最大值 单位秒 精确到小数后两位 [float]
          arg3 - 随机距离范围最小值 精确到小数后两位 [float]
          arg4 - 随机距离范围最大值 精确到小数后两位 [float]
]]
m.mnhs["set_random_movement"] = "随机移动"
function m:set_random_movement(node, minTm, maxTm, minDist, maxDist)
  local tmStart = engine.time()
  local tmSpan = math.random(minTm*100, maxTm*100)
  local dist = math.random(minDist*100, maxDist*100)
  tmSpan = tmSpan / 100
  dist = dist / 100
  local x = math.random(-50, 50)
  local z = math.random(-50, 50)

  local dir = Vector3.new(Vector3.Normalized(Vector3(x, 0, z)))
  local ptStart = Vector3.new(self.fighter:position())
  self:bd_set_movement(dir, tmSpan, tmStart, ptStart, dist * dist)
  if aidbg.debug then
    aidbg.log(0, "...set_random_movement success")
  end
  return m.success
end

--[[
    方法: walk
    别名: 走路
    描述: 沿着设定好的移动方向走过去
    参数: arg1 - 脸部朝向是否面向布标[bool]
]]
m.mnhs["walk"] = "走"
function m:walk(node, faceTarget)
  if self:_is_dead() then
    return m.fail
  end

  return self:_move(node, "walk", faceTarget)
end

--[[
    方法: in_side
    别名: 是否在某个side?
    描述: 查询单位是否在指定的某个side中
    参数: arg1 - 指定的side[float]
]]
m.mnhs["in_side"] = "是否在某个side?"
function m:in_side(node, side)
  if not self.env or not self.fighter then
    if aidbg.debug then
      aidbg.log(0, "Invalid env!!!", aidbg.ERROR)
    end
    return m.fail
  end

  if self.fighter.side == side then
    return m.success
  else
    return m.fail
  end
end


--[[
    方法: need_move_to_active_mission
    别名: 是否需要移动来激活下一个mission？
    描述: 查询是否是否需要移动来激活下一个mission
    参数: 无
]]
m.mnhs["need_move_to_active_mission"] = "是否需要移动来激活下一个mission？"
function m:need_move_to_active_mission(node)
  if self:_is_dead() then
    return m.fail
  end
  if not self.env or not self.fighter
    or not self.env.cc or not self.env.cc.scene
    or not self.env.cc.scene:pve() then
    if aidbg.debug then
      aidbg.log(0, "Invalid env!!!", aidbg.ERROR)
    end
    return m.fail
  end

  if self.fighter.side ~= 1 then
    return m.fail
  end

  local sid = self.fighter.summon_pid
  if sid then
    return m.fail
  end

  local curSeg = self.env.cc.scene.curSeg
  if not curSeg then
    return m.fail
  end

  if curSeg:finished() then
    return m.success
  else
    if curSeg.pass.condition == 'move' then
      return m.success
    end
  end
  return m.fail
end

--[[
    方法: move_to_active_mission
    别名: 移动到下一个mission
    描述: 移动到可以激活下一个mission的位置
    参数: 无
]]
m.mnhs["move_to_active_mission"] = "移动到下一个mission"
function m:move_to_active_mission(node)
  if self:_is_dead() then
    return m.fail
  end

  local move_to_x = function(to_x, cur_x, cur_pos)
    local x_dir = 1
    if to_x < cur_x then x_dir = -1 end
    local dir = Vector3.new(x_dir, 0, 0)
    local dist = (to_x - cur_x) * x_dir
    self:bd_set_movement(dir, nil, nil, Vector3.new(cur_pos), dist * dist)
  end

  if not self.env or not self.fighter
    or not self.env.cc or not self.env.cc.scene
    or not self.env.cc.scene:pve() then
    if aidbg.debug then
      aidbg.log(0, "Invalid env!!!", aidbg.ERROR)
    end
    return m.fail
  end
  local curSeg = self.env.cc.scene.curSeg
  if not curSeg then
    return m.fail
  end
  local pos = self.fighter:position()
  local x = pos[1]
  if curSeg:finished() then
    local n = curSeg.next
    if n then
      local xRight = n.xRight - 1
      local xLeft = n.xLeft + 1
      if x > xRight then
        move_to_x(xRight, x, pos)
      elseif x < xLeft then
        move_to_x(xLeft, x, pos)
      end
    end
  else
    if curSeg.pass.condition == 'move' then
      if x ~= curSeg.pass.x then
        move_to_x(curSeg.pass.x, x, pos)
      end
    end
  end
  return m.success
end

function m:_reach_boundary(dir)
  local boundary = cc.scene:getFightBoundary()
  local xMin, xMax, zMax, zMin = boundary[1], boundary[2], boundary[3], boundary[4]
  local pos = self.fighter:position()
  local nearBoundary = false
  local boundary = {}
  local bounds = self.fighter:getBounds()
  local boundSize = bounds:get_size()
  local xW = boundSize[1] / 2 + self.fighter.radius
  local zW = boundSize[3] / 2 + self.fighter.radius

  -- logd(">>>>>>>ssss xMin"..inspect(xMin))
  -- logd(">>>>>>>ssss xMax"..inspect(xMax))
  -- logd(">>>>>>>ssss zMin"..inspect(zMin))
  -- logd(">>>>>>>ssss zMax"..inspect(zMax))
  -- logd(">>>>>>>ssss pos"..inspect(pos))
  -- logd(">>>>>>>ssss xW"..inspect(xW))
  -- logd(">>>>>>>ssss zW"..inspect(zW))

  if ((pos[1] - xMin) < xW) then
    nearBoundary =  true
    boundary[#boundary + 1] = "left"
  elseif ((xMax - pos[1]) < xW) then
    nearBoundary =  true
    boundary[#boundary + 1] = "right"
  end

  if ((pos[3] - zMin) < zW) then
    nearBoundary =  true
    boundary[#boundary + 1] = "bottom"
  elseif ((zMax - pos[3]) < zW) then
    nearBoundary =  true
    boundary[#boundary + 1] = "up"
  end

  --logd(">>>>>>>ssssnearBoundary"..inspect(nearBoundary))
  if not nearBoundary then
    return false
  end

  --在边界附近还需要判断move方向是否朝边界外
  local dirV2 = Vector2(dir[1], dir[3])
  local dirIndex = UIUtil.getDirIndex(dirV2)
  -- logd(">>>>>>>boundary"..inspect(boundary))
  -- logd(">>>>>>>dirIndex"..inspect(dirIndex))
    local deg = dirIndex - 90
    if deg < 0 then
      deg = 360 + deg
    end

    if boundary[1] == "left" then
      if not boundary[2] then
        return deg > 90 and deg < 270
      else
        if boundary[2] == "up" then
          logd(">>>>>>>deg"..inspect(deg))
          return deg > 0 and deg < 270
        else
          return deg > 90 and deg < 360
        end
      end
    elseif boundary[1] == "right" then
      if not boundary[2] then
        return (deg > 0  and deg < 90) or (deg > 270 and deg < 360)
      else
        if boundary[2] == "up" then
          return (deg > 0 and deg < 180) or (deg > 270 and deg < 360)
        else
          return (deg > 0 and deg < 90) or (deg > 180 and deg < 360)
        end
      end
    elseif boundary[1] == "up" then
      if not boundary[2] then
        return deg > 0 and deg < 180
      else
        if boundary[2] == "left" then
          return deg > 0 and deg < 270
        else
          return (deg > 0 and deg < 180) or (deg > 270 and deg < 360)
        end
      end
    elseif boundary[1] == "bottom" then
      if not boundary[2] then
        return deg > 180 and deg < 360
      else
        if boundary[2] == "left" then
          return deg > 90 and deg < 360
        else
          return (deg > 0 and deg < 90) or (deg > 180 and deg < 360)
        end
      end
    end
    return false
end

function m:_hit_something(dir, mag)
  local pos = self.fighter:position()
  local vectorA = Vector3.new(0, 1, 0)
  local testMask = unity.getCullingMask('Default', 'Barrel')--self.fighter.actor:getRayTestMask()
  mag = mag or 1--self.fighter.radius * 2

  local pStart = pos + vectorA
  local ok1, info = unity.raycastFirst(pStart, dir, mag, testMask)
  return ok1, info
end

local max = math.max
local sqr = math.sqr

function m:_hit_enemy(dir)
  if true then return false end
  local p1 = self.fighter:position()
  local entity = self.fighter.actor:getEntity()
  local psm = entity.psm
  if entity.destroyed then return false end
  if not entity:isLocal() then return false end
  if (not psm:isMoving()) and (not psm:isCasting()) then return false end

  local s1 = self.fighter.radius

  local sides = cc.enemySides(self.fighter.side)
  for _, side in pairs(sides) do
    for _, hero in cc.iterHeroes(side) do
      local p2 = hero:position()
      local s2 = hero.radius

      local dpx = p2[1] - p1[1]
      local dpz = p2[3] - p1[3]
      local offsetX = -0.5
      if dpx/dir[1] < 0 then
        offsetX = 0.5 * math.abs(dir[1])
      end
      local offsetZ = -0.5
      if dpz/dir[3] < 0 then
        offsetZ = 0.5 * math.abs(dir[3])
      end

      local distX = math.abs(dpx) + offsetX
      local distZ = math.abs(dpz) + offsetZ
        -- logd(">>>>>>>dir.x"..inspect(dir.x))
        -- logd(">>>>>>>dir.z"..inspect(dir.z))
        -- logd(">>>>>>>offsetZ"..inspect(offsetZ))
        -- logd(">>>>>>>offsetX"..inspect(offsetX))
        -- logd(">>>>>>>self.fighter.radius"..inspect(self.fighter.radius))
        -- logd(">>>>>>>hero.radius"..inspect(hero.radius))
        -- logd(">>>>>>>s1"..inspect(s1))
        -- logd(">>>>>>>s2"..inspect(s2))
        -- logd(">>>>>>>p2.x-p1.x"..inspect(dpx))
        -- logd(">>>>>>>p2.z-p1.z"..inspect(dpz))
        -- logd(">>>>>>>distZ"..inspect(distZ))
        -- logd(">>>>>>>distX"..inspect(distX))
        -- logd(">>>>>>>s1+s2"..inspect(s1+s2))
      local dist = s1 + s2
      if distX <= dist and distZ <= dist then
        return true
      end
    end
  end
  return false
end

function m:_reach_dist(p1, p2, dist)
  local m2 = MathUtil.dist2(p1, p2)
  return m2 >= dist - 0.5
end

function m:_unscheduleMove()
  local h = self:bd_get_move_handle()
  if aidbg.debug then
    aidbg.log(0, "[MOVE] unschedule handle:%s", tostring(h))
  end
  if h then
    scheduler.unschedule(h)
    self:bd_set_move_handle(nil)
  end
end

function m:_decorateMoveAction(act, faceTarget, dir, overrideJsDir, dist, action)
  local pos = self.fighter:position()
  local faceDir = Vector3.new(dir)
  local realDir = overrideJsDir or dir
  action:setMoveData(self.fighter, pos, realDir, faceDir)
  action:setVector3(action, 'posStart', pos)

  action.distance = math.sqrt(dist)
  local data = action.data
  data.cmd = act
  data.speed = CombatCalculatorUtil.getMovementSpeed('run', self.fighter.id)
  return action
end

function m:_move(node, act, faceTarget)
  if aidbg.debug then
    aidbg.log(0, "..."..tostring(node.uid))
  end

  if self:bd_get_move_end() then
    self:bd_set_move_end(false)
    return m.success
  end

  if self:bd_get_move_handle() then
    return m.running
  end

 -- for i=0, 10000 do
 --   Quaternion.Euler(Vector3(0, 1, 0))
 -- end
  local dir, tmSpan, tmStart, ptStart, dist, hitEnemyStop = self:bd_get_movement()
  if hitEnemyStop == nil then
    hitEnemyStop = true
  end
  -- logd(">>>>>>>dir.x:"..inspect(dir.x).."  dir.z:"..inspect(dir.z))
  -- logd(">>>>>>>ptStart.x:"..inspect(ptStart.x))
  -- logd(">>>>>>>ptStart.z:"..inspect(ptStart.z))
  -- logd(">>>>>>>dist"..inspect(dist))

  if not dir or not ptStart or not dist then
    if aidbg.debug then
      aidbg.log(0, "...plz set movement first")
    end
    return m.fail
  end

  local function stopMove()
    self:bd_set_move_end(true)
    self:_unscheduleMove()

    local action = ActionFactory.makeIdle()
    if self.fighter then
      action:setMoveData(self.fighter)
      self:sendAction(action)
    end
    scheduler.performWithDelay(0, function()
        if self.env and self.env.aic then
          self.env.aic:manualStep(self.btid)
        end
      end)
  end

  local function sendMoveAction()
    if not self.fighter then
      return 
    end
    if not self.fighter:canMove() then
      return
    end

    local action, fdir, overrideJsDir = MoveActionFactory.makeMove(self.fighter, dir)
    if action then
      self:_decorateMoveAction(act, faceTarget, dir, overrideJsDir, dist, action)
      self:sendAction(action)
      if aidbg.debug then
        aidbg.log(0, "...send move action")
      end
    end
  end

  local function checkStop(deltaTime)
    if not self.fighter then
      return
    end

    local psm = self.fighter.psm
    if not psm then
      return
    end
    if psm.curState.classname == 'PSBorn' then
      return
    end

    if self.destroyed then
      stopMove()
      return
    end

    local canMove = self.fighter:canMove()
    if not canMove then
      if aidbg.debug then
        aidbg.log(0, "..."..act.." success: cann't move now!")
      end
      stopMove()
      return
    end

    local pos = self.fighter:position()
    local reachDist = self:_reach_dist(pos, ptStart, dist)
    local hitSomething = false
    local hitSomeBody = false

    if not reachDist then
      hitSomething = self:_hit_something(dir)
      if not hitSomething then
        hitSomeBody = hitEnemyStop and self:_hit_enemy(dir)
      end
    end
    -- if self.fighter.id == "bot-miss1010101-area3-1-3" then
    --   logd(">>>>>>>reachDist:"..inspect(reachDist))
    --   logd(">>>>>>>hitSomething:"..inspect(hitSomething))
    --   logd(">>>>>>>hitSomeBody:"..inspect(hitSomeBody))
    -- end
    if reachDist or hitSomething or hitSomeBody then
      if aidbg.debug then
        aidbg.log(0, "..."..act.." success. reachDist:"..tostring(reachDist).." hitSomething:"..tostring(hitSomething).." hitSomeBody:"..tostring(hitSomeBody))
      end
      stopMove()
      return
    else
      --不计时 一直移动
      if not tmSpan or not tmStart then
        return
      end
      --计时到才停止
      local now = engine.time()
      local span = now - tmStart
      if tmSpan ~= 0 and span >= tmSpan then
        if aidbg.debug then
          aidbg.log(0, "..."..act.." success. time up.")
        end
        stopMove()
      else
        sendMoveAction()
      end
    end
  end

  local function startMove()
    sendMoveAction()
    self._move_tick = 0
    self:bd_set_move_end(false)
    self:_unscheduleMove()
    local handler = scheduler.scheduleWithUpdate(function ()
      unity.beginSample('AIAgent.checkStop')
      --send move action per 0.5 seconds
      self._move_tick = self._move_tick + 1
      if (self._move_tick % 5) == 0 then
        sendMoveAction()
      end
      checkStop()

      unity.endSample()
    end, 0.1)
    self:bd_set_move_handle(handler)
  end

  startMove()
  return m.running
end

--[[
    方法: movement_arrived
    别名: 到达移动目标点
    描述: 到达移动目标点
    参数: 无
]]
m.mnhs["movement_arrived"] = "到达?"
function m:movement_arrived(node)
  local dir, tmSpan, tmStart, ptStart, dist = self:bd_get_movement()
  if not dir or not ptStart or not dist then
    return m.success
  end

  local pos = self.fighter:position()
  local reachDist = self:_reach_dist(pos, ptStart, dist)
  local hitSomething = self:_hit_something(dir)
  local hitSomeBody = self:_hit_enemy(dir)
  local reachBoundary = self:_reach_boundary(dir)

  if reachDist or hitSomething or hitSomeBody or reachBoundary then
    self:bd_set_movement(nil, nil, nil, nil, nil)
    return m.success
  end

  return m.fail
end

--[[
    方法: movement_set
    别名: 是否设置了移动
    描述: 是否设置了移动
    参数: 无
]]
m.mnhs["movement_set"] = "移动?"
function m:movement_set(node)
  local dir, tmSpan, tmStart, ptStart, dist = self:bd_get_movement()
  if not dir or not ptStart or not dist then
    return m.fail
  end
  return m.success
end

--[[
    方法: clear_movement
    别名: 清除移动设置
    描述: 清除移动设置
    参数: 无
]]
m.mnhs["clear_movement"] = "清除移动"
function m:clear_movement(node)
  self:bd_set_movement(nil, nil, nil, nil, nil)
  return m.success
end

--[[
    方法: run
    别名: 跑动
    描述: 沿着设定好的移动方向跑过去
    参数: arg1 - 脸部朝向是否面向布标[bool]
]]
m.mnhs["run"] = "跑"
function m:run(node, faceTarget)
  if self:_is_dead() then
    return m.fail
  end

  -- logd(">>>>>>self.fighter.summon_pid:%s", tostring(self.fighter.summon_pid))
  -- if self.fighter.summon_pid then
  --   aidbg.logPath(node)
  -- end
  -- return m.success
  return self:_move(node, "run", faceTarget)
end

--[[
    方法: set_movement_to_target
    别名: 设置移动朝目标
    描述: 以目标最近的平齐点为移动目标点，移动参数一设定的时间，
          如果超过时间，就停止移动，如果过程中碰到敌人，或者障碍，墙都会停下返回成功
    参数: arg1 - 移动时间段 单位 秒[float]
]]
m.mnhs["set_movement_to_target"] = "朝目标移动"
function m:set_movement_to_target(node, tmSpan)
  -- logd(">>>>>>>朝目标移动："..inspect(self.fighter.id))
  local target = self:_check_get_target()
  if not target then
    return m.fail
  end

  local range = self:attr_attack_range() or 0.5

  local pos2 = target:position()
  local pos1 = self.fighter:position()

  if pos1[1] > pos2[1] then
    pos2[1] = pos2[1] + range + target.radius - 0.3
  else
    pos2[1] = pos2[1] - range - target.radius + 0.3
  end

  local dist = MathUtil.dist2(pos1, pos2)
  local dir = Vector3.new(Vector3.Normalized(pos2 - pos1))
  local hit, info = self:_hit_something(dir, math.sqrt(dist))

    -- logd(">>>>>>>range:"..inspect(range))
    -- logd(">>>>>>>target.radius:"..inspect(target.radius))
    -- logd(">>>>>>>pos2.x:"..inspect(pos2.x).." pos2.z:"..inspect(pos2.z))
    -- logd(">>>>>>>pos1.x:"..inspect(pos1.x).." pos1.z:"..inspect(pos1.z))
    -- logd(">>>>>>>hit"..inspect(hit))

  if hit then
    local pt = Vector3(info:get_point())
    --logd(">>>>>>>pt x:"..inspect(pt.x).." z:"..inspect(pt.z))
    pos2 = target:position()
    if pos1[1] > pos2[1] then
      pos2[1] = pos2[1] - range - target.radius + 0.3
    else
      pos2[1] = pos2[1] + range + target.radius - 0.3
    end
    --logd(">>>>>>>pos2.x:"..inspect(pos2.x).." pos2.z:"..inspect(pos2.z))
    dist = MathUtil.dist2(pos1, pos2)
    dir = Vector3.new(Vector3.Normalized(pos2 - pos1))
  end
  -- logd(">>>>>>>dir.x:"..inspect(dir.x).."  dir.z:"..inspect(dir.z))
  -- logd(">>>>>>>dist"..inspect(dist))
  local tmStart = engine.time()
  self:bd_set_movement(dir, tmSpan, tmStart, Vector3.new(pos1), dist, false)

  return m.success
end

--[[
    方法: should_skill_attack
    别名: 技能是否应该释放
    描述: 如果是有施法距离设置的话，需要判断是否和目标单位在一个水平线上，并且在攻击范围内
          （tolerance是从skill中读取, 如果没配置就是0.5）
          如果没有施法距离设置的话，就是可以原地施法，直接返回成功
          如果跟对方有碰撞直接释放，可以防止为了释放技能，导致一直朝释放技能的目标点走卡住
    参数: 无
]]
m.mnhs["should_skill_attack"] = "技能能放？"
function m:should_skill_attack(node)
  local sid = self:bd_get_cur_skill()
  if not sid then
    return m.fail
  end

  local profile = cfg.skills[sid]
  local tolerance = profile.use_depth or 0.5

  if aidbg.debug then
    aidbg.log(0, "[DEPTH] tolerance:%s", tostring(tolerance))
  end

  return self:should_attack(node, tolerance)
end

--[[
    方法: should_attack
    别名: 是否应该释放技能
    描述: 如果是有施法距离设置的话，需要判断是否和目标单位在一个水平线上，并且在攻击范围内
          如果没有施法距离设置的话，就是可以原地施法，直接返回成功
          如果跟对方有碰撞直接释放，可以防止为了释放技能，导致一直朝释放技能的目标点走卡住
    参数: arg1 - 对齐容忍范围绝对值 [float]
]]
m.mnhs["should_attack"] = "能出手？"
function m:should_attack(node, tolerance)
  local target = self:_check_get_target()
  if not target then
    return m.fail
  end

  local ptMe = self.fighter:position()
  local ptTa = target:position()

  local attackRgn = self:attr_attack_range()
  if not attackRgn or attackRgn == 0 then
    return m.success
  end

  local dir, _, _, _, _ = self:bd_get_movement()
  if dir then
    local hitEnemy = self:_hit_enemy(dir)
    if hitEnemy then
      return m.success
    end
  end

  attackRgn = attackRgn + target.radius + 0.3
  local attackRgn2 = attackRgn * attackRgn
  local dist2 = MathUtil.dist2(ptMe, ptTa)
  local dt = ptMe[3] - ptTa[3]

  if dist2 <= attackRgn2 and
    (dt >= -tolerance and dt <= tolerance ) then
    return m.success
  end

  return m.fail
end

--[[
    方法: is_align_target
    别名: 是否与目标对齐
    描述: 判断是否和目标单位在一个水平线上
    参数: arg1 - 容忍范围绝对值 [float]

]]
m.mnhs["is_align_target"] = "目标平行？"
function m:is_align_target(node, tolerance)
  local target = self:_check_get_target()
  if not target then
    if aidbg.debug then
      aidbg.log(0, "...no target fail")
    end
    return m.fail
  end

  local pos2 = target:position()
  local pos1 = self.fighter:position()
  local dt = pos1.z - pos2.z
  if dt >= -tolerance and dt <= tolerance then
    if aidbg.debug then
      aidbg.log(0, "...is_align_target success")
    end
    return m.success
  end

  if aidbg.debug then
    aidbg.log(0, "...is_align_target fail")
  end
  return m.fail
end

--[[
    方法: face_to_target
    别名: 转向目标
    描述: 转向目标
    参数: 无
]]
m.mnhs["face_to_target"] = "朝向目标"
function m:face_to_target(node)
  if self:_is_dead() then
    return m.fail
  end

  local ks = self.fighter.keyState
  local target = self:_check_get_target()
  if not target then
    if aidbg.debug then
      aidbg.log(0, "...no target fail")
    end
    return m.fail
  end

  if target:destroyedOrDead() then
    return m.fail
  end

  local pos2 = target:position()
  local pos1 = self.fighter:position()
  local dir = Vector3.Normalized(pos2 - pos1)
  local faceDir = self.fighter:forward()
  if (faceDir[1] > 0 and dir[1] > 0) or
     (faceDir[1] < 0 and dir[1] < 0) then
    if aidbg.debug then
      aidbg.log(0, "...face_to_target success")
    end
    return m.success
  end

  local action = ActionFactory.makeTurn()
  action:setMoveData(self.fighter, pos1, dir, dir)
  self:sendAction(action)
  if aidbg.debug then
    aidbg.log(0, "...face_to_target success")
  end
  return m.success
end

--[[
    方法: set_skill
    别名: 设置技能
    描述: 设置一个当前要使用的技能
    参数: arg1 - 技能id [string]
]]
m.mnhs["set_skill"] = "设置技能"
function m:set_skill(node, sid)
  local curSkill = self:bd_get_cur_skill()
  if curSkill then
    return m.success
  end

  self:bd_set_cur_skill(sid)
  self:bd_set_cur_skill_info(nil)

  local speed = cfg.skills[sid].move_speed
  self:bd_set_move_speed(speed)

  local speed = cfg.skills[sid].move_speed
  self:bd_set_move_speed(speed)

  if aidbg.debug then
    aidbg.log(0, "...set_skill success:"..sid)
  end
  return m.success
end

--[[
    方法: attackable
    别名: 是否能释放技能
    描述: 判断当前是否可以释放设置好的技能
    参数: 无
]]
m.mnhs["attackable"] = "是否能释放"
function m:attackable(node)
  local skill = self:bd_get_cur_skill()
  if not skill then
    if aidbg.debug then
      aidbg.log(0, "...fail no skill", aidbg.ERROR)
    end
    return m.fail
  end

  if not self:_can_cast(action.data.tid) then
    return m.fail
  end

  return m.success
end

--[[
    方法: has_force_queued
    别名: 是否有设置强制多段攻击
    描述: 检查是否有设置强制多段攻击
    参数: 无
]]
m.mnhs["has_force_queued"] = "有多段？"
function m:has_force_queued(node)
  local q = self:bd_get_skill_queue()
  if q then
    return m.success
  else
    return m.fail
  end
end

function m:cancelCheckSkillMove()
  if not self._h_check_stop_skill_move then
    return
  end

  scheduler.unschedule(self._h_check_stop_skill_move)
  self._h_check_stop_skill_move = nil
end

function m:stopSkillMove()
  self._apply_move = false
  local action = MoveActionFactory.makeIdle(self.fighter)
  if action then
    action:setMoveData(self.fighter)
    self:sendAction(action)
  end
end

function m:checkStopSkillMove()
  if self.fighter.destroyed then return end
  if not self.fighter.psm then return end
  self._apply_move = true

  cc.signal('skill_exit'):addOnce(function ()
    self:stopSkillMove()
  end)
  cc.signal('skill_after_move'):addOnce(function()
    self:stopSkillMove()
  end)
end

function m:applySkillMovement(sid)
  local target = self:_check_get_target()
  if not target then
    return
  end

  local profile = cfg.skills[sid]
  if not profile.movable then
    return
  end

  local ptDst = target:position()
  local ptCur = self.fighter:position()
  local dir = ptDst - ptCur

  local action, faceDir, overDir = MoveActionFactory.makeMove(self.fighter, dir)
  if not action then
    if aidbg.debug then
      aidbg.log(0, "[SKILL_MOVE] make move failure")
    end
    return
  end

  local realDir = overDir or dir
  action:setMoveData(self.fighter)--, ptCur, realDir, faceDir)
  action.manual = true
  action.data.cmd = 'run'
  self:sendAction(action)
  self:checkStopSkillMove()
end

function m:doQueuedSkill(index)
  if aidbg.debug then
    aidbg.log(0, "[QSKILL] do queue skill index:%s", tostring(index))
  end

  local skills = self:bd_get_skill_queue()
  local target = self:_check_get_target()
  local ks = self.fighter.keyState

  if not ks then return false end
  ks:resetSignalVars()

  local sid = skills[index].sid
  local action = SkillActionFactory.make(self.fighter, sid)
  if aidbg.debug then
    logd("[QSKILL] real send sid:%s", inspect(action.data.tid))
  end

  if not self:_can_cast(action.data.tid) then
     if aidbg.debug then
       logd("[QSKILL] sid:%s action data tid:%s fighter canCast:%s model canCast:%s",
        tostring(sid),
        tostring(action.data.tid),
        tostring(self.fighter:canCast()),
        tostring(self.fighter.model:canCast(action.data.tid))
        )
     end
    return false
  end

  if skills[index].face_target or  skills[index].face_target == nil then
    local pos2 = target:position()
    local pos1 = self.fighter:position()
    local dir = Vector3.Normalized(pos2 - pos1)
    self.fighter:setForward(dir)
  end

  self:sendAction(action)

  --记录下来真正的施法id以后比对状态的使用要用
  self._real_skills = self._real_skills or {}
  self._real_skills[index] = action.data.tid

  self._skill_frame_count = 0
  self._calc_skill_frame = true

  if aidbg.debug then
     aidbg.log(0, "[DESIGN][%s] <color='#ff7e20'>队列攻击</color>: %s", inspect(self.fighter.id), inspect(sid))
  end

  return true
end

function m:cleanupSkillQueue()
  if aidbg.debug then
    aidbg.log(0, "[QSKILL] cleanup skill queue")
  end
  self:unscheduleSkillQueue()
  self:bd_set_skill_queue(nil)
  self:bd_set_sq_index(nil)
  self:bd_set_sq_end(nil)
  self.fighter.keyState:resetSignalVars()
end

function m:unscheduleSkillQueue()
  local h = self:bd_get_sq_handle()
  if aidbg.debug then
    aidbg.log(0, "[QSKILL] unschedule handle:%s", tostring(h))
  end
  if h then
    scheduler.unschedule(h)
    self:bd_set_sq_handle(nil)
  end
end

function m:getClipTime(anim_type)
  if anim_type == nil then return 0 end
  self.clipTimeCache = self.clipTimeCache or {}
  local t = self.clipTimeCache[anim_type]
  if not t then
    t = ClipUtil.getClipTime(self.fighter, anim_type)
    self.clipTimeCache[anim_type] = t
  end
  return t
end

function m:scheduleSkillQueue()
  --防止重入导致启动多个schedule
  self:unscheduleSkillQueue()
  if aidbg.debug then
    aidbg.log(0, "[QSKILL] begin skill queue check!")
  end
  local function stopQueue()
    self:bd_set_sq_end(true)
    self:unscheduleSkillQueue()
    self:bd_set_sq_handle(nil)
    self:bd_set_sq_index(nil)
    table.clear(self._real_skills)
  end

  local h = function (deltaTime)
    if not self:bd_get_sq_handle() then
      return
    end

    if self.destroyed then
      if aidbg.debug then
        aidbg.log(0, "[QSKILL] quit destroyed!")
      end
      stopQueue()
      return
    end

    if self.fighter.destroyed then
      stopQueue()
      return
    end

    local target = self:_check_get_target()
    if not target then
      if aidbg.debug then
        aidbg.log(0, "[QSKILL] quit - no target!")
      end
      stopQueue()
      return
    end

    local ks = self.fighter.keyState
    if ks.hasInput then
      if aidbg.debug then
        aidbg.log(0, "[QSKILL] quit - user input!")
      end
      stopQueue()
      return
    end

    if ks.interupted then
      if aidbg.debug then
        aidbg.log(0, "[QSKILL] quit - interupted!")
      end
      stopQueue()
      return
    end

    local skills = self:bd_get_skill_queue()
    if not skills then
      if aidbg.debug then
        aidbg.log(0, "[QSKILL] quit - queue empty!")
      end
      stopQueue()
      return
    end

    --存在这样一种情况，sendaction成功了，但是实际有可能在真正释放的时候失败的情况，
    --  （具体原因是action是放到一个action queue中在下一帧才会flush进行execut，
    --    到那时状态机驱动的时候发现transation检测不可释放，就会释放失败）
    --  所以这里需要对上一个释放出去的技能action做失败检测
    --  方法是 通过计数过了两帧时间 发现依然没有技能的 skillEnter就认为这个技能释放失败
    if self._calc_skill_frame and not ks.skillEnter then
      self._skill_frame_count = self._skill_frame_count + 1
      if self._skill_frame_count >= 2 then
        self._calc_skill_frame = false
        self._skill_frame_count = 0
        if aidbg.debug then
          aidbg.log(0, "[QSKILL] quit - timeout!")
        end
        stopQueue()
        return
      end
    end


    --注意：skillEnter标记和skillExit标记会同时出现，原因是切招过程中psskill -> psskill转换
    --     在同一帧完成，我们收到signal也是在同一帧，这样就需要我们先检测是否有新技能释放，然后再
    --     处理上一个技能退出
    if ks.skillEnter then
      --收到技能进入如果处于技能释放检测中需要终止检测
      if self._calc_skill_frame then
        self._calc_skill_frame = false
        self._skill_frame_count = 0
      end

      --技能释放后可以朝敌人移动
      local curIndex = self:bd_get_sq_index()
      local sid = self._real_skills[curIndex - 1]
      self:applySkillMovement(sid)
    end

    --检查apply的skill移动是否打到人，打到就停下移动
    if ks.skillHitted and self._apply_move then
      self:stopSkillMove()
    end

    if ks.skillExit then
      local curIndex = self:bd_get_sq_index()
      if ks.skillTid == 'any' then --解套
        stopQueue()
        return
      end

      local sid = self._real_skills[curIndex - 1]
      -- logd(">>>>sid:%s ks.skillTid:%s", inspect(sid), inspect(ks.skillTid))
      if sid == ks.skillTid then
        local stype = cfg.skills[sid]
        --不可切招的技能如果退出，但是并没有被打断，那么我们认为是技能释放完了可以放下一招
        if not stype.cancelable then
          if curIndex > #skills then
            if aidbg.debug then
              aidbg.log(0, "[QSKILL] quit - finished! curIndex:%s", inspect(curIndex))
            end
            stopQueue()
            return
          end

          if not self:doQueuedSkill(curIndex) then
            if aidbg.debug then
              aidbg.log(0, "[QSKILL] quit - can't release curIndex:%s!", inspect(curIndex))
            end
            stopQueue()
            return
          end
          self:bd_set_sq_index(curIndex + 1)
        else
          --如果可以切招但是技能退出，的同时并没有新技能进入，我们认为是新技能释放失败
          --或者是最后一个技能释放完了（策划要求这么做 最后一个技能要释放完）
          if not ks.skillEnter then
            if aidbg.debug then
              aidbg.log(0, "[QSKILL] quit - not switch!")
            end
            stopQueue()
            return
          end
        end
      else --也许被玩家切招了
        if aidbg.debug then
          aidbg.log(0, "[QSKILL] quit - switch by player!")
        end
        stopQueue()
        return
      end
    end


    --如果发现可以切换招数，就直接切换下一个技能
    local curIndex = self:bd_get_sq_index()
    if ks.skillSwitch and curIndex <= #skills then
      if aidbg.debug then
        aidbg.log(0, "[QSKILL] could switch!")
      end

      local skill = skills[curIndex]
      if skill.last_hit == true and not ks.skillHitted then
        if aidbg.debug then
          aidbg.log(0, "[QSKILL] quit - not hit target")
        end
        stopQueue()
        return
      end

      --无论释放与否都清除击中标志
      ks:resetSigVarByName('skillHitted')

      if not self.fighter:canCast()  then
        if aidbg.debug then
          aidbg.log(0, "[QSKILL] quit - can't cast")
        end
        stopQueue()
        return
      end

      if not self:doQueuedSkill(curIndex) then
        if aidbg.debug then
          aidbg.log(0, "[QSKILL] quit - can't release curIndex:%s", inspect(curIndex))
        end
        stopQueue()
        return
      end

      self:bd_set_sq_index(curIndex + 1)
    end

    -- logd("[aaaa] curIndex:%s", inspect(curIndex))

    --每帧处理完信号需要清除状态
    ks:resetSigVarPerFrm()
  end

  local handler = scheduler.scheduleWithUpdate(h)
  self:bd_set_sq_handle(handler)
end

--[[
    方法: force_queued_attack
    别名: 强制多段攻击
    描述: 如果没有队列的技能就释放之前设置的技能；
          如果有队列的技能则释放之前队列起来的技能列表，当前技能不释放，直接设空；
          第一个技能需要按照强制释放保证释放成功，然后一直检测排队技能是否可以释放；
          如果过程中发生被击打断的情况，返回成功；
          如果到了切招点可以释放后续技能，就释放；
          所有技能释放完成后返回成功
    参数: 无
]]
m.mnhs["force_queued_attack"] = "强制多段攻击"
function m:force_queued_attack(node)
  -- logd(">>>>>>>queue attack")
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
    local suc = self:force_attack(node)
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
  self:bd_set_cur_skill_info(nil)
  self:bd_set_move_speed(nil)

  local i = self:bd_get_sq_index() or 1
  if i == 1 then
    local sid = skills[1].sid
    if not self.fighter:canCast(sid)  then
      self:cleanupSkillQueue()
      return m.fail
    end

    self:bd_set_sq_index(1)

    if aidbg.debug then
      aidbg.log(0, "[DESIGN][%s] <color='#ff7e20'>普通队列攻击开始</color>, skills: %s", inspect(self.fighter.id), inspect(skills))
    end
    if not self:doQueuedSkill(1) then
      self:cleanupSkillQueue()
      return m.fail
    end

    self:bd_set_sq_index(2)
    self:bd_set_sq_end(false)
    self:scheduleSkillQueue()

    return m.running
  else
    return m.running
  end
end

function m:_can_cast(sid)
   return   sid and self.fighter:canCast() and
            self.fighter.psm.curState:canCast(sid) and
            self.fighter.model:canCast(sid)
end


--[[
    方法: force_attack
    别名: 强制攻击
    描述: 释放之前选定好的当前技能，内部检测是否可施法，如果不能会一直等到可以施法为止
    参数: 无
]]
m.mnhs["force_attack"] = "强制攻击"
function m:force_attack(node)
  local function clear()
    self:bd_set_cur_skill(nil)
    self:bd_set_cur_skill_info(nil)
    self:bd_set_move_speed(nil)
    self:bd_set_tm_start(nil)
    self.fighter.keyState:resetSignalVars()
  end

  if self:_is_dead() then
    clear()
    return m.fail
  end

  local sid = self:bd_get_cur_skill()
  if not sid then
    if aidbg.debug then
      aidbg.log(0, "...fail no skill", aidbg.ERROR)
    end
    clear()
    return m.fail
  end

  local target = self:_check_get_target()
  if not target then
    if aidbg.debug then
      aidbg.log(0, "...no target fail")
    end
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
    if not self.fighter:canCast() then
      clear()
      return m.fail
    end

    local action = SkillActionFactory.make(self.fighter, sid)

    if not self:_can_cast(action.data.tid) then
      clear()
      return m.fail
    end

    if self:bd_get_face_target() then
      local pos2 = target:position()
      local pos1 = self.fighter:position()
      local dir = Vector3.Normalized(pos2 - pos1)
      self.fighter:setForward(dir)
    end

    self:sendAction(action)

    if aidbg.debug then
      aidbg.log(0, "[DESIGN][%s] <color='#ffc500'>强制普通攻击</color>: %s", inspect(self.fighter.id), inspect(sid))
    end
    self:bd_set_face_target(nil)
    self:bd_set_tm_start(engine.time())
    ks:resetSignalVars()
    return m.running
  end

  if not ks.skillEnter then
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
    方法: attack
    别名: 攻击
    描述: 释放之前选定好的当前技能
    参数: 无
]]
m.mnhs["attack"] = "攻击"
function m:attack(node)
  if aidbg.debug then
    aidbg.log(0, ">>>>>>attack:"..tostring(self.fighter.keyState.state))
  end

  local function clear()
    self:bd_set_cur_skill(nil)
    self:bd_set_cur_skill_info(nil)
    self:bd_set_move_speed(nil)
    self:bd_set_tm_start(nil)
    self.fighter.keyState:resetSignalVars()
  end

  if self:_is_dead() then
    clear()
    return m.fail
  end

  local sid = self:bd_get_cur_skill()
  if not sid then
    if aidbg.debug then
      aidbg.log(0, "...fail no skill", aidbg.ERROR)
    end
    clear()
    return m.fail
  end

  local target = self:_check_get_target()
  if not target then
    if aidbg.debug then
      aidbg.log(0, "...no target fail")
    end
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
      return m.running
    end
    self:sendAction(action)

    if aidbg.debug then
      aidbg.log(0, "[DESIGN][%s] <color='#ffc500'>普通攻击</color>: %s", inspect(self.fighter.id), inspect(sid))
    end

    self:bd_set_tm_start(engine.time())
    ks:resetSignalVars()
    return m.running
  end

  if not ks.skillEnter then
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
    方法: delay
    别名: 延迟
    描述: idle 延迟一段时间
    参数: arg1 - 延时时间，单位秒 [float]
]]
m.mnhs["delay"] = "延迟"
function m:delay(node, tmSpan)
  local tmStart = self:bd_get_tm_start()
  if not tmStart then
    self:bd_set_tm_start(engine.time())
    return m.running
  end

  local now = engine.time()
  --logd(">>>>>>now:"..now)
  local pastTm = now - tmStart
  if pastTm >= tmSpan then

    if aidbg.debug then
      aidbg.log(0, "...delay success")
    end
    self:bd_set_tm_start(nil)
    return m.success
  end

  if aidbg.debug then
    aidbg.log(0, "...delay running")
  end

  return m.running
end


--[[
    方法: is_attr_in_range
    别名: 属性区间判断
    描述: 是否某个属性在某个范围内
          属性可以是agent支持的属性,也可以是entity的任意属性，
          属性如果是总量用属性名称，如果是当前量用"cur_"前缀加上属性名 例如: cur_hp cur_rage
          如果要获取目标属性，需要增加前缀"target.";例如：target.hp  target.cur_hp
    参数: arg1 - 属性名 [string]
         arg2 - 最小数值 [float]
         arg3 - 最大数值 [float]
         arg4 - 是否是百分比 [bool]
         arg5 - 包含属性区间的最小数值 [bool]
         arg6 - 包含属性区间的最大数值 [bool]
]]
m.mnhs["is_attr_in_range"] = "属性符合？"
function m:is_attr_in_range(node, attr, valueMin, valueMax, ratio, boundaryMin, boundaryMax)
  --logd(">>>>>>>valueMax"..inspect(valueMax))
  --logd(">>>>>>>valueMin"..inspect(valueMin))
  --获取目标属性
  local getter = nil
  if attr:match("^target.") then
    getter = self["attr_target_row_getter"]
  else
    --获取自身属性
    getter = self["attr_"..attr]
    if not getter then
      getter = self["attr_row_getter"]
    end
  end

  local value = getter(self, attr)
  if not value then
    if aidbg.debug then
      aidbg.log(0, "Not exist attr:"..tostring(attr))
    end

    return m.fail
  end
  if ratio then
    local faMax = self["attr_"..attr.."_max"]
    if not faMax then
      if aidbg.debug then
        aidbg.log(0, "Not exist attr max:"..tostring(attr))
      end

      return m.fail
    end
    local vMax = faMax(self)
    value = MathUtil.GetPreciseDecimal(value/vMax, 2)

    valueMax = MathUtil.GetPreciseDecimal(valueMax/100, 2)
    valueMin = MathUtil.GetPreciseDecimal(valueMin/100, 2)
  end

  local fitMin = m.fail
  local fitMax = m.fail
  if valueMin == "inf" then
    fitMin = true
  else
    if boundaryMin then
      fitMin = (value >= valueMin)
    else
      fitMin = (value > valueMin)
    end
  end

  if valueMax == "inf" then
    fitMax = true
  else
    if boundaryMax then
      fitMax = (value <= valueMax)
    else
      fitMax = (value < valueMax)
    end
  end

  -- logd(">>>>>>>value"..inspect(value))
  -- logd(">>>>>>>valueMin"..inspect(valueMin))
  -- logd(">>>>>>>valueMax"..inspect(valueMax))
  if (fitMin and fitMax) then
    --logd(">>>>>>>111"..inspect(111))
    return m.success
  end
  --logd(">>>>>>>222"..inspect(222))
  return m.fail
end

m._compare = function (v1, v2, op)
  if op == "~=" then
    return v1 ~= v2
  end

  if op == "==" then
    return v1 == v2
  end

  if op == ">" then
    return v1 > v2
  end

  if op == ">=" then
    return v1 >= v2
  end

  if op == "<" then
    return v1 < v2
  end

  if op == "<=" then
    return v1 <= v2
  end
end

function m:_parse_variable(var)
  --logd(">>>>>>>var"..inspect(var))
  local res = nil
  local n = tonumber(var)
  if n then
    res = n
  else
    local getter = nil
    if var:match("^target[.]") then
      getter = self["attr_target_row_getter"]
    else
      getter = self["attr_"..var]
      if not getter then
        getter = self["attr_row_getter"]
      end
    end

    res = getter(self, var)
    if not res then
      res = self.variables["var_"..var]
    end
  end

  return res
end

--[[
    方法: compare
    别名: 比较数值
    描述: 比较两个数值，可以使属性，自定义变量，常数任意比较，
          内部会判断是否是常数还是，属性，或是变量(判断顺序：是否常数 》是否目标属性 》是否自身属性 》是否变量)
          属性如果是总量用属性名称，如果是当前量用"cur_"前缀加上属性名 例如: cur_hp cur_rage
          属性可以是agent支持的属性,也可以是entity的任意属性，如果要获取目标属性，需要增加前缀"target.";例如：target.hp  target.cur_hp
    参数: arg1 - 属性名称，自定义变量名称，常数 [string]
         arg2 - 属性名称，自定义变量名称，常数 [string]
         arg3 - 比较操作 >, >=, <, <=, ==, ~= [string]
]]
m.mnhs["compare"] = "比较"
function m:compare(node, v1, v2, operate)
  local var1 = self:_parse_variable(v1)
  local var2 = self:_parse_variable(v2)
  --未找到变量或者属性
  if not var1 or not var2 then
    return m.fail
  end

  if aidbg.debug then
    aidbg.log(0, "compare "..v1..":"..var1.." "..v2..":"..var2)
  end

  if m._compare(var1, var2, operate) then
    if aidbg.debug then
      aidbg.log(0, "...compare success")
    end
    return m.success
  end

  if aidbg.debug then
    aidbg.log(0, "...compare fail")
  end

  return m.fail
end

--[[
    方法: assignment
    别名: 给属性或自定义变量赋值
    描述: 先查找属性，如果存在属性可以赋值，就给属性赋值，
         如果没有相应属性，给自定义变量赋值，
         如果该名字的变量没有的话，就增加一个变量，并将value赋值，
    参数: arg1 - 属性、变量名称 [string]
         arg2 - 数值(内部会转换成number) [string]
]]
m.mnhs["assignment"] = "赋值"
function m:assignment(node, varName, value)
  local setter = self["attr_set_"..varName]
  if setter then
    setter(self, tonumber(value))
  else
    self.variables["var_"..varName] = tonumber(value)
  end

  if aidbg.debug then
    aidbg.log(0, "...assignment success")
  end
  return m.success
end


m._calculate = function (v1, v2, op)
  if op == "+" then
    return v1 + v2
  end

  if op == "-" then
    return v1 - v2
  end

  if op == "*" then
    return v1 * v2
  end

  if op == "/" then
    return v1 / v2
  end

  if op == "%" then
    return v1 % v2
  end
end

--[[
    方法: calculate
    别名: 计算一个表达式，然后将结果赋值给某个自定义变量
    描述: 参与计算的可以是属性，可以使常数，可以是自定义变量；
         被赋值的必须是自定义变量，如果不存在，则直接创建
    参数: arg1 - 最后要赋值的变量名称 [string]
         arg2 - 属性，变量，常数[string]
         arg3 - 属性，变量，常数[string]
         arg4 - 操作符 + - * / % [string]
]]
m.mnhs["calculate"] = "计算"
function m:calculate(node, vx, v1, v2, operate)
  local var1 = self:_parse_variable(v1)
  assert(var1)
  local var2 = self:_parse_variable(v2)
  assert(var2)

  local ret = m._calculate(var1, var2, operate)

  local setter = self["attr_set_"..vx]
  if setter then
    setter(self, tonumber(ret))
  else
    self.variables["var_"..vx] = tonumber(ret)
  end

  return m.success
end

--[[
    方法: enter_fight_state
    别名: 进入战斗
    描述: 进入战斗模式，临时方法，提供一个进入战斗前的操作方法，例如：讲一句挑衅的话
    参数: arg1 - 要说的话 [string]
         arg2 -  要持续的时间 [float]
]]
m.mnhs["enter_fight_state"] = "进入战斗"
function m:enter_fight_state(node, words, tmSpan)
  local res = nil
  local tmStart = self:bd_get_tm_start()
  if not tmStart then
    tmStart = engine.time()
    self:bd_set_tm_start(tmStart)
    if self.env.scene.showSpeaker then
      self.env.scene:showSpeaker(self.fighter, words, tmSpan)
    end

    if aidbg.debug then
      aidbg.log(0, "...enter_fight_state begin running")
    end
    res = m.running
  end

  if node.registerFinish then
    node:registerFinish(function()
        if aidbg.debug then
          aidbg.log(0, "...enter_fight_state on finish")
        end
        self:bd_set_tm_start(nil)
        if self.env.scene.hideSpeaker then
          self.env.scene:hideSpeaker()
        end
      end)
  end

  local now = engine.time()
  local pastTm = now - tmStart
  if pastTm > tmSpan then
    if aidbg.debug then
      aidbg.log(0, "... enter_fight_state success")
    end
    res = m.success
  else
    if aidbg.debug then
      aidbg.log(0, "... enter_fight_state running")
    end
    res = m.running
  end

  return res
end

--[[
    方法: set_interval
    别名: 设置定时
    描述: 是指定时间隔
    参数: arg1 - 定时索引key [string]
          arg2 - 定时间隔单位S [float]
]]
m.mnhs["set_interval"] = "定时"
function m:set_interval(node, key, interval)
  local value = self:bd_get_interval(key)
  if not value then
    self:bd_set_interval(key, interval)
  end
  local ok = self:bd_interval_tick(key)
  if ok then
    return m.success
  end
  return m.fail
end

--[[
    方法: clear_interval
    别名: 清除定时
    描述: 清除定时
    参数: arg1 - 定时索引key [string]
]]
m.mnhs["clear_interval"] = "清除定时"
function m:clear_interval(node, key)
  self:bd_set_interval(key, nil)
  return m.success
end

--[[
    方法: buff_exist
    别名: buff存在否？
    描述: 查询是否存在某个buff 在身上
    参数: arg1 - buff id [string]
]]
m.mnhs["buff_exist"] = "有buff?"
function m:buff_exist(node, buffid)
  if self:_is_dead() then
    if aidbg.debug then
      aidbg.log(0, "...(deat) so buff_exist fail")
    end
    return m.fail
  end

  if self.fighter.model and self.fighter.model:buffExist(buffid) then
    if aidbg.debug then
      aidbg.log(0, "...buff_exist success")
    end
    return m.success
  end

  if aidbg.debug then
    aidbg.log(0, "...buff_exist fail")
  end
  return m.fail
end


--for test
--[[
    方法: success
    别名: 成功
    描述: 直接返回成功
    参数: 无
]]
m.mnhs["success"] = "成功"
function m:success(node)
  if aidbg.debug then
    aidbg.log(0, "...success success")
  end
  return m.success
end

--[[
    方法: fail
    别名: 失败
    描述: 直接返回失败
    参数: 无
]]
m.mnhs["fail"] = "失败"
function m:fail(node)
  if aidbg.debug then
    aidbg.log(0, "...fail fail")
  end
  return m.fail
end

--[[
    方法: running
    别名: 运行中
    描述: 运行一段时间然后返回成功
    参数: arg1 - 时间 [float]
]]
m.mnhs["running"] = "运行中"
function m:running(node, tmSpan)
  local tmStart = self:bd_get_tm_start()
  if not tmStart then
    self:bd_set_tm_start(engine.time())
    if aidbg.debug then
      aidbg.log(0, "...running running")
    end
    return m.running
  end

  if node.registerFinish then
    node:registerFinish(function()
        if aidbg.debug then
          aidbg.log(0, "...running on finish")
        end
        self:bd_set_tm_start(nil)
      end)
  end

  local now = engine.time()
  local pastTm = now - tmStart
  if aidbg.debug then
    aidbg.log(0, ">>>>pastTm:"..pastTm.." span:"..tmSpan)
  end
  if pastTm >= tmSpan then
    if aidbg.debug then
      aidbg.log(0, "...running success")
    end
    self:bd_set_tm_start(nil)
    return m.success
  end

  if aidbg.debug then
    aidbg.log(0, "...running running")
  end
  return m.running
end


--[[
    方法: set_movement_to_target_around
    别名: 设置移动朝目标环形区域
    描述: 设置以目标为中心，指定环形区域内的随机点为目标点
    参数: arg1 - 移动时间段 单位 秒[float]
          arg2 - 区域环内半径 精确到小数后两位 [float]
          arg3 - 区域换外半径 精确到小数后两位 [float]
]]
m.mnhs["set_movement_to_target_around"] = "朝目标环形区域"
function m:set_movement_to_target_around(node, tmSpan, rMin, rMax)
  local target = self:_check_get_target()
  if not target then
    return m.fail
  end
  local ptCenter = target:position()
  local x,z = self:_randomPosition(rMin, rMax, target.radius)

  local ptDst = Vector3(ptCenter[1] + x, ptCenter[2], ptCenter[3] + z)
  local ptSrc = self.fighter:position()

  local dir = Vector3.new(Vector3.Normalized(ptDst - ptSrc))
  local dist = MathUtil.dist2(ptSrc, ptDst)
  local tmStart = engine.time()

  self:bd_set_movement(dir, tmSpan, tmStart, Vector3.new(ptSrc), dist)

  return m.success
end

--[[
    方法: set_enemy_as_target_by_tid
    别名: 设置某个tid敌人为目标
    描述: 从敌人中找到资源是tid的敌人设置为目标，如果有多个相同tid的敌人，取找到的第一个
    参数: arg1 - 要是指的目标tid [string]
]]
m.mnhs["set_enemy_as_target_by_tid"] = "tid设成目标"
function m:set_enemy_as_target_by_tid(node, tid)
  local enemies = cc.enemySides(self.fighter.side)
  local target = nil
  if enemies then
    for i,v in pairs(enemies) do
      for j,e in cc.iterHeroes(v) do
        if e.config.tid == tid then
          target = e
          break
        end
      end
    end
  end

  if not target then
    if aidbg.debug then
      aidbg.log(0, "can't find target by tid:"..tostring(tid), aidbg.ERROR)
    end
    return m.fail
  end

  self:bd_set_target(target)
  if aidbg.debug then
    aidbg.log(0, "...set_enemy_as_target_by_tid success")
  end

  return m.success
end

function m:_randomPosition(rMin, rMax, radius)
  rMin = (rMin + radius) * 100
  rMax = (rMax + radius) * 100

  local rMin2 = rMin * rMin
  local rMax2 = rMax * rMax

  local x, z = nil, nil
  local i = 1

  while i < 50 do
    x = math.random(-rMax, rMax)
    z = math.random(-rMax, rMax)

    local m2 = x*x + z*z
    if m2 >= rMin2 and m2 <= rMax2 then
      local ptSrc = self.fighter:position()
      local ptDst = Vector3(x + ptSrc[1], 0, z + ptSrc[3])
      local dir = Vector3.new(Vector3.Normalized(ptDst - ptSrc))
      --local hitSomething = self:_hit_something(dir)
      local hitSomeBody = self:_hit_enemy(dir)
      if not hitSomeBody then
        break
      end
    end
    i = i + 1
  end

  x = x / 100
  z = z / 100
  return x, z
end

--[[
    方法: set_movement_to_comrade
    别名: 设置移动朝资源为tid战友
    描述: 从战友中寻找资源为tid的战友，向他靠近
    参数: arg1 - 要寻找的战友资源tid [string]
          arg2 - 区域环内半径 精确到小数后两位 [float]
          arg3 - 区域换外半径 精确到小数后两位 [float]
]]
m.mnhs["set_movement_to_comrade"] = "设置移动朝tid战友"
function m:set_movement_to_comrade(node, tid, rMin, rMax)
  local side = self.fighter.side
  local comrade = nil
  for k,v in cc.iterHeroes(side) do
    if v.config.tid == tid then
      comrade = v
      break
    end
  end

  if not comrade then
    return m.fail
  end

  local x,z = self:_randomPosition(rMin, rMax, comrade.radius)

  local ptCenter = comrade:position()
  local ptDst = Vector3(ptCenter[1] + x, ptCenter[2], ptCenter[3] + z)
  local ptSrc = self.fighter:position()

  local dir = Vector3.new(Vector3.Normalized(ptDst - ptSrc))
  local dist = MathUtil.dist2(ptSrc, ptDst)
  self:bd_set_movement(dir, 0, 0, Vector3.new(ptSrc), dist)
  return m.success
end

--[[
    方法: is_summoned
    别名: 本单位是否是召唤出来的
    描述: 是否是召唤出来的
    参数: 无
]]
m.mnhs["is_summoned"] = "summoned?"
function m:is_summoned(node)
  if self.fighter.summon_pid then
    return m.success
  end
  return m.fail
end

--[[
    方法: set_movement_to_summoner
    别名: 设置移动朝召唤出自己的单位
    描述: 移动到离召唤人距离为range的最近的位置,没有召唤者返回失败
    参数: arg1 - 区域环内半径 精确到小数后两位 [float]
          arg2 - 区域换外半径 精确到小数后两位 [float]
]]
m.mnhs["set_movement_to_summoner"] = "朝召唤移动"
function m:set_movement_to_summoner(node, rMin, rMax)
  local sid = self.fighter.summon_pid
  if not sid then
    return m.fail
  end
  local partner = self.env.cc.findHero(sid)
  if not partner then
    return m.fail
  end

  local x,z = self:_randomPosition(rMin, rMax, partner.radius)

  local ptCenter = partner:position()
  local ptDst = Vector3(ptCenter[1] + x, ptCenter[2], ptCenter[3] + z)
  local ptSrc = Vector3.new(self.fighter:position())

  local dir = Vector3.new(Vector3.Normalized(ptDst - ptSrc))
  local dist = MathUtil.dist2(ptSrc, ptDst)
  self:bd_set_movement(dir, 0, 0, ptSrc, dist)
  return m.success
end

--[[
    方法: random_play_anim
    别名: 随机播放动作
    描述: 播放动作集合，随机播放
    参数: arg1 - 动作集合以逗号分隔 [string]
]]
m.mnhs["random_play_anim"] = "随机休闲动作"
function m:random_play_anim(node, animations)
  local anims = string.split(animations, ',')
  if #anims == 0 then return m.fail end

  local tmStart = self:bd_get_tm_start()
  local tmSpan = self:bd_get_tm_span()
  if not tmStart then
    local i = math.random(#anims)
    local clip = anims[i]
    self.fighter:playAnim(clip, 0)
    local tmSpan = self:getClipTime(clip)
    local tmStart = engine.time()
    self:bd_set_tm_start(tmStart)
    self:bd_set_tm_span(tmSpan)
    return m.running
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

--internal methods
--权重节点的子节点支持填写字符串和数字
--当填写字符串的时候，需要从agent中该方法获取
--其他的agent类型需要重写该方法
function m:getWeight(name)
  return 0
end

--end method













