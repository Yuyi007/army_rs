
class('StateMachine', function(self, opt)
  if opt then
    self.owner = opt.owner
  end
  self.enabled = true
  self.allStates = nil
  -- state stacks
  self.states = {}
end)

local m = StateMachine

function m:reopenInit(owner)
  -- logd('[%s] reopenInit', self.class.classname)
  self.owner = owner
  self.enabled = true

  for k, state in pairs(self.allStates) do
    state:reopenInit(self)
  end
end

function m:reopenExit()
  -- logd('[%s] reopenExit', self.class.classname)
  self.owner = nil

  for k, state in pairs(self.allStates) do
    state:reopenExit()
  end
end

function m:update(deltaTime)
  if not self.enabled then return end

  local top = self:currentState()
  if top then
    top:update(deltaTime)
  end
end

function m:push(state)
  local top = self:currentState()
  if top then top:exit() end

  local states = self.states
  if top and top:stateName() == state:stateName() then
    states[#states] = state
  else
    states[#states + 1] = state
  end

  state:enter()
end

-- clear the state stacks and switch to the given state
function m:switch(state)
  self:clear()

  if state then
    self:push(state)
  end
end

function m:pop()
  local popped = self:currentState()
  if popped then popped:exit() end
  self.states[#self.states] = nil
  local top = self:currentState()
  if top then top:enter() end
end

function m:clear()
  local states = self.states
  for i = #states, 1, -1 do
    states[i]:exit()
    states[i] = nil
  end
end

function m:currentState()
  return self.states[#self.states]
end

function m:onCommand(command, ...)
  local top = self:currentState()
  if top then top:onCommand(command, ...) end
end