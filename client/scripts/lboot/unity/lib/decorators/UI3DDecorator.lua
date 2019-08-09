class('UI3DDecorator')

local m = UI3DDecorator

local RenderTextureFormat = UnityEngine.RenderTextureFormat
local Texture = UnityEngine.Texture
local RenderTexture = UnityEngine.RenderTexture

function m.decorate(o)
  local mt = getmetatable(o)
  local t = m.funcs()
  for k, v in pairs(t) do
    rawset(mt, k, v)
  end
end

function m.funcs()
  local mt = {}

  function mt.setVisible(self, visible)
    self:get_gameObject():setVisible(visible)
  end

  function mt.init(self, model)
    if self:get_uiTexture() == nil then
      local w, h = self:get_width(), self:get_height()

      if QualityUtil.isMemoryTight() then
        if w > 500 then
          logd('UI3DDecorator: limit w=%d h=%d for memory', w, h)
          h = 500 * h / w
          w = 500
        end
      end

      local w1 = w * ui.scaleFactor
      local h1 = h * ui.scaleFactor

      local renderTexture = RenderTexture(w1, h1, 16, RenderTextureFormat.ARGB32)
      renderTexture:set_antiAliasing(2)
      self:set_uiTexture(renderTexture)

      local rawImg = self:get_rawImg()
      local camera = self:get_camera()

      rawImg:set_texture(renderTexture)
      rawImg:set_color(Color(1, 1, 1, 1))
      camera:set_targetTexture(renderTexture)
      camera:set_renderingPath(1)
      camera:set_cullingMask(unity.getCullingMask('3DUI'))

      camera:set_nearClipPlane(1)
      -- camera:set_farClipPlane(1000)
      if not ui.camera then
        camera:set_farClipPlane(1000 * ui.scaleFactor)
      else
        camera:set_farClipPlane(1000)
      end
      camera:set_depth(0)
      camera:set_useOcclusionCulling(false)

      -- disable fog
      -- the cit016 has a global fog color that will affect the rendered image
      -- we need to disable the fog in this camera
      FogDisabler(camera:get_gameObject())
    end
  end
  
  function mt.setCameraPos(self,valueZ)
    local camera = self:get_camera()
    local x = camera.transform:get_localPosition().x
    local y = camera.transform:get_localPosition().y
    camera.transform:set_localPosition(Vector3(x,y,valueZ))
  end

  function mt.addToScene(self, go, onComplete)
    local camera = self:get_camera()
    local oldFov = camera:get_fieldOfView()
    uoc:setAttr(self.gameObject, 'old_fov', oldFov)

    go:setParent(self:get_goScenery())
    local transform = go:get_transform()
    transform:reset()
    local modelPosition = self:get_modelPosition()


    -- if not ui.camera then
      -- if oldFov > 40 then
      --   logd(">>>>>>oldFov:"..inspect(oldFov))
      --   local newFov = oldFov / ui.scaleFactor
      --   camera:set_fieldOfView(newFov)  
      -- end  
      -- modelPosition[3] = modelPosition[3] 
    -- end

    transform:set_localPosition(modelPosition)
    transform:set_localScale(Vector3.static_one * self:get_modelScale())
    transform:set_eulerAngles(self:get_modelRotation())

    local trans=go.transform:GetComponentsInChildren(UnityEngine.Transform,true)
    for _,tran in ipairs(trans) do
      tran.gameObject:setLayer('3DUI')
      --go:setLayer('3DUI')
    end


    if onComplete then
      onComplete()
    end
  end
  
  function mt.setCameraAttr(self)
    local camera = self:get_camera()
    if camera then
      -- camera:set_fieldOfView(60)
      camera:set_farClipPlane(1000)
      camera:set_nearClipPlane(0.3)
    end  
  end

  function mt.exit(self)
    local camera = self:get_camera()

    local oldFov = uoc:getAttr(self.gameObject, 'old_fov')
    if oldFov then
      camera:set_fieldOfView(oldFov)
    end

    if camera then
      camera:set_targetTexture(nil)
    end

    local rawImg = self:get_rawImg()
    if rawImg then
      rawImg:set_texture(nil)
      rawImg:set_color(Color(0, 0, 0, 0))
    end

    local uiTexture = self:get_uiTexture()
    if uiTexture then
      uiTexture:Release()
      uiTexture:set_width(0)
      uiTexture:set_height(0)
      uiTexture:set_depth(0)
      GameObject.Destroy(uiTexture)
      self:set_uiTexture(nil)
    end
  end

  return mt

end

setmetatable(m, {__call = function(t, ...) m.decorate(...) end })

class('FogDisabler', function(self, go)
  go:bindLua(self)
  self:init()
end)

local RenderSettings = UnityEngine.RenderSettings
local LuaCameraBehaviour = LBoot.LuaCameraBehaviour

local m = FogDisabler

function m:init()
  self.fog = RenderSettings.fog
  self.gameObject:addComponent(LuaCameraBehaviour)
end

function m:exit()
  for k, _v in pairs(self) do
    self[k] = nil
  end
end

function m:OnPreRender()
  -- set previous fog parameters here,
  -- to avoid everything affected by fog when closing a UI with animation.
  self.fog = RenderSettings.fog
  RenderSettings.fog = false
end

function m:OnPostRender()
  RenderSettings.fog = self.fog
end

setmetatable(m, {__call = function(t, ...) return m.new(...) end })
