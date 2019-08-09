class('SceneUtil')

local m = SceneUtil
local Camera = unity.Camera

function m.getMainCam()
  local cam = m.findCam('scenery', 'Main Camera')
  if cam then return cam end

  cam = m.findCam('CameraRoot', 'Main Camera')
  if cam then return cam end

  loge("[camera]error no main camera found in the scene:"..debug.traceback())
  return nil
end

function m.findCam(camParentName, camName)
  local camParentGo = GameObject.Find(camParentName)
  if not camParentGo then return nil end

  local camTrans = camParentGo:get_transform():find(camName)
  if not camTrans then return nil end
  return camTrans:GetComponent(Camera)
end

function m.goToMainScene()
  cc:exit()
  ui:goto(MainSceneView.new())
end










