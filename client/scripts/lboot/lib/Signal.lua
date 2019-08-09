-- Signal.lua

Signal = class("Signal", function (o)
  o.handlers          = {}
  o.onceHandlers      = {}
  o.addedHandlers     = {}
  o.addedOnceHandlers = {}
end)

function Signal:fire(...)
  local handlers = self.handlers
  local onceHandlers = self.onceHandlers
  local addedOnceHandlers = self.addedOnceHandlers
  local currentFuncs = {}

  for i = 1, #handlers do
    local v = handlers[i]
    currentFuncs[#currentFuncs + 1] = v.handler
  end


  for i = 1, #onceHandlers do
    local v = onceHandlers[i]
    currentFuncs[#currentFuncs + 1] = v.handler
  end

  for i = #onceHandlers, 1, -1 do onceHandlers[i] = nil end
  for k, _ in pairs(addedOnceHandlers) do addedOnceHandlers[k] = nil end

  -- execute the callbacks at the end to avoid exception breaking the data structure
  for i = 1, #currentFuncs do
    currentFuncs[i](...)
  end
end

function Signal:add(handler, index)
  if handler == nil then return nil end
  if self:added(handler) then return handler end

  if index then
    table.insert(self.handlers, index, { handler = handler })
  else
    self.handlers[table.getn(self.handlers)+1] = { handler = handler }
  end

  self.addedHandlers[handler] = true
  return handler
end

function Signal:addOnce(handler)
  if handler == nil then return end
  if self:added(handler) then return handler end
  self.onceHandlers[table.getn(self.onceHandlers)+1] = { handler = handler }
  self.addedOnceHandlers[handler] = true
  return handler
end

function Signal:added(handler)
  if handler == nil then return false end
  return op.truth(self.addedHandlers[handler]) or op.truth(self.addedOnceHandlers[handler])
end

function Signal:remove(handler)
  if handler == nil then return end
  if self.addedHandlers[handler] then
    local handlers = self.handlers
    for i = 1, #handlers do
      local v = handlers[i]
      if v.handler == handler then
        self.addedHandlers[handler] = nil
        table.remove(handlers, i)
        break
      end
    end
  end

  if self.addedOnceHandlers[handler] then
    local onceHandlers = self.onceHandlers
    for i = 1, #onceHandlers do
      local v = onceHandlers[i]
      if v.handler == handler then
        self.addedOnceHandlers[handler] = nil
        table.remove(onceHandlers, i)
        break
      end
    end
  end
end

function Signal:clear()
  local handlers = self.handlers
  local onceHandlers = self.onceHandlers
  local addedHandlers = self.addedHandlers
  local addedOnceHandlers = self.addedOnceHandlers

  for i = #handlers, 1, -1 do handlers[i] = nil end
  for i = #onceHandlers, 1, -1 do onceHandlers[i] = nil end
  for k, _ in pairs(addedHandlers) do addedHandlers[k] = nil end
  for k, _ in pairs(addedOnceHandlers) do addedOnceHandlers[k] = nil end
end
