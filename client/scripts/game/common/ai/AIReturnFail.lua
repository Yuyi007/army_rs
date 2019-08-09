class('AIReturnFail', function(self, config)
end, Decorator)

local m = AIReturnFail

function m:success()
  if aidbg.debug then
    aidbg.log(0, "...AIReturnFail fail", 1)
  end
  self.control:fail()
end

function m:fail()
  if aidbg.debug then
    aidbg.log(0, "...AIReturnFail fail", 1)
  end
  self.control:fail()
end