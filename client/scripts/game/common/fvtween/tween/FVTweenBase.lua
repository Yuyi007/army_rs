class('FVTweenBase', function(self)
  self:init()
end)

local m = FVTweenBase
local fvtc = FVTController

function m:init()
  loge('[%s] you should define init', self.classname)
end

function m:tick(deltaTime)
  loge('[%s] you should define tick', self.classname)
end

function m:isTweenDone()
  loge('[%s] you should define isTweenDone', self.classname)
end

function m:getDuration()
  loge('[%s] you should define getDuration', self.classname)
end

function m:play()
  self.isDone = false
  fvtc.addTween(self)
end

function m:pause()
  self.isDone = true
end

function m:destroy()
  self.isDone = true
end
