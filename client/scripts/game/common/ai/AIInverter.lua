class('AIInverter', function(self, config)
end, Decorator)

local m = AIInverter

function m:success()
  if aidbg.debug then
    aidbg.log(0, "AIInverter fail")
  end
  self.control:fail()
end

function m:fail()
  if aidbg.debug then
    aidbg.log(0, "AIInverter success")
  end
  self.control:success()
end
