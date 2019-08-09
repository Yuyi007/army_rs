
class('AIReturnRunning', function(self, config)
end, Decorator)

local m = AIReturnRunning

function m:success()
  if aidbg.debug then
    aidbg.log(0, "...AIReturnRunning success => running", 1)
  end
  self.control:running()
end

function m:fail()
  if aidbg.debug then
    aidbg.log(0, "...AIReturnRunning fail => running", 1)
  end
  self.control:running()
end