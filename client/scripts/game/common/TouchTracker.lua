class('TouchTracker', function(self, options)
  self.options = options or {}
end)

local m = TouchTracker

local TouchPhase_Began = UnityEngine.TouchPhase.Began
local TouchPhase_Moved = UnityEngine.TouchPhase.Moved
local TouchPhase_Canceled = UnityEngine.TouchPhase.Canceled
local TouchPhase_Ended = UnityEngine.TouchPhase.Ended
local Input = UnityEngine.Input
local InputSource = InputSource
local Vector2 = UnityEngine.Vector2
local unity = unity

local joystickOrgPos = Vector2.new(188, 144)

function m:base_init()
  self.isLeftAxisTracking = false
  self.isRightAxisTracking = false
  self.isTracking = false
  self.trackedTouch = nil
  self:setFingerId(nil)
end

function m:setFingerId(fingerId)
  self.fingerId = fingerId
end

function m:jsOrgPos()
  return Vector2(joystickOrgPos)
end

function m:update_joystick_left_axis()

  if not jbt.enableJoystick then
    return
  end

  if not ui:baseViewVisible() or mp:isBusyShown() then
    return
  end

  local lhoz = Input.GetAxis("LeftAxisHorizontal")
  local lver = Input.GetAxis("LeftAxisVertical")

  -- logd('update_joystick_left_axis %s, %s', lhoz, lver)

  if math.abs(lhoz) < 0.05 then lhoz = 0 end
  if math.abs(lver) < 0.05 then lver = 0 end

  if lhoz == 0 and lver == 0 then
    if self.isLeftAxisTracking then
      self:onLeftAxisEnded(self:jsOrgPos())
      self.isLeftAxisTracking = false
    end
  end

  if lhoz ~= 0 or lver ~= 0 then
    local pos = Vector2(lhoz, lver)
    if not self.isLeftAxisTracking then
      logd("<<<< jsOrgPos:%s",inspect(self:jsOrgPos()))
      self:onLeftAxisBegan(self:jsOrgPos())
    else
      self:onLeftAxisMoved(self:jsOrgPos(), pos)
    end
    self.isLeftAxisTracking = true
  end
end

function m:update_joystick_right_axis(deltaTime)

  if not jbt.enableJoystick then
    return
  end

  if not ui:baseViewVisible() or mp:isBusyShown() then
    return
  end

  local lhoz = Input.GetAxis("RightAxisHorizontal")
  local lver = Input.GetAxis("RightAxisVertical")

  -- logd('update_joystick_right_axis %s, %s', lhoz, lver)

  if math.abs(lhoz) < 0.05 then lhoz = 0 end
  if math.abs(lver) < 0.05 then lver = 0 end

  if lhoz == 0 and lver == 0 then
    if self.isRightAxisTracking then
      self:onRightAxisEnded(self:jsOrgPos())
      self.isRightAxisTracking = false
    end
  end

  if lhoz ~= 0 or lver ~= 0 then
    local deltaPos = Vector2(lhoz, lver)
    if not self.isRightAxisTracking then
      self:onRightAxisBegan(self:jsOrgPos())
      self.isRightAxisTracking = true
    end

    if self.isRightAxisTracking then
      self:onRightAxisMoved(self:jsOrgPos(), deltaPos, deltaTime)
      self.isRightAxisTracking = true
    end
  end
end

function m:update_joystick_buttons(deltaTime)

  if not jbt.enableJoystick then
    return
  end

  if not ui:baseViewVisible() or mp:isBusyShown() then
    return
  end

  -- local x = InputSource.getButtonDown("BtnX")
  -- local y = InputSource.getButtonDown("BtnY")
  -- local a = InputSource.getButtonDown("BtnA")
  -- local b = InputSource.getButtonDown("BtnB")
  -- local l1 = InputSource.getButtonDown("BtnL1")
  -- local l2 = InputSource.getButtonDown("BtnL2")
  -- local l3 = InputSource.getButtonDown("BtnR1")
  -- local l4 = InputSource.getButtonDown("BtnR2")
  -- local ps = InputSource.getButtonDown("BtnPause")
  -- local ss = InputSource.getButtonDown("BtnSelect")

  -- logd('update_joystick_buttons, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s',x,y,a,b,l1,l2,l3,l4,ps,ss)

  if self.onJoystickBtn then
    self:onJoystickBtn()
  end
