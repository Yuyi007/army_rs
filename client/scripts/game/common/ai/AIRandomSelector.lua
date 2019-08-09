class('AIRandomSelector', function(self, config)
end, BranchNode)

local m = AIRandomSelector

function m:start(object)
  BranchNode.start(self, object)
  self:resetActualTask()
end

function m:resetActualTask()
  self.actualTask = math.floor(math.random() * #self.nodes+1)
end

function m:success()
  if aidbg.debug then
    aidbg.log(0, "...AIRandomSelector success", 1)
  end
  BranchNode.success(self)
  self.control:success()
  self:resetActualTask()
end

function m:fail()
  if aidbg.debug then
    aidbg.log(0, "...AIRandomSelector fail", 1)
  end
  BranchNode.fail(self)
  self.control:fail()
  self:resetActualTask()
end