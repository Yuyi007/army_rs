
class('AIReturnSuccess', function(self, config)
end, Decorator)

local m = AIReturnSuccess

function m:success()
  if aidbg.debug then
    aidbg.log(0, "...AIReturnSuccess success", 1)
  end
  self.control:success()
end

function m:fail()
  if aidbg.debug then
    aidbg.log(0, "...AIReturnSuccess success", 1)
  end
  self.control:success()
end