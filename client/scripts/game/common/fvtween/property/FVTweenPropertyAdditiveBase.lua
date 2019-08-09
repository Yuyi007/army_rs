class('FVTweenPropertyAdditiveBase', function(self)
  self:init()
end)

local m = FVTweenPropertyAdditiveBase

function m:init()
  self.curDuration = 0
end

function m:initParams(propertyName, totalDuration, relative, pos)
  self.propertyName = propertyName
  self.totalDuration = totalDuration
  self.relative = relative
  self.pos = pos
end

function m:validateTarget(target)
  self.getPropCB, self.setPropCB = FVTweenUtils.getPropertyAccessor(target, self.propertyName)

  local startValue = self.getPropCB()
  local endValue
  if self.relative then
    endValue = startValue + self.pos
  else
    endValue = self.pos
  end

  local diffValue = endValue - startValue
  self.incValue = Vector3.new(diffValue / self.totalDuration)

  self.inited = true
end

function m:tick(elapsedTime)
  if not self.inited or
     not self.setPropCB or
     not self.getPropCB then
    return
  end
  elapsedTime = math.min(elapsedTime, self.totalDuration)
  if self.curDuration >= elapsedTime then
    return
  end
  local deltaTime = elapsedTime - self.curDuration
  self.curDuration = elapsedTime

  self:onTick(deltaTime)
end

function m:onTick(deltaTime)
  local prop = self.getPropCB()
  local newProp = prop + self.incValue * deltaTime
  self.setPropCB(newProp)
end

function m:isTweenDone()
  return self.curDuration >= self.totalDuration
end

