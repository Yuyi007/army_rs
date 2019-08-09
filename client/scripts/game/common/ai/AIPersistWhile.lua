class('AIPersistWhile', function(self, config)
    self.tmSpan = 0
    self.tmStart = nil
  end, Decorator)

local m = AIPersistWhile

function m:init(cfg)
  self.tmSpan = tonumber(cfg["tmspan"])
end

function m:start(object)
  if aidbg.debug then
    aidbg.log(0, "...AIPersistWhile start")
  end
  Decorator.start(self, object)

  if not self.tmStart then
    self.tmStart = engine.time()
  end
end

function m:running()
  if aidbg.debug then
    aidbg.log(0, "...AIPersistWhile running:"..tostring(self.uid))
  end
  self:onComplete()
end

function m:onComplete()
  local now = engine.time()
  if (now - self.tmStart) >= self.tmSpan then
    if aidbg.debug then
      aidbg.log(0, "...AIPersistWhile success2")
    end
    self.tmStart = nil
    Decorator.resetAllBranchNode(self.node)
    Decorator.success(self)
  else
    if aidbg.debug then
      aidbg.log(0, "...AIPersistWhile running 2")
    end
    Decorator.running(self)
  end
end

function m:success()
  self:onComplete()
end

function m:fail()
  self:onComplete()
end

function m:forceReset()
  self.tmStart = nil
end