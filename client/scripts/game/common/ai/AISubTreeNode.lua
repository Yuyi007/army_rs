class('AISubTreeNode', function(self)
end, Node)

local m = AISubTreeNode

function m:start(object)
  self.node:start(object)
end

function m:finish(object)
  self.node:finish(object)
end

function m:run(object)
  if aidbg.debug then
    aidbg.changeLineColor(self, true)
  end
  self.node:setControl(self)
  self.node:call_run(object)
end