end

function m:base_update()
  unity.beginSample('TouchTracker.base_update')

  if InputSource.getTouchCount() > 0 then

    -- deal with tracking touch began
    self.trackedTouch = nil
    if self.fingerId == nil then
      self.trackedTouch = self:findFirstTrackingTouch()
      if self.trackedTouch then
        self:onTouchBegan(self.trackedTouch:get_position())
        self.isTracking = true
        self:setFingerId(self.trackedTouch:get_fingerId())
      end
    else
      self.trackedTouch = self:findTrackingTouch(self.fingerId)
    end

    -- deal with tracking touch moved and end
    if self.trackedTouch then
      --self.trackedTouch.phase == TouchPhase_Moved and
      if self.isTracking then
        -- logd('before calling '.. self.classname .. ': onTouchMoved x:'..tostring(self.trackedTouch.position.x)..', y:'..tostring(self.trackedTouch.position.y))
        -- logd('before calling '.. self.classname .. ': onTouchMoved x:'..tostring(self.trackedTouch.position.x)..', y:'..tostring(self.trackedTouch.position.y))
        self:onTouchMoved(self.trackedTouch:get_position(), self.trackedTouch:get_deltaPosition())
        self.isTracking = true
      end

      local phase = self.trackedTouch:get_phase()
      if (phase == TouchPhase_Canceled or
         phase == TouchPhase_Ended) and self.isTracking then
        self:onTouchEnded(self.trackedTouch:get_position())
        self.isTracking = false
        self.trackedTouch = nil
        self:setFingerId(nil)
      end

    end
  end


  if game.platform == 'editor' then
    if self:needProcessKeyboard() then
      -- add for keyboard
      local up = Input.GetKey('w')
      local down = Input.GetKey('s')
      local left = Input.GetKey('a')
      local right = Input.GetKey('d')
      self.keyHeldDown = (up or down or left or right)

      local up = Input.GetKeyDown('w')
      local down = Input.GetKeyDown('s')
      local left = Input.GetKeyDown('a')
      local right = Input.GetKeyDown('d')
      local keyChange = false

      if up or down or left or right then
        self.up = self.up or up
        self.down = self.down or down
        self.left = self.left or left
        self.right = self.right or right
        keyChange = true
      end

      up = Input.GetKeyUp('w')
      down = Input.GetKeyUp('s')
      left = Input.GetKeyUp('a')
      right = Input.GetKeyUp('d')

      if up or down or left or right then
        self.up = self.up and not up
        self.down = self.down and not down
        self.left = self.left and not left
        self.right = self.right and not right
        keyChange = true
      end

      if keyChange then
        local centerPoint = Vector2(188, 144)
        if self.touchCenter and self.touchCenter ~= Vector2(0, 0) then
          centerPoint = self.touchCenter
        end
        if self.up or self.down or self.left or self.right then
          if self:isTouchInside(centerPoint) then
            self:setLastPoint(centerPoint)
            self:onTouchBegan(centerPoint)
            self.isTracking = true
          end
        else
          self.isTracking = false
          self:onTouchEnded(centerPoint)
        end
      end

      if (self.up or self.down or self.left or self.right) and self.lastPoint and self.isTracking then
        local centerPoint = Vector2(188, 144)
        if self.touchCenter and self.touchCenter ~= Vector2(0, 0) then
          centerPoint = self.touchCenter
        end
        local cu,cl = 0, 0
        local dis = 70
        if self.up then cu = cu + dis  end
        if self.down then cu = cu - dis end
        if self.left then cl = cl - dis end
        if self.right then cl = cl + dis end
        local deltaPos = Vector2(cl, cu)
        local screenPoint = centerPoint + deltaPos
        self:onTouchMoved(screenPoint, self.lastPoint - self.lastPoint)
        self:setLastPoint(screenPoint)
      end
    end
    if not self.keyHeldDown then

      if Input.GetMouseButtonDown (0) then
        local mouse = Input:get_mousePosition()
        local screenPoint = Vector2(mouse[1], mouse[2])
        self:setLastPoint(screenPoint)
        if self:isTouchInside(screenPoint) and not self:isTouchOutArea(screenPoint) then
          self:onTouchBegan(screenPoint)
          self.isTracking = true
        end
      end

      if Input.GetMouseButton (0) and self.isTracking then
        local mouse = Input:get_mousePosition()
        local screenPoint = Vector2(mouse[1], mouse[2])
        self:setLastPoint(self.lastPoint or screenPoint)
        self:onTouchMoved(screenPoint, screenPoint - self.lastPoint)
        self:setLastPoint(screenPoint)
        self.isTracking = true
      end

      if Input.GetMouseButtonUp (0) and self.isTracking then
        local mouse = Input:get_mousePosition()
        local screenPoint = Vector2(mouse[1], mouse[2])
        self:onTouchEnded(screenPoint)
        self.isTracking = false
        self.trackedTouch = nil
        self:setFingerId(nil)
        self.lastPoint = nil
      end

    end

  end

  unity.endSample()
