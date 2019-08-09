class('FVTweenChain', function(self)
end, FVTweenBase)

local m = FVTweenChain

function m:init()
  self.children = {}
  self.duration = 0
  self.curDuration = 0
  self.checkStart = 1
  self.isDone = false
end

function m:tick(deltaTime)
  if self:isTweenDone() then
    return
  end

  local preDuration = self.curDuration
  self.curDuration = self.curDuration + deltaTime
  local curFinishTime = self:getCurFinishTime()
  -- check if curDuration is beyond the current tween
  while curFinishTime < self.curDuration do
    local curTween = self:getCurTween()
    -- update to the end of this tween
    curTween.tween:tick(curTween.tween:getDuration())
    -- process next tween
    self.checkStart = self.checkStart + 1
    preDuration = curTween.finishTime
    curFinishTime = self:getCurFinishTime()
  end
  local realDeltaTime = self.curDuration - preDuration
  local curTween = self:getCurTween()
  if curTween then
    curTween.tween:tick(realDeltaTime)
  end
end

function m:getCurTween()
  return self.children[self.checkStart]
end

function m:getLastFinishTime()
  if self.checkStart > 1 then
    return self.children[self.checkStart-1].finishTime
  else
    return 0
  end
end

function m:getCurFinishTime()
  local curTween = self:getCurTween()
  if curTween then
    return curTween.finishTime
  else
    return self.curDuration
  end
end

function m:isTweenDone()
  return self.curDuration >= self.duration or self.isDone
end

function m:getDuration()
  return self.duration
end

function m:append(tween)
  table.insert(self.children, {
    tween = tween,
    finishTime = self:getDuration() + tween:getDuration()
  })
  self.duration = self.duration + tween:getDuration()
end

function m:appendDelay(delayTime)
  local tween = FVTween(
    nil,
    delayTime,
    FVTweenConfig():delay(delayTime)
  )
  self:append(tween)
end

function m:prepend(tween)
  table.insert(self.children, 1, tween)
  self:refreshAllChildren()
  self.duration = self.duration + tween:getDuration()
end

function m:refreshAllChildren()
  local lastFinishTime = 0
  for i = 1, #self.children do local v = self.children[i]
    v.finishTime = lastFinishTime + v.tween:getDuration()
    lastFinishTime = v.finishTime
  end
end

setmetatable(FVTweenChain, {
  __call = function(t)
    return t.new()
  end
})
