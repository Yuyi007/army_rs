--[[
 Monitor the valid condition of the running node
--]]

class('Monitor', function(self, config)
end, Decorator)

local m = Monitor

function m:run(object)
  if aidbg.debug then
    aidbg.changeLineColor(self, true)
  end
  --logd("run:"..debug.traceback())
  self.node:setControl(self)
  if self:valid(object) then
    self.node:call_run(object)
  else
    Decorator.resetAllBranchNode(self.node)
    --self.node:fail()
    Decorator.fail(self) -- 直接打断
  end
end

-- override this function
-- to validate the precondition of run
function m:valid(object)
  return true
end