end

function m:needProcessKeyboard()
  return false
end

function m:setLastPoint(p)
  if p then
    if self.lastPoint then
      self.lastPoint:set(p)
    else
      self.lastPoint = Vector2.new(p)
    end
  end
end

function m:findFirstTrackingTouch()
  local res = nil
  for i = 0, InputSource.getTouchCount() - 1 do
    local firstTouch = InputSource.getTouch(i)
    if firstTouch:get_phase() == TouchPhase_Began and
       self:isTouchInside(firstTouch:get_position()) and
       not self:isTouchOutArea(firstTouch:get_position()) then
      res = firstTouch
      break
    end
  end
  return res
end

function m:findTrackingTouch(fingerId)
  local res = nil
  for i = 0, InputSource.getTouchCount() - 1 do
    local firstTouch = InputSource.getTouch(i)
    if firstTouch:get_fingerId() == fingerId then
      res = firstTouch
      break
    end
  end
  return res
end

function m:forceTouchEnd()
  self:onTouchEnded()
  self.isTracking = false
  self.trackedTouch = nil
  self:setFingerId(nil)
end


function m:isTouchInside(pos)
  logd(self.classname .. ': isTouchInside not implemented!!')
end

function m:isTouchOutArea(pos)
  logd(self.classname .. ': isTouchOutArea not implemented!!')
end

function m:onTouchBegan(pos)
  logd(self.classname .. ': onTouchBegan not implemented!!')
end

function m:onTouchMoved(pos, deltaPos)
  logd(self.classname .. ': onTouchMoved not implemented!!')
end

function m:onTouchEnded(pos)
  logd(self.classname .. ': onTouchEnded not implemented!!')
end

function m:onLeftAxisBegan(pos)
  logd(self.classname .. ': onLeftAxisBegan not implemented!!')
end

function m:onLeftAxisMoved(pos, deltaPos, deltaTime)
  logd(self.classname .. ': onLeftAxisMoved not implemented!!')
end

function m:onLeftAxisEnded(pos)
  logd(self.classname .. ': onLeftAxisEnded not implemented!!')
end

function m:onRightAxisBegan(pos)
  logd(self.classname .. ': onRightAxisBegan not implemented!!')
end

function m:onRightAxisMoved(pos, deltaPos, deltaTime)
  logd(self.classname .. ': onRightAxisMoved not implemented!!')
end

function m:onRightAxisEnded(pos)
  logd(self.classname .. ': onRightAxisEnded not implemented!!')
end
