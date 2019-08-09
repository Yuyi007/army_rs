class('AIExecutor', function(self, options)
  self.lastAttacker = nil
  self.lastAction = nil
end, InputState)

local m = AIExecutor

function m:init()
  InputState.init(self)
  self:clearFrameResult()
  self:registSignals()
end

function m:resetSignalVars()
  -- logd(">>>>reset %s", debug.traceback())
  self.interupted = false
  self.skillSwitch = false
  self.skillHitted = false
  self.skillExit = false
  self.skillEnter = false
end

function m:resetSigVarPerFrm(varName)
  self.interupted = false
  self.skillSwitch = false
  self.skillExit = false
  self.skillEnter = false
end

function m:resetSigVarByName(name)
  self[name] = false
end

function m:registSignals()
  self.player:setInputSignal()
  local signal = self.player:getInputSignal()
  if signal then
    signal:add(function(t, uuid, sid)
      -- if aidbg.debug then
      --   aidbg.log(0, "[QSKILL] t:%s received", tostring(t))
      -- end
      if t == "stop" then       --被打断
        if not self.player:isBati() and
           not self.player:isInvincible() then
          self.interupted = true
        end
      elseif t == "start" then  --到切招点
        self.skillSwitch = true
      elseif t == "hit" then    --打到人
        self.skillHitted = true
      elseif t == "exitSkill" then --技能放完
        self.skillExit = true
        self.skillTid = sid
      elseif t == "enter" then
        self.skillEnter = true --技能进入
        self.skillTid = sid
      end
    end)
  end
end


function m:exit()
  InputState.exit(self)

  if self.action then
    self.action:release()
    self.action = nil
  end

  if self.lastAction then
    self.lastAction:release()
    self.lastAction = nil
  end
end

function m:getLastAttacker()
  return self.lastAttacker
end

function m:clearLastAttacker()
  self.lastAttacker = nil
end

function m:handleAttackedByFighter(collider)
  if InputState.handleAttackedByFighter(self, collider) then
    local attackerInfo = FighterUtil.getFighterInfoHashByCollider(collider)
    if attackerInfo.fighter.model.side ~= self.player.model.side then
      self.lastAttacker = attackerInfo.fighter
      self.player:signal('hitted'):fire(attackerInfo)
    end
    return true
  else
    return false
  end
end

function m:handleAttackedByProjectileHit(collider)
  if InputState.handleAttackedByProjectileHit(self, collider) then
    local proj = FighterUtil.getProjByCollider(collider)
    if proj.player.model.side ~= self.player.model.side then
      self.lastAttacker = proj.player
      local attackerInfo = FighterUtil.getProjInfoHashByCollider(collider)
      self.player:signal('hitted'):fire(attackerInfo)
    end
    return true
  else
    return false
  end
end

function m:OnAnimEvent(param)
  InputState.OnAnimEvent(self, param)
  -- if string.find(param, "anim_end") then
  --  self:endAction()
  -- end
end

function m:checkClearAttacker()
  if self.lastAttacker and self.lastAttacker:died() then
    self.lastAttacker = nil
  end
end

function m:updateInputs(deltaTime)
  InputState.updateInputs(self)
  self:checkClearAttacker()
end


