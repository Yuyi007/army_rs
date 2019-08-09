class('AIWeightSelector', function(self, config)
  self.totalWeight = nil
end, BranchNode)

local m = AIWeightSelector

function m:start(agent)
  BranchNode.start(self, agent)
  --If total weight is 0, we just make this node success
  if self.actualTask == -1 then
    self:success()
  end
end

function m:resetActualTask()
  if not self.totalWeight then
    self:calcTotalWeight()
  end
  self.actualTask = self:randomWeight()
end

function m:randomWeight()
  if self.totalWeight == 0 then
    return -1
  end

  local r = math.random(self.totalWeight)
  local w = 0
  for i=1,#self.nodes do
    local min = w
    local sw = self.object:getWeight(self.nodes[i].weight) or 0

    sw = tonumber(sw)
    if not sw then
      sw = self.object:getWeight(self.nodes[i].weight)
    end

    local max = w + sw
    if r > min and r <= max then
      return i
    end
    w = max
  end
  return 1
end

function m:calcTotalWeight()
  self.totalWeight = 0
  if self.nodes then
    for i,v in pairs(self.nodes) do
      local weight = v.weight or 0
      weight = tonumber(weight)
      if not weight then
        weight = self.object:getWeight(v.weight)
      end
      self.totalWeight = self.totalWeight + weight
    end
  end
end

function m:success()
  BranchNode.success(self)
  if aidbg.debug then
    aidbg.log(0, "...AIWeightSelector success", 1)
  end
  self.control:success()
  self:resetActualTask()
end

function m:fail()
  BranchNode.fail(self)
  if aidbg.debug then
    aidbg.log(0, "...AIWeightSelector fail", 1)
  end
  self.control:fail()
  self:resetActualTask()
end