class('AICountLimit', function(self)
  self.finished = false
end, AILoop)

local m = AICountLimit

function m:finish(agent)
  Decorator.finish(self, agent)
  self.finished = true
end

function m:run(object)
  if self.finished then
    self.node:success()
  end

  AILoop.run(self, object)
end

function m:onComplete(suc)
  if self.num >= 0 then
    if self.count < self.num then
      self.count = self.count + 1
      if suc then
        if aidbg.debug then
          aidbg.log(0, "...AICountLimit success", 1)
        end
        Decorator.success(self)
      else
        if aidbg.debug then
          aidbg.log(0, "...AICountLimit fail", 1)
        end
        Decorator.fail(self)
      end
    else
      if aidbg.debug then
        aidbg.log(0, "...AICountLimit finish fail", 1)
      end
      Decorator.fail(self)
    end
  else -- -1表示无限循环
    self.count = self.count + 1
    if suc then
      if aidbg.debug then
        aidbg.log(0, "...AICountLimit success", 1)
      end
      Decorator.success(self)
    else
      if aidbg.debug then
        aidbg.log(0, "...AICountLimit fail", 1)
      end
      Decorator.fail(self)
    end
  end
end

function m:success()
  self:onComplete(true)
end

function m:fail()
  self:onComplete(false)
end