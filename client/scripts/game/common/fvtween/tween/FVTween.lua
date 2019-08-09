class('FVTween', function(self, options)
end, FVTweenBase)

local m = FVTween
local fvtc = FVTController

function m:init()
  self.curDuration = 0
  self.isDone = false
end

function m:initParams(target, duration, tweenConfig)
  self.target = target
  self.duration = duration
  self.tweenConfig = tweenConfig
  self.tweenConfig:validateTarget(self.target)
end

function m:tick(deltaTime)
  if self:isTweenDone() then
    return
  end
  self.curDuration = self.curDuration + deltaTime
  self.tweenConfig:tick(self.curDuration)
end

function m:isTweenDone()
  return self.curDuration >= self.duration or self.isDone
end

function m:getDuration()
  return self.duration
end

setmetatable(FVTween, {
  __call = function(t, target, duration, tweenConfig)
    local tween = t.new()
    tween:initParams(target, duration, tweenConfig)
    return tween
  end
})

