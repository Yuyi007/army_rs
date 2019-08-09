
class('AIUntilSuccess', function(self, config)
end, Decorator)

local m = AIUntilSuccess

function m:success()
  if aidbg.debug then
    aidbg.log(0, "...AIUntilSuccess success", 1)
  end
  self.control:success()
end

function m:fail()
  if aidbg.debug then
    aidbg.log(0, "...AIUntilSuccess running", 1)
  end
  self.control:running()
end