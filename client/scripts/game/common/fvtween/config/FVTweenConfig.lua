class('FVTweenConfig', function(self, options)
  self:init()
end)

local m = FVTweenConfig

function m:init()
  self.properties = {}
  self.totalDuration = 0

end

function m:positionAdditive(pos, totalDuration, relative)
  local property = FVTweenPropertyVec3Additive.new()
  property:initParams('position', totalDuration, relative, Vector3.new(pos))
  table.insert(self.properties, property)
  self.totalDuration = math.max(self.totalDuration, totalDuration)
  return self
end

function m:onComplete(onComplete)
  self.onCompleteFunc = onComplete
  return self
end

function m:delay(delayTime)
  local property = FVTweenPropertyDelay.new({})
  table.insert(self.properties, property)
  return self
end

function m:validateTarget(target)
  for k, v in pairs(self.properties) do
    v:validateTarget(target)
  end
end

function m:tick(elapsedTime)
  if elapsedTime >= self.totalDuration then
    if self.onCompleteFunc then
      self.onCompleteFunc()
      self.onCompleteFunc = nil
    end
  end

  for k, v in pairs(self.properties) do
    v:tick(elapsedTime)
  end
end

setmetatable(FVTweenConfig, {
  __call = function(t)
    return t.new({})
  end
})