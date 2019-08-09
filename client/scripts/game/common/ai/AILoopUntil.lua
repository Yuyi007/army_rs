class('AILoopUntil', function(self)
  self.condition = nil
  self.finished = false
end, AILoop)

local m = AILoopUntil

function m:init(cfg)
  AILoop.init(self, cfg)
  local condition = cfg["condition"]
  if condition == "y" then
    self.condition = true
  elseif condition == "n" then
    self.condition = false
  else
    error("Invalid condition attr:"..tostring(condition), 3)
  end
end

function m:run(object)
  if self.finished then
    self.node:success()
  end

  AILoop.run(self, object)
end

function m:finish(agent)
  Decorator.finish(self, agent)
  self.finished = true
end

function m:onComplete(suc)
  if self.condition == true and suc then
    if aidbg.debug then
      aidbg.log(0, "...AILoopUntil success", 1)
    end
    Decorator.success(self)
    return
  end

  if self.condition == false and not suc then
    if aidbg.debug then
      aidbg.log(0, "...AILoopUntil fail", 1)
    end
    Decorator.fail(self)
    return
  end

  AILoop.onComplete(self)
end

function m:success()
  self:onComplete(true)
end

function m:fail()
  self:onComplete(false)
end