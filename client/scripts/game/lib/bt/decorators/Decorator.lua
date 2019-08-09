class('Decorator', function(self, config)
end, Node)

local m = Decorator

function m:initialize(config)
  Node.initialize(self)
end

function m:setNode(node)
  self.node = node
end

function m:start(object)
  if aidbg.debug then
    aidbg.log(0, "...start"..self.classname.." uid:"..tostring(self.uid))
  end
  self.node:setControl(self)
  self.node:start(object)
end

function m:finish(object)
  self.node:finish(object)
end

function m:run(object)
  if aidbg.debug then
    aidbg.changeLineColor(self, true)
  end

  self.node:call_run(object)
end

--打断子节点的时候需要 强制重置所有分支节点
function m.resetAllBranchNode(n)
  if n.node then
    m.resetAllBranchNode(n.node)
  end
  if aidbg.debug then
    --aidbg.log(0, ">>>>>>>n.classname"..inspect(n.classname))
  end
  n:forceReset()
end