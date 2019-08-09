
class('AIUntilFail', function(self, config)
end, Decorator)

local m = AIUntilFail

function m:success()
  if aidbg.debug then
    aidbg.log(0, "...AIUntilFail running", 1)
  end
  self.control:running()
end

function m:fail()
  if aidbg.debug then
    aidbg.log(0, "...AIUntilFail success", 1)
  end
  self.control:success()
end