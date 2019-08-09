class('CameraManager', function(self)
  self:init()
end)
local m = CameraManager

function m:init()
  self.camAniPlaying = false
  self.lookAtAniPlaying = false
  self.finish = true
end

function m:setCamera(camera, camPos, lookAtPos,cameraRoot)
  self.camera = camera
  self.cameraRoot = cameraRoot
  -- self.camera.transform = self.camera.transform
  self.camPosOld = camPos
  self.lookAtPosOld = lookAtPos

  
end

function m:playCameraAni(hid, type)
  -- logd("playAni:%s",debug.traceback())
  -- camera.transform:set_position(camPos)
  -- camera.transform:set_eulerAngles(lookAtPos)

  -- logd("[CameraManager] playAni car:%s type:%s", hid, type)
   local pos = self.camera.transform:get_position()
  self.camPosOld = Vector3.new(pos.x, pos.y, pos.z)

  local roa = self.camera.transform:get_eulerAngles()
  self.lookAtPosOld = Vector3.new(roa.x, roa.y, roa.z)
  local config = cfg.heroes[hid]
  local posCam = config[type.."_camera"]
  local posLook = config[type.."_lookat"]
  self.finish = false
  if not posCam and not posLook then
    
    self.finish = true
    return
  end

  if posCam then
    self.camPos = Vector3.new(posCam[1], posCam[2], posCam[3])
  end

  if posLook then
    self.lookAtPos = Vector3.new(posLook[1], posLook[2], posLook[3])

  end
  
  
  
  -- self:updateCameraRoot()
  if self.hSwu then return end

  self.camAniPlaying = true
  self.lookAtAniPlaying = true
 
  self.hSwu = scheduler.scheduleWithUpdate(function(dt)

    self:updateAni(dt)
    end)
end



function m:getCameraLerp(deltatTime)
  local maxTime = 1
  self.camTime = self.camTime or 0
  self.camPosOld = self.camPosOld or Vector3.new(0,0,0)

  local x = self.camPos[1] - self.camPosOld[1]
  local y = self.camPos[2] - self.camPosOld[2]
  local z = self.camPos[3] - self.camPosOld[3]
  local dis = x*x + y*y + z*z

  -- logd("[CameraManager] cam deltatTime:%s,dis:%s", deltatTime, dis)
  if dis <= 0.0001 then
    -- logd("[CameraManager] stop pos")
    self.camPosOld = self.camPos
    self.camTime = 0
    -- logd(">>>>>>>getCameraLerp")
    self.camAniPlaying = false
    return self.camPosOld
  end

  self.camTime = self.camTime + deltatTime

  local percent = self.camTime / maxTime
  
  -- logd("[CameraManager] camTime:%s,percent:%s", self.camTime, percent)

  if percent > 1 then
    percent = 1
  end

  local pos = Vector3.Lerp(self.camPosOld, self.camPos, percent)
  self.camPosOld = Vector3.new(pos.x, pos.y, pos.z)

  return self.camPosOld
end

function m:getLookAtLerp(deltatTime)
  local maxTime = 1
  self.lookAtTime = self.lookAtTime or 0
  self.lookAtPosOld = self.lookAtPosOld or Vector3.new(0,0,0)
  local x = self.lookAtPos[1] - self.lookAtPosOld[1]
  local y = self.lookAtPos[2] - self.lookAtPosOld[2]
  local z = self.lookAtPos[3] - self.lookAtPosOld[3]
  local dis = x*x + y*y + z*z

  -- logd("[CameraManager] lookAt dis:%s", dis)
  if dis <= 0.0001 then
    self.lookAtPosOld = self.lookAtPos
    self.lookAtTime = 0
    -- logd(">>>>>>>getLookAtLerp")
    self.lookAtAniPlaying = false
    return self.lookAtPosOld
  end

  self.lookAtTime = self.lookAtTime + deltatTime

  local percent = self.lookAtTime / maxTime
  if percent > 1 then
    percent = 1
  end

  local pos = Vector3.Lerp(self.lookAtPosOld, self.lookAtPos, percent)
  self.lookAtPosOld = Vector3.new(pos.x, pos.y, pos.z)

  return self.lookAtPosOld
end



function m:updateAni(deltatTime)
  -- logd("[CameraManager] update")
  
  if self.camAniPlaying then
    local pos = self:getCameraLerp(deltatTime)
    -- logd("[CameraManager] update pos:%s",tostring(pos))
    self.camera.transform:set_localPosition(pos)
  end

  if self.lookAtAniPlaying then
    local pos = self:getLookAtLerp(deltatTime)
    -- self.camera.transform:LookAt(pos)
    self.camera.transform:set_eulerAngles(pos)
    -- self.camera.transform:set_localRotation(pos)
  end

  if not self.camAniPlaying and not self.lookAtAniPlaying  then
    -- logd("[CameraManager] stop playing")
    scheduler.unschedule(self.hSwu)
    self.hSwu = nil
    self.finish  = true
  end

end

function m:updateCameraRoot()
    local rootVal = self.cameraRoot.transform:get_localEulerAngles()
    local val = nil
    --logd(">>>>>>rootVal:%s",tostring(rootVal[1]))
    if  rootVal[1]>=335 and rootVal[1]<360  then
      val = 360
    elseif rootVal[1] >= 0 then
      val = 0
    end  
    self.cameraRoot.transform:set_localEulerAngles(Vector3(val,0,0)) 
  end

