class("TouchButton", function(self, options)
	self.rctrans = options.rctrans
	self.downFunc = options.downFunc
  self.moveFunc = options.moveFunc
	self.upFunc = options.upFunc 
	self:init()
end, TouchTracker)

local m = TouchButton

function m:init()
	self:base_init()
  self:makeRect()
end

function m:makeRect()
	self.rects = {}
	TouchUtil.getRect(self.rects, self.rctrans)
  -- self:dumpRects()
end

function m:dumpRects()
  logd("==dump start====")
  for i,v in pairs(self.rects) do 
    logd("%s:x:%s y:%s w:%s h:%s",  tostring(i), tostring(v.x), tostring(v.y), 
                                    tostring(v.width), tostring(v.height))
  end
  logd("==end dump======")
end

function m:isTouchInside(pos)
  local inside = UIUtil.pointInCtrlRects(self.rects, pos)
  -- logd("[touchbtn] inside:%s pos:%s %s", tostring(inside), tostring(pos.x), tostring(pos.y))
  return inside
end


function m:onTouchBegan(pos)
  if self.downFunc then
  	self.downFunc(pos)
  end
end

function m:onTouchMoved(pos)
	if self.moveFunc then 
    self.moveFunc(pos)
  end
end

function m:onTouchEnded(pos)
	if self.upFunc then
  	self.upFunc(pos)
  end
end

function m:onUpdate()
  self:base_update()
end

function m:start()
  self:stop()
  -- if self.hUpdate then return end
  self.hUpdate = scheduler.scheduleWithUpdate(function(deltaTime)
      self:onUpdate()
  end)
end

function m:stop()
  if self.hUpdate then

    --强制 stop后，必须重新touchBegin,才能touchEnd
    self:base_init()

    scheduler.unschedule(self.hUpdate)
    self.hUpdate = nil
  end
end

function m:exit()
  self:stop()
end




