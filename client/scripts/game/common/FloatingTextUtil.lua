class('FloatingTextUtil')

local m = FloatingTextUtil

--随着每个单位距离摄像机的远近不同，每个单位头顶飘字的大小也不同，本函数用于调整头顶飘字的大小，保证飘字大小不随距离变化
function m.reScaleText(floatingText)
  -- local camGO = cc.camera.camera
  -- local camTransform = camGO:get_transform()
  -- local cameraZOffset = camTransform:get_localPosition()[3]
  -- local tranCam = UIUtil.camera():get_transform()
  -- local tranTxt = floatingText.transform
  -- local zoffset = tranCam:get_position()[3] - tranTxt:get_position()[3]
  -- if zoffset == 0 then return end
  -- local scale = zoffset / cameraZOffset

  local baseScale = floatingText._baseScale or 0.014
  unity.setScale(floatingText.gameObject, baseScale)

  --unity.setScale(floatingText.gameObject, baseScale*scale)

  if not floatingText.entityCtrl then return end
  local pos = floatingText.entityCtrl:getPosition()
  local pos_ = floatingText.transform:get_position()
  floatingText.gameObject.transform:set_position(Vector3(pos[1], pos_[2], pos[3]))
end