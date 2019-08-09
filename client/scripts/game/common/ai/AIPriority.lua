class('AIPriority', function(self)
end, BranchNode)

local m = AIPriority

function m:success()
  BranchNode.success(self)
  if aidbg.debug then
    aidbg.log(0, "...AIPriority success", 1)
  end
  self.control:success()
end

function m:fail()
  BranchNode.fail(self)
  self.actualTask = self.actualTask + 1
  if self.actualTask <= #self.nodes then
    self:_run(self.object)
  else
    if aidbg.debug then
      aidbg.log(0, "...AIPriority fail", 1)
    end
    self.control:fail()
  end
end