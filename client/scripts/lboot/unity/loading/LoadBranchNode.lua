class("LoadBranchNode", function(self, options)
  self.branchNode = true
  self.parentNode = nil
  self.finished = false
  self.parallel_count = 5
  self.curIndex = 0
  self.childNodes = {}
  self.finishCount = 0

  if options then
    self.options = options
    self.name = options.name
    self.onFinished = options.onFinished
    self.parallel_count = options.parallel_count or 5
    if options.nodes then
      local nodes = options.nodes
      if #nodes > 0 then
        self:addChildren(unpack(nodes))
      end
    end
  end

end)

local m = LoadBranchNode
local unity = unity

function m:iterateLeaves(func)
  for i,v in pairs(self.childNodes) do
    if v.leafNode then
      func(v)
    else
      v:iterateLeaves(func)
    end
  end
end

function m:iterateBranches(func)
  for i,v in pairs(self.childNodes) do
    if v.leafNode then
      -- nothing to do
    else
      func(v)
      v:iterateBranches(func)
    end
  end
end

function m:childCount()
  return #self.childNodes
end

function m:getCount()
  local count = 0
  for _,v in ipairs(self.childNodes) do
    if v.branchNode then
      count = count + v:getCount()
    elseif v.leafNode then
      count = count + 1
    end
  end
  return count
end

function m:getProgressCount()
  local count = 0
  for _,v in ipairs(self.childNodes) do
    if v.branchNode then
      count = count + v:getProgressCount()
    elseif v.leafNode then
      count = count + (v.count or 1)
    end
  end
  return count
end

function m:setParentNode(node)
  self.parentNode = node
end

function m:addChildNode(node)
  node:setParentNode(self)
  table.insert(self.childNodes, node)
  if node.bundles then
    self.bundles = self.bundles or {}
    for k, v in pairs(node.bundles) do
      self.bundles[k] = v
    end
  end
end

function m:addChildren(...)
  local nodes = {...}
  for i, v in ipairs(nodes) do
    self:addChildNode(v)
  end
end

function m:onChildNodeFinish(childNode)
  -- logd('[loading finished] %s', tostring(childNode.name or childNode.classname))
  self.finishCount = self.finishCount + 1
  if self.finishCount > #self.childNodes then
    logd("[dbgload] trace back:%s", debug.traceback())
  end
  -- logd("[dbgload] %s - on child finish self.finishcount:%s childNode:%s", tostring(self.name), tostring(self.finishCount), tostring(childNode.name))
  self:checkFinished()
  self:startOneWork()
end

function m:startOneWork()
  unity.beginSample('LoadBranchNode.startOneWork')

  self.curIndex = self.curIndex + 1
  if self.curIndex > #self.childNodes then
    unity.endSample()
    return false
  end

  local task = self.childNodes[self.curIndex]
  -- logd("[dbgload] %s - startOneWork self.finishcount:%s task:%s", tostring(self.name), tostring(self.finishCount), tostring(task.name))
  -- logd('[loading started] %s', tostring(task.name or task.classname))
  logd('[LoadTaskNode] start %s', tostring(task.name))
  task.startLoadTime = Time:get_time()
  task:startLoad()

  unity.endSample()
  return true
end

function m:startLoad()
  unity.beginSample('LoadBranchNode.startLoad %s', tostring(self.name))
  LoadTaskNode.startLoad(self)
  for i=1, self.parallel_count do
    if not self:startOneWork() then
      break
    end
  end

  unity.endSample()
end

function m:checkFinished()
  if self.finishCount > #self.childNodes then
    loge("loading branch node working count %s %s", tostring(self.name), tostring(self.finishCount))
  end

  if self.finishCount == #self.childNodes then
    logd("[loading finished] branch node counts: %s %s", tostring(self.name), tostring(#self.childNodes))
    self.finished = true

    if self.parentNode and self.parentNode.onChildNodeFinish then
      self.parentNode:onChildNodeFinish(self)
    end

    if self.onFinished then
      self.onFinished()
    end
  else
    self.finished = false
  end
end

function m:stopLoad()
  unity.beginSample('LoadBranchNode.stopLoad %s', tostring(self.name))

  logd('[LoadBranchNode] stopLoad')
  self.stopped = true
  self:iterateLeaves(function(taskNode)
    taskNode:stopLoad()
  end)

  unity.endSample()
end
