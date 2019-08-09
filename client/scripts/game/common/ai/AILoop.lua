class('AILoop', function(self)
  self.num = 1
  self.count = 0
  self.nodeRunning = false
end, Decorator)

local m = AILoop

function m:init(cfg)
  self.num = cfg["num"]
end

function m:finish(agent)
  Decorator.finish(self, agent)
  self.count = 1
end

function m:running()
  self.nodeRunning = true
  Decorator.running(self)
end

function m:run(object)
  if aidbg.debug then
    aidbg.changeLineColor(self, true)
  end

  if not self.nodeRunning then
    self.nodeRunning = false
    self.node:start(object)
    self.node:setControl(self)
  end
  self.node:call_run(object)
end

function m:onComplete()
  self.nodeRunning = false
  if self.num >= 0 then
    if self.count < self.num then
      self.count = self.count + 1
      if aidbg.debug then
        aidbg.log(0, "...AILoop running num:"..tostring(self.num).." count:"..tostring(self.count))
      end
      Decorator.resetAllBranchNode(self.node)
      self:running()
    else
      if aidbg.debug then
        aidbg.log(0, "...AILoop success", 1)
      end
      Decorator.success(self)
    end
  else -- -1表示无限循环
    self.count = self.count + 1
    if aidbg.debug then
      aidbg.log(0, "...AILoop running", 1)
    end
    Decorator.resetAllBranchNode(self.node)
    Decorator.running(self)
  end
end

function m:forceReset()
  self.count = 1
end

function m:success()
  self:onComplete()
end

function m:fail()
  self:onComplete()
end