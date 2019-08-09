class('StateBase', function(self, fsm)
  self.fsm = fsm
  self.transitions = {}
  self.owner = self.fsm.owner
  self:init()
end)

local m = StateBase

function m:init()
  self:initTransitions()
end

function m:initTransitions()
end

function m:reopenInit(fsm)
  -- logd('[%s] reopenInit', self.class.classname)
  self.fsm = fsm
  self.owner = fsm.owner
end

function m:reopenExit()
  -- logd('[%s] reopenExit', self.class.classname)
  self.fsm = nil
  self.owner = nil
end

function m:enter()
  -- loge('State enter: %s', tostring(self:stateName()))
  self.elapsedTime = 0
  self.startTime = Time:get_realtimeSinceStartup()
  self.active = true
  if self.onEnter then self:onEnter() end
end

function m:elapsed()
  return self.elapsedTime
end

function m:fixedUpdate(deltaTime)
  if not self.active then return end

  if self.onFixedUpdate then self:onFixedUpdate(deltaTime) end
end

function m:update(deltaTime)
  self.deltaTime = deltaTime
  if not self.active then return end
  if self:updateTransitions() then return end
  if self.onUpdate then self:onUpdate(deltaTime) end
  self.elapsedTime = Time:get_realtimeSinceStartup() - self.startTime
end

function m:exit()
  -- loge('State exit: %s', tostring(self:stateName()))
  self.active = false
  if self.onExit then self:onExit() end
end

function m:addTransition(...)
  local arg = {...}
  for i = 1, #arg do local v = arg[i]
    table.insert(self.transitions, v)
  end
end

function m:updateTransitions()
  local transitions = self.transitions
  for i = 1, #transitions do
    local v = transitions[i]
    if v.condition() then
      v.toState()
      return true
    end
  end

  return false
end

function m:owner()
  return self.fsm.owner
end

function m:stateName()
  return self.class.classname
end

function m:onCommand(command, ...)
  if self[command] and type(self[command] == 'function') then
    self[command](self, ...)
  end
end

function m.transition(condition, toState)
  return {condition = condition, toState = toState}
end


