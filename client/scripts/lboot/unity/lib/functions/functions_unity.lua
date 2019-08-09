


local UnityEngine             = UnityEngine
local PlayerPrefs             = UnityEngine.PlayerPrefs
local GameObject              = UnityEngine.GameObject
local Transform               = UnityEngine.Transform
local EventSystems            = UnityEngine.EventSystems
local RectTransformUtility    = UnityEngine.RectTransformUtility
local LuaBinderBehaviour      = LBoot.LuaBinderBehaviour
local BundleHelper            = LBoot.BundleHelper
local PhysicRender            = LBoot.PhysicRender
local Screen                  = UnityEngine.Screen
local Color                   = UnityEngine.Color
local LayerMask               = UnityEngine.LayerMask
local Sprite                  = UnityEngine.Sprite
local TimeUtil                = LBoot.TimeUtil
local Physics                 = UnityEngine.Physics
local File                    = System.IO.File
local Slua                    = Slua
local Vector2                 = UnityEngine.Vector2
local Vector3                 = UnityEngine.Vector3
local Color                   = UnityEngine.Color
local RangeAdditiveBehaviour  = Game.RangeAdditiveBehaviour


local SluaOut = Slua.out

local assert, type, tonumber, tostring = assert, type, tonumber, tostring
local band, bor, bnot, lshift, rshift = bit.band, bit.bor, bit.bnot, bit.lshift, bit.rshift
local floor, lerpf = math.floor, math.lerpf

local traceLoading = false
local _resolution = nil

function unity.default_ttl(uri)
  return LoadingHelper.default_ttl(uri)
end

class('FunctionsUnityReloader', function (self)
end)

function FunctionsUnityReloader.onClassReloaded(_cls)
  unity.initLayers()
end

function unity.init()
  -- Switch on/off unity struct pooling
  -- if true, structs like Vector3, Color are pooled object by default.
  -- when constructed with Vector3(), it's a pooled object,
  -- when constructed with Vector3.new(), it's a new object.
  unity.useStructPooling = true

  -- Let slua_ext.c pushVector3 etc. reuse pooled objects
  local xt = require 'xt'
  xt.set_use_struct_pooling(unity.useStructPooling and 1 or 0)

  -- Keep jit turned off until luajit bad performance on ARM solved
  if rawget(_G, 'jit') then jit.off() end

  -- Clear slua struct metatable cache, see: slua_ext.c
  for i = 1, 5 do
    local ref = rawget(_G, i)
    if ref then
      -- FIXME old struct metatable is never gc'ed: an acceptable minor leak
      -- do lua_unref in C to fix it
      rawset(_G, i, nil)
    end
  end

  unity.initDecorates()
  unity.decorateCommon()
  unity.initLayers()

  declare('GameObject', UnityEngine.GameObject)
  declare('Transform', UnityEngine.Transform)
  declare('Vector3', UnityEngine.Vector3)
  declare('Vector2', UnityEngine.Vector2)
  declare('Vector4', UnityEngine.Vector4)
  declare('Canvas', UnityEngine.Canvas)
  declare('CanvasGroup', UnityEngine.CanvasGroup)
  declare('UI', UnityEngine.UI)
  declare('RenderMode', UnityEngine.RenderMode)
  declare('RectTransform', UnityEngine.RectTransform)
  declare('CanvasRenderer', UnityEngine.CanvasRenderer)
  declare('Animator', UnityEngine.Animator)
  declare('Application', UnityEngine.Application)
  declare('Color', UnityEngine.Color)
  declare('Rect', UnityEngine.Rect)
  declare('Resources', UnityEngine.Resources)
  declare('Rigidbody', UnityEngine.Rigidbody)
  declare('RigidbodyConstraints', UnityEngine.RigidbodyConstraints)
  declare('Time', UnityEngine.Time)
  declare('Material', UnityEngine.Material)
  declare('Input', UnityEngine.Input)
  declare('Camera', UnityEngine.Camera)
  declare('Quaternion', UnityEngine.Quaternion)
  declare('Gizmos', UnityEngine.Gizmos)
  declare('Mathf', UnityEngine.Mathf)
  declare('Screen', UnityEngine.Screen)
  declare('Matrix4x4', UnityEngine.Matrix4x4)
  declare('BoxCollider', UnityEngine.BoxCollider)
  declare("Image", UnityEngine.UI.Image)
  declare("Shader", UnityEngine.Shader)
  declare('Destroy', UnityEngine.Object.Destroy)
  declare('LuaBinderBehaviour', LBoot.LuaBinderBehaviour)
  declare('FileUtils', LBoot.FileUtils)
  declare('TimeUtil', LBoot.TimeUtil)

  scheduler.init()

  -- if rawget(_G, 'game') then
  --   if game.mode == 'development' then
  --     LBoot.LogUtil.level = 1
  --   else
  --     LBoot.LogUtil.level = 2
  --   end

  --   if game.platform == 'ios' and game.usage ~= 'review' then
  --     LBoot.LogUtil.level = 1
  --   end
  -- end

  local SystemInfo = UnityEngine.SystemInfo
  local deviceModel = SystemInfo.deviceModel

end

local layers = {}

function unity.initLayers()
  -- Normally you shoundn't change the actual layer name here to be different from the TagManager
  -- but only the ones that none is actually using
  layers = {
    Default                 = 0,
    IgnoreRaycasts          = 2,
    UI                      = 5,
    ["Background Image"]    = 8,
    Obstacles               = 9,
    Ground                  = 10,
    Player                  = 11,
    Entities                = 12,
    ["3DUI"]                = 13,
    ParticleEffect          = 14,
    LodObstacle             = 15, 
    LodObstacle120          = 16,
    Sences                  = 17,
    Indicators              = 18,
    T4mObjs                 = 30,
  }
end

function unity.sceneLayers()
  return 'Default', 'LodObstacle', 'Obstacles', 'LodObstacle120'
end


function unity.resetTransform(go)
  local transform = go.transform
  transform:set_localPosition(Vector3.static_zero)
  transform:set_localRotation(Quaternion.static_identity)
  transform:set_localScale(Vector3.static_one)
end

function unity.resetRectTransform(rectTransform)
  local one = Vector2.static_one
  local zero = Vector2.static_zero
  rectTransform:set_anchorMax(one)
  rectTransform:set_anchorMin(zero)
  rectTransform:set_offsetMin(zero)
  rectTransform:set_offsetMax(zero)
  rectTransform:set_pivot(Vector2(0.5, 0.5))
  rectTransform:set_localScale(Vector3.static_one)
  rectTransform:set_sizeDelta(zero)
  rectTransform:set_anchoredPosition(zero)
end

-- avoid using this in loops, use setTransformIdentity whenever possible
function unity.setIdentity(go1, go2)
  local transform1 = go1.transform
  local transform2 = go2.transform
  transform1:set_position(transform2:get_position())
  transform1:set_localPosition(transform2:get_localPosition())
  transform1:set_localRotation(transform2:get_localRotation())
  transform1:set_localScale(transform2:get_localScale())
end

-- avoid using this in loops, use setTransformIdentity whenever possible
function unity.setIdentity2(go1, go2)
  local transform1 = go1.transform
  local transform2 = go2.transform
  transform1:set_position(transform2:get_position())
  transform1:set_rotation(transform2:get_rotation())
end

function unity.setTransformIdentity(t1, t2)
  t1:set_position(t2:get_position())
  t1:set_localRotation(t2:get_localRotation())
  t1:set_localScale(t2:get_localScale())
end

function unity.setTransformIdentity2(t1, t2)
  t1:set_position(t2:get_position())
  t1:set_rotation(t2:get_rotation())
end

function unity.resetParticleSystem(effect)
  local effTransform = effect:get_transform()
  effTransform:set_localPosition(Vector3.static_zero)
  effTransform:set_localRotation(Vector3.static_zero)
  effTransform:set_localScale(Vector3.static_one)
end

function unity.setIdentityParticleSystem(effect, go)
  local fvpr = effect:GetComponent(LBoot.FVParticleRoot)
  if not fvpr then
    return
  end

  local effTransform = effect:get_transform()
  local goTransform = go:get_transform()

  effTransform:set_position(goTransform:get_position())
  effTransform:set_localPosition(goTransform:get_localPosition())
  fvpr:set_Rotation(Vector3.static_zero)
  fvpr:setFVScale(goTransform:get_localScale())
end

function unity.cloneBone(bone)
  local go = GameObject()
  local boneTransform = bone:get_transform()
  unity.setIdentity(go, boneTransform)
  for t in boneTransform:iter() do
    local sgo = t.gameObject
    local dgo = unity.cloneBone(sgo)
    unity.setParent(dgo, go, false)
  end
  return go
end

function unity.moveInDir(go, distance, dir)
  local transform = go:get_transform()
  transform:set_localPosition(transform:get_localPosition() + dir * distance)
end

function unity.moveUp(go, distance)
  unity.moveInDir(go, distance, Vector3.static_up)
end

function unity.moveDown(go, distance)
  unity.moveInDir(go, distance, Vector3.static_down)
end

function unity.moveLeft(go, distance)
  unity.moveInDir(go, distance, Vector3.static_left)
end

function unity.moveRight(go, distance)
  unity.moveInDir(go, distance, Vector3.static_right)
end

function unity.moveForward(go, distance)
  unity.moveInDir(go, distance, Vector3.static_forward)
end

function unity.moveBack(go, distance)
  unity.moveInDir(go, distance, Vector3.static_back)
end

function unity.setParent(go, parent, worldPosStays)
  if worldPosStays == nil then
    worldPosStays = false
  end

  if is_null(go) then return end

  local transform = go.transform
  if is_null(transform) then return end

  transform:setParent(parent, worldPosStays)
end

function unity.destroy(go, recyleOpts)
  -- logd("unity.destroy go=%s trace=%s", tostring(go), debug.traceback())
  unity.clearEventTrigger(go)

  if gp.shouldRecycle and gp:shouldRecycle(go) then
    gp:recycle(go, recyleOpts)
  else
    if go then
      go:destroy()
    end
  end
end

function unity.forceExit(binder)
  local view = binder:get_Lua()
  if view and ViewFactory.objPools[view] then
    if ViewFactory.debug then
      logd('forceExit view in pool view=%s binder=%s', tostring(view), tostring(binder))
    end
  else
    -- logd('forceExit binder=%s view=%s %s %s', tostring(binder),
    --   tostring((view and view.class) and view.class.classname or ''),
    --   tostring(view), debug.traceback())
    return binder:ForceExit()
  end
end

function unity.setScale(go, scale)
  local transform = go.transform
  if type(scale) == 'number' then
    transform:set_localScale(Vector3(scale, scale, scale))
  else
    transform:set_localScale(scale)
  end
end

function unity.isPointerOverUI()
  local isOverUI = false
  local touches = InputSource.getTouches()

  for i = 1, #touches do
    local touch = touches[i]
    if EventSystems.EventSystem.current:IsPointerOverGameObject(touch:get_fingerId()) then
      isOverUI = true
      break
    end
  end

  isOverUI = isOverUI or EventSystems.EventSystem.current:IsPointerOverGameObject()
  isOverUI = isOverUI or EventSystems.EventSystem.current.currentSelectedGameObject ~= nil

  return isOverUI
end


function unity.removeAllChildren(go, exclude)
  exclude = exclude or {}
  local listToDestroy = {}

  for v in go:iter() do
    local gi = v:get_gameObject()
    if not table.contains(exclude, gi) then
      listToDestroy[#listToDestroy + 1] = gi
    end
  end

  for _, gi in ipairs(listToDestroy) do
    gi:setParent(nil)
    gi:destroy()
  end

  table.clear(listToDestroy)
end

function unity.getString(key)
  return PlayerPrefs.GetString(key)
end

function unity.setString(key, str)
  PlayerPrefs.SetString(key, tostring(str))
end

function unity.getInt(key)
  return PlayerPrefs.GetInt(key)
end

function unity.setInt(key, number)
  PlayerPrefs.SetInt(key, tonumber(number))
end

function unity.getBool(key)
  return unity.getString(key) == 'true'
end

function unity.setBool(key, value)
  unity.setString(key, tostring(value))
end

function unity.createTweenChain(config)
  config = config or GoTweenCollectionConfig()
  local chain = GoTweenChain(config)
  chain:set_autoRemoveOnComplete(true)
  return chain
end

function unity.createFVTweenChain()
  return FVTweenChain()
end

local function sheetBundlePath(uri)
  return cfg:spriteAssetBundlePath(uri)
end

local function spriteMatBundlePath(uri)
  return cfg:spriteMatBundlePath(uri)
end


function unity.getFps()
  return Time.timeScale / Time.smoothDeltaTime
end

------------------- quality settings

function unity.setResolution(ratio)
  -- editor set resolution will not take effect so disable it
  if game.platform == 'editor' then return end

  _resolution = nil

  ratio = ratio or game.resolution or 1
  ratio = tonumber(ratio)
  local fullSize = game.fullSize

  -- ios always keep 1
  if game.ios() then
    ratio = 1
  end

  -- if game.ios() and unity.Debug.isDebugBuild then
  --   if game.systemInfo.graphicsDeviceVersion == 'Metal' then
  --     ratio = 1
  --     disableResolutionChange = true
  --   end
  -- end

  logwarn('unity.setResolution ratio=%f fullSize=%s, %s', ratio,
    tostring(fullSize.width), tostring(fullSize.height))

  -- scheduler.performWithDelay(0, function()
    -- if unity.resolution == ratio then
    --   if rawget(_G, 'ui') then
    --     ui:setResolution(ratio)
    --   end
    --   return
    -- end


    local w = math.round(fullSize.width * ratio)
    local h = math.round(fullSize.height * ratio)

    if w % 2 == 1 then
      w = w - 1
    end

    if h % 2 == 1 then
      h = h - 1
    end


    local displays = unity.Display.displays.Table
    local display = displays[1]
    logd("[res] w:%s, h:%s", tostring(w), tostring(h))
    display:SetRenderingResolution(w, h)

    unity.resolution = ratio

    logd('setResolution success w=%s h=%s', w, h)
  -- end)
end

function unity.setTextureVariant(variant)
  -- logd('setTextureVariant %s %s', tostring(variant), debug.traceback())
  if variant then
    BundleHelper.SetBundleVariants(Slua.MakeArray(String, {'texture', variant}))
  end
end

--lmt
--0:full size
--1:1/2 size
--2:1/4 size
--3:1/8 size
function unity.setTextureLmt(lmt)
  UnityEngine.QualitySettings.masterTextureLimit = lmt
end

--mode
--0, 2, 4, 8
function unity.setAAMode(mode)
  if game.platform ~= 'ios' then
    UnityEngine.QualitySettings.antiAliasing = mode
  end
end

--count : 0~4
function unity.setPixelLightCount(count)
  UnityEngine.QualitySettings.pixelLightCount = count
end

--count : 0, 1, 2
function unity.setVsync(count)
  UnityEngine.QualitySettings.vSyncCount = count
end

--mode
--0:disable
--1:enable
--2:force enable
function unity.setAnisotropicFiltering(mode)
  UnityEngine.QualitySettings.anisotropicFiltering = mode
end

function unity.getResolution()
  if not _resolution then
    _resolution = UnityEngine.Screen.currentResolution
  end
  return _resolution
end

--lmt
--0:full size
--1:1/2 size
--2:1/4 size
--3:1/8 size
function unity.getTextureLmt()
  return UnityEngine.QualitySettings.masterTextureLimit
end

--mode
--0, 2, 4, 8
function unity.getAAMode()
  return UnityEngine.QualitySettings.antiAliasing
end

--count : 0~4
function unity.getPixelLightCount()
  return UnityEngine.QualitySettings.pixelLightCount
end

--count : 0, 1, 2
function unity.getVsync()
  return UnityEngine.QualitySettings.vSyncCount
end

--mode
--0:disable
--1:enable
--2:force enable
function unity.getAnisotropicFiltering()
  return UnityEngine.QualitySettings.anisotropicFiltering
end

-- shadow, 0 - off, 1 - on
function unity.setCastShadow(castShadow)
  unity.castShadow = castShadow or 0
  if unity.castShadow == 1 then
    UnityEngine.QualitySettings.shadows = 2
    UnityEngine.QualitySettings.shadowDistance = 20
  else
    UnityEngine.QualitySettings.shadows = 0
    UnityEngine.QualitySettings.shadowDistance = 0
  end

  UnityEngine.QualitySettings.shadowResolution = 0
  UnityEngine.QualitySettings.shadowProjection = 0
end

function unity.setTargetFrameRate(rate)
  UnityEngine.Application.targetFrameRate = rate
  game.frameTime = 1000.0 / rate
end

-------------------------------------

-- callback(PointerEventData)

function unity.setLayer(go, layer, recurisve)
  if not_null(go) then
    go:setLayer(layer, recurisve)
  end
end

function unity.setLayerOpt(go, layer, recurisve)
  if is_null(go) then return end

  if recurisve then
    -- setLayer recursively is slow
    -- pooled object probably have this set
    if go:get_layer() ~= layer then
      go:setLayer(layer, recurisve)
    end
  else
    go:setLayer(layer, recurisve)
  end
end

function unity.setSkinnedMeshRendererLayers(go, layer)
  if not_null(go) then
    go:setSkinnedMeshRendererLayers(layer)
  end
end

function unity.clearEventTrigger(go)
  if is_null(go) then return end
  local trigger = go:GetComponent(EventSystems.EventTrigger)
  if trigger then trigger.triggers:Clear() end
end

function unity.insideRectTransform(rectTransform, screenPoint, camera)
  return RectTransformUtility.RectangleContainsScreenPoint(rectTransform, screenPoint, camera)
end

function unity.newHexToColor(hex)
  local color = unity.hexToColor(hex)
  return Color.new(color)
end

function unity.newHexToColorWithAlpha(hex)
  local color = unity.hexToColorWithAlpha(hex)
  return Color.new(color)
end

local hexColorCache = setmetatable({}, {__mode='k'})

function unity.hextToColorCached(hex)
  local item = hexColorCache[hex]
  if not item then
    item = m.hexToColor(hex)
    hexColorCache[hex] = item
  end
  return item
end

function unity.hexToColor(hex)
  if unity.debug then
    assert(type(hex) == 'string' or type(hex) == 'number')
  end

  if type(hex) == 'string' then
    hex = string.gsub(hex, "#", "")
    if not hex:match('^0x') then hex = '0x'..hex end
  end

  local value = tonumber(hex)
  local r = band(rshift(value, 16), 255)
  local g = band(rshift(value, 8), 255)
  local b = band(value, 255)

  return Color(r / 255, g / 255, b / 255, 1)
end

function unity.hexToColorWithAlpha(hex)
  if unity.debug then
    assert(type(hex) == 'string' or type(hex) == 'number')
  end

  if type(hex) == 'string' then
    if not hex:match('^0x') then hex = '0x'..hex end
  end

  local value = tonumber(hex)
  local r = band(rshift(value, 24), 255)
  local g = band(rshift(value, 16), 255)
  local b = band(rshift(value, 8), 255)
  local a = band(value, 255)

  return Color(r / 255, g / 255, b / 255, a / 255)
end

function unity.layer(name)
  if layers[name] then return layers[name] end
  return LayerMask.NameToLayer(name)
end

function unity.layerBit(layerName)
  return lshift(1, unity.layer(layerName))
end

-- Make table allocations and is slow, DO NOT use in loops.
function unity.getCullingMask(...)
  return reduce(function(b, name) return bor(b, unity.layerBit(name)) end, 0, {...})
end

function unity.getNegateCullingMask(...)
  local b = unity.getCullingMask(...)
  return bnot(b)
end

function unity.as(t1, t2)
  if type(t1) == 'userdata' then
    if Slua.IsNull(t1) then return nil end
    return Slua.As(t1, t2)
  else
    return t1
  end
end

function unity.osTime()
  return os.time()
end

function unity.preciseTime()
  return socket.gettime()
end


function unity.duplicateCamera(camera)
  local newCamera = GameObject()
  newCamera:addComponent(UnityEngine.Camera)
  newCamera:addComponent(UnityEngine.GUILayer)
  newCamera:addComponent(UnityEngine.AudioListener)
  unity.identityCamera(newCamera, camera)
  return newCamera
end

function unity.identityCamera(outCamera, camera)
  local outTrans = outCamera:get_transform()
  local trans = camera:get_transform()

  outTrans:set_position(trans:get_position())
  outTrans:set_rotation(trans:get_rotation())

  local outComp = outCamera:GetComponent(UnityEngine.Camera)
  local comp = camera:GetComponent(UnityEngine.Camera)

  local mask = comp:get_cullingMask()
  if outComp:get_cullingMask() ~= mask and mask ~= 0 then
    outComp:set_cullingMask(mask)

  end

  -- outComp:set_depth(comp:get_depth())

  outComp:set_backgroundColor(comp:get_backgroundColor())
  outComp:set_eventMask(comp:get_eventMask())
  outComp:set_fieldOfView(comp:get_fieldOfView())
  outComp:set_farClipPlane(comp:get_farClipPlane())
  outComp:set_nearClipPlane(comp:get_nearClipPlane())
end

function unity.lerpCamera(res, c1, c2, t)
  res.transform:set_position(c1.transform:get_position():lerp(c2.transform:get_position(), t))
  res.transform:set_rotation(c1.transform:get_rotation():lerp(c2.transform:get_rotation(), t))

  local resComp = res:GetComponent(UnityEngine.Camera)
  local c1Comp = c1:GetComponent(UnityEngine.Camera)
  local c2Comp = c2:GetComponent(UnityEngine.Camera)

  resComp:set_fieldOfView(lerpf(c1Comp:get_fieldOfView(), c2Comp:get_fieldOfView(), t))
  resComp:set_farClipPlane(lerpf(c1Comp:get_farClipPlane(), c2Comp:get_farClipPlane(), t))
  resComp:set_nearClipPlane(lerpf(c1Comp:get_nearClipPlane(), c2Comp:get_nearClipPlane(), t))
end

function unity.isCameraDoneTracked(srcCam, dstCam)
  local res = true
  res = res and (srcCam.transform:get_position():dist2(dstCam.transform:get_position()) < 0.25)
  res = res and (srcCam.transform:get_rotation():get_eulerAngles():dist2(dstCam.transform:get_rotation():get_eulerAngles()) < 0.25)
  return res
end

-- Find or create the game object at path
-- Create the game object at path along with its pathed gos if any doesnt exist
function unity.findCreateGameObject(path)
  local go = GameObject.Find(path)
  if go then return go end

  local list = path:split('/')
  local gos  = {}
  local p    = ''

  for i = 1, #list do
    local name = list[i]
    local parent = nil

    if i > 1 then
      parent = gos[i - 1]
    end

    p = p .. '/'.. list[i]
    go = GameObject.Find(p)
    if not go then
      go = GameObject(name)
      local transform = go:get_transform()
      if parent then
        transform:SetParent(parent, false)
      else
        transform:SetParent(nil, false)
      end
    end

    table.insert(gos, go)
  end

  return table.last(gos)
end

-- FIXME tempHits num may needs to be increased
local tempHits = {}
for i = 1, 3 do tempHits[i] = UnityEngine.RaycastHit() end
tempHits = Slua.MakeArray(UnityEngine.RaycastHit, tempHits)

function unity.raycastFirst(origin, direction, maxDist, layerMask)
  -- This will have GC Alloc
  local ok, hit = Physics.Raycast(origin, direction, SluaOut, maxDist, layerMask)
  return ok, hit

  --[[
  local hitNum = Physics.RaycastNonAlloc(origin, direction, tempHits, maxDist, layerMask)
  if hitNum > 0 then
    local minDist = maxDist
    local minDistHit = nil
    for i = 1, #tempHits do
      local hit = tempHits[i]
      local dist = hit:get_distance()
      if dist < minDist then
        minDist = dist
        minDistHit = hit
      end
    end
    return true, minDistHit
  else
    return false, nil
  end
  ]]
end

-- FIXME tempColliders num may needs to be increased
local tempColliders = {}
for i = 1, 30 do tempColliders[i] = UnityEngine.Collider() end
tempColliders = Slua.MakeArray(UnityEngine.Collider, tempColliders)

function unity.overlapSphere(position, radius, layerMask)
  -- This will have GC Alloc
  local colliders = Physics.OverlapSphere(position, radius, layerMask)
  return colliders, #colliders

  --[[
  local count = Physics.OverlapSphereNonAlloc(position, radius, tempColliders, layerMask)
  logd('tempColliders=%d count=%d', #tempColliders, count)
  return tempColliders, count
  ]]
end

function unity.overlapBox(position, halfExtents, orientation, layerMask)
  -- This will have GC Alloc
  orientation = orientation or Quaternion.static_identity
  local colliders = Physics.OverlapBox(position, halfExtents, orientation, layerMask)
  return colliders, #colliders

  --[[
  local count = Physics.OverlapSphereNonAlloc(position, radius, tempColliders, layerMask)
  logd('tempColliders=%d count=%d', #tempColliders, count)
  return tempColliders, count
  ]]
end

local assetsBundleConfig = nil
local bundleConfig = {
}

local function getBundleConfig(category)
  if not bundleConfig[category] then
    local name = 'bundles_ios'
    if game.editor() then
      name = 'bundles_osx'
    else
      name = 'bundles_'..game.platform
    end

    local dbname = name .. '.' ..category..'.db'
    local proxy = SqliteConfigFileProxy.new(dbname)

    bundleConfig[category] = proxy
  end
  return bundleConfig[category]
end

local function prefabBundlePath(uri)
  uri = uri:lower()
  local cfg = rawget(_G, 'cfg')
  if cfg and cfg.prefabBundlePath then
    return cfg:prefabBundlePath(uri)
  else
    local bc = getBundleConfig('prefabs')
    local path = string.format('assets/%s.prefab', uri)
    return bc[path]
  end
end

local function sceneBundlePath(uri)
  uri = uri:lower()
  local cfg = rawget(_G, 'cfg')
  if cfg and cfg.sceneBundlePath then
    return cfg:sceneBundlePath(uri)
  else
    local bc = getBundleConfig('scenes')
    local path = string.format('assets/%s.unity', uri)
    return bc[path]
  end
end


local function prefabAssetPath(uri)
  uri = uri:lower()
  return string.format('assets/%s.prefab', uri)
end

local function textureAssetPath(uri)
  uri = uri:lower()
  return string.format('assets/%s.tga', uri)
end

function unity.getAllDependencies(uri)
  local depends = BundleHelper.GetAllDependencies(uri)
  return depends
end

function unity.loadBundle(uri, ttl)
  if not unity.bundleExists(uri) then
    loge('unity.loadBundle: %s not found', uri)
    return nil
  end

  ttl = ttl or unity.default_ttl(uri)

  if traceLoading then
    logd('traceLoading: loadBundle uri=%s ttl=%d', uri, ttl)
  end

  return BundleHelper.Load(uri, ttl)
end

function unity.loadBundleWithDependencies(uri, ttl)
  if not unity.bundleExists(uri) then
    loge('unity.loadBundleWithDependencies: %s not found %s', tostring(uri), debug.traceback())
    return nil
  end

  ttl = ttl or unity.default_ttl(uri)

  if traceLoading then
    logd('traceLoading: loadBundleWithDependencies uri=%s ttl=%d', uri, ttl)
  end

  return BundleHelper.LoadWithDependencies(uri, ttl)
end


function unity.loadBundleAsync(uri, onComplete, ttl)
  if not unity.bundleExists(uri) then
    loge('unity.loadBundleAsync: %s not found', uri)
    return onComplete()
  end

  ttl = ttl or unity.default_ttl(uri)

  if traceLoading then
    logd('traceLoading: loadBundleAsync uri=%s ttl=%d', uri, ttl)
  end

  -- 因为forceUnload导致回调中bundle是nil，所以如果是nil就下一帧再load一次
  local _onComplete = function(bundle)
    if is_null(bundle) then
      logd('loadBundleAsync reload cuz bundle is nil %s', tostring(uri))
      scheduler.performWithDelay(0, function()
        unity.loadBundleAsync(uri, onComplete, ttl)
      end)
    else
      onComplete(bundle)
    end
  end

  return BundleHelper.LoadAsync(uri, ttl, _onComplete)
end


function unity.loadBundleWithDependenciesAsync(uri, onComplete, ttl)
  if not unity.bundleExists(uri) then
    loge('unity.loadBundleWithDependenciesAsync: %s not found %s', tostring(uri), debug.traceback())
    return
  end

  ttl = ttl or unity.default_ttl(uri)

  if traceLoading then
    logd('traceLoading: loadBundleWithDependenciesAsync uri=%s ttl=%d', uri, ttl)
  end

  -- 因为forceUnload导致回调中bundle是nil，所以如果是nil就下一帧再load一次
  local _onComplete = function(bundle)
    if is_null(bundle) then
      logd('loadBundleWithDependenciesAsync reload cuz bundle is nil %s', uri)
      scheduler.performWithDelay(0, function()
        unity.loadBundleWithDependenciesAsync(uri, onComplete, ttl)
      end)
    else
      local now = Time.get_realtimeSinceStartup()
      local startTime = unity.startUps[uri]
      local span = now - startTime
      if traceLoading then
        logd(">>>>>>>bundle span:"..inspect(span).." uri:"..uri)
      end
      onComplete(bundle)
    end
  end
  unity.startUps = unity.startUps or {}
  unity.startUps[uri] = Time.get_realtimeSinceStartup()
  return BundleHelper.LoadWithDependenciesAsync(uri, ttl, _onComplete)
end


local LoadSceneMode = unity.SceneManagement.LoadSceneMode
local SceneManager = unity.SceneManagement.SceneManager

-- not used for now
--[[
function unity.loadLevel(uri, ttl)
  uri = uri:lower()
  ttl = ttl or unity.default_ttl(uri)

  if traceLoading then
    logd('traceLoading: loadLevel uri=%s ttl=%d', uri, ttl)
  end

  if game.editor() then
    return BundleHelper.LoadLevel(uri, ttl)
  end

  local bundlePath = sceneBundlePath(uri)
  unity.loadBundleWithDependencies(bundlePath, ttl)
  SceneManager.LoadScene(table.last(string.split(uri, '/')), LoadSceneMode.Single)
end
]]

function unity.loadAssetInEditor(uri, t, ttl)
  ttl = ttl or unity.default_ttl(uri)
  return BundleHelper.LoadAssetInEditor(uri, ttl, t)
end


function unity.loadLevelAsync(uri, onComplete, onProgress, ttl)
  unity.recordTime('unity.loadLevelAsync %s', uri)

  uri = uri:lower()
  ttl = ttl or unity.default_ttl(uri)

  if unity.isLoadingLevel then
    loge('loadLevelAsync: already loading! %s', debug.traceback())
    return
  end

  unity.isLoadingLevel = true

  if traceLoading then
    logd('traceLoading: loadLevelAsync uri=%s ttl=%d', uri, ttl)
  end

  local bundlePath = sceneBundlePath(uri)
  local startTime = engine.realtime()

  local function _onStart()
    TransformCollection.protectAll()
  end

  local function _onComplete()
    unity.releaseAsyncLock(uri)
    TransformCollection.unprotectAll()
    unity.recordTime('unity.loadLevelAsync done %s', uri)
    unity.recordTime('unity.loadLevelAsync done %s', uri, engine.realtime() - startTime)
    onComplete()
  end

  local function _onProgress(t, p)
    -- logd('loadlevelAsync %s progress=%s', uri, p)
    if onProgress then onProgress(t, p) end
  end

  local function _loadLevelAsync()
    coroutineStart(function()
      unity.recordTime('unity.loadLevelAsync start (bundle loaded) %s', uri)

      _onStart()
      local acquireStart = Time:get_time()
      while not unity.acquireAsyncLock(uri) do
        coroutine.yield()
        if Time:get_time() - acquireStart > 6.0 then
          loge('loadLevelAsync: uri=%s lock timeout', uri)
          break
        end
      end

      local req = SceneManager.LoadSceneAsync(table.last(string.split(uri, '/')), LoadSceneMode.Single)
      while not req:get_isDone() do
        _onProgress(3, req:get_progress())
        coroutine.yield()
      end
      _onComplete()

      unity.isLoadingLevel = nil
    end, 0, {global = true})
  end

  if game.editor() then
    return _loadLevelAsync()
  end

  unity.loadBundleWithDependenciesAsync(bundlePath, function(bundle)
    _loadLevelAsync()
  end, ttl)
end

--[[
function unity.loadLevelAdditiveAsync(uri, onComplete, onProgress, ttl)
  uri = uri:lower()
  ttl = ttl or unity.default_ttl(uri)

  if traceLoading then
    logd('traceLoading: loadLevelAdditiveAsync uri=%s ttl=%d', uri, ttl)
  end

  if game.editor() then
    return BundleHelper.LoadLevelAdditiveAsync(uri, ttl, onComplete, onProgress)
  end

  local bundlePath = sceneBundlePath(uri)
  unity.loadBundleWithDependenciesAsync(bundlePath, function(bundle)
    local req = SceneManager.LoadSceneAsync(table.last(string.split(uri, '/')), LoadSceneMode.Additive)
    coroutineStart(function()
      while not req:get_isDone() do
        if onProgress then onProgress(3, req:get_progress()) end
        coroutine.yield()
      end
      onComplete()
    end)
  end, ttl)
end
]]

local Yield = UnityEngine.Yield

function unity.loadAssetAsync(assetPath, bundlePath, onComplete, ttl)
  assetPath = assetPath:lower()
  ttl = ttl or unity.default_ttl(bundlePath)

  if traceLoading then
    logd('traceLoading: loadAssetAsync bundle=%s asset=%s ttl=%d', tostring(bundlePath), tostring(assetPath), ttl)
  end

  if game.shouldLoadAssetInEditor() then
    local asset = unity.loadAssetInEditor(assetPath, UnityEngine.Object)
    onComplete(asset)
  else
    if not bundlePath then
      loge('bundlePath for %s is nil %s', assetPath, debug.traceback())
      return
    end

    local loader = unity.getAssetLoader(bundlePath, ttl)
    loader:loadAsync(assetPath, onComplete)
  end
end

function unity.loadAsset(assetPath, bundlePath, ttl, bundle)
  ttl = ttl or unity.default_ttl(bundlePath)
  assetPath = assetPath:lower()

  if traceLoading then
    logd('traceLoading: loadAsset bundle=%s asset=%s ttl=%d', tostring(bundlePath), tostring(assetPath), ttl)
  end

  if game.shouldLoadAssetInEditor() then
    local asset = unity.loadAssetInEditor(assetPath, UnityEngine.Object)
    return asset
  else
    if not bundlePath then
      -- loge('bundlePath for %s is nil', assetPath)
      return nil
    end

    if bundle then
      return bundle:LoadAsset(assetPath)
    else
      local loader = unity.getAssetLoader(bundlePath, ttl)
      return loader:load(assetPath)
    end
  end
end

function unity.getAssetLoader(bundlePath, ttl)
  unity.assetLoaders = unity.assetLoaders or {}
  local loader = unity.assetLoaders[bundlePath]

  if not loader then
    loader = AssetBundleAssetLoader.new(bundlePath, ttl)
    unity.assetLoaders[bundlePath] = loader
  end

  return loader
end


function unity.loadSound(uri, ttl)
  local assetPath = string.format('assets/%s.mp3', uri)
  local bundlePath = cfg:soundBundlePath(uri)
  return unity.loadAsset(assetPath, bundlePath, ttl)
end

function unity.loadSoundAsync(uri, onComplete, ttl)
  local assetPath = string.format('assets/%s.mp3', uri)
  local bundlePath = cfg:soundBundlePath(uri)

  if traceLoading then
    logd('traceLoading: loadSoundAsync uri=%s ttl=%s', uri, tostring(ttl))
  end

  return unity.loadAssetAsync(assetPath, bundlePath, onComplete, ttl)
end

function unity.loadPrefab(uri, ttl)
  local assetPath = prefabAssetPath(uri)
  local bundlePath = prefabBundlePath(uri)

  if traceLoading then
    logd('traceLoading: loadPrefab bundle=%s asset=%s ttl=%s', bundlePath, assetPath, tostring(ttl))
  end

  return unity.loadAsset(assetPath, bundlePath, ttl)
end

function unity.loadPrefabAsync(uri, onComplete, ttl)
  local assetPath = prefabAssetPath(uri)
  local bundlePath = prefabBundlePath(uri)

  if traceLoading then
    logd('traceLoading: loadPrefabAsync uri=%s ttl=%s', uri, tostring(ttl))
  end

  return unity.loadAssetAsync(assetPath, bundlePath, onComplete, ttl)
end

function unity.loadTexture2D(uri, ttl)
  local assetPath = textureAssetPath(uri)
  local bundlePath = cfg:texture2DBundlePath(uri)

  return unity.loadAsset(assetPath, bundlePath, ttl)
end

function unity.loadTexture2DAsync(uri, onComplete, ttl)
  local assetPath = textureAssetPath(uri)
  local bundlePath = cfg:texture2DBundlePath(uri)
  return unity.loadAssetAsync(assetPath, bundlePath, onComplete, ttl)
end

function unity.loadSpriteAsset(sheetPath)
  local assetPath = string.format('assets/%s.asset', sheetPath)
  local bundlePath = sheetBundlePath(sheetPath)
  if traceLoading then
    logd('traceLoading: loadSpriteAsset bundle=%s asset=%s', bundlePath, assetPath)
  end
  return unity.loadAsset(assetPath, bundlePath, -1)
end

function unity.loadSpriteMat(sheetPath)
  sheetPath = sheetPath:gsub('images/', 'images_mask/')
  -- loge('sheetPath = %s', sheetPath)
  local assetPath = string.format('assets/%s.mat', sheetPath)
  local bundlePath = spriteMatBundlePath(sheetPath)
  -- if not bundlePath then
  --   loge('bundlePath = ')
  --   return nil
  -- end
  -- loge('bundlePath = %s', tostring(bundlePath))
  if traceLoading then
    logd('traceLoading: loadSpriteMat bundle=%s asset=%s', bundlePath, assetPath)
  end

  return unity.loadAsset(assetPath, bundlePath, -1)
end

function unity.loadSpriteMatAsync(sheetPath, onComplete)
  sheetPath = sheetPath:gsub('images', 'images_mask')
  local assetPath = string.format('assets/%s.mat', sheetPath)
  local bundlePath = spriteMatBundlePath(sheetPath)

  if traceLoading then
    logd('loadSpriteMatAsync: bundle=%s asset=%s', bundlePath, assetPath)
  end
  return unity.loadAssetAsync(assetPath, bundlePath, onComplete, -1)
end

function unity.loadSpriteAssetAsync(sheetPath, onComplete)
  local assetPath = string.format('assets/%s.asset', sheetPath)
  local bundlePath = sheetBundlePath(sheetPath)
  if traceLoading then
    logd('loadSpriteAssetAsync: bundle=%s asset=%s', bundlePath, assetPath)
  end
  return unity.loadAssetAsync(assetPath, bundlePath, onComplete, -1)
end

function unity.unloadBundle(bundlePath, unloadAsset)
  if traceLoading then
    logd('traceLoading: unloadBundle bundlePath=%s', bundlePath)
  end

  unloadAsset = not not unloadAsset

  if unity.assetLoaders then
    local loader = unity.assetLoaders[bundlePath]
    if loader and loader.loading then
      logd('bundle %s is in use. not unloading', bundlePath)
      return
    end
  end

  return BundleHelper.Unload(bundlePath, unloadAsset)
end

function unity.unloadBundleByPrefabPath(uri, unloadAsset)
  if traceLoading then
    logd('traceLoading: unloadBundleByPrefabPath uri=%s', uri)
  end

  local bundlePath = prefabBundlePath(uri)
  if bundlePath then
    return unity.unloadBundle(bundlePath, unloadAsset)
  end
end

function unity.unloadDeadBundles(iterCount)
  if traceLoading then
    logd('traceLoading: unloadDeadBundles iterCount=%d', iterCount)
  end

  return BundleHelper.UnloadDeadBundles(false, iterCount)
end

function unity.unloadDyingBundles(period)
  if traceLoading then
    logd('traceLoading: unloadDyingBundles period=%s', tostring(period))
  end

  return LBoot.BundleManager.UnloadDyingBundles(period, false)
end

local emptyDelegate = function() end
function unity.unloadAllUnusedAssetsAsync(onComplete, force)
  unity.beginSample('unloadAllUnusedAssetsAsync')

  logd('unload all unused assets...')
  onComplete = onComplete or emptyDelegate
  if not force then
    if unity.acquireAsyncLock('unloadUnused') then
      BundleHelper.UnloadAllUnsuedAssetsAsync(function()
        unity.releaseAsyncLock('unloadUnused')
        onComplete()
      end)
    else
      onComplete()
    end
  else
    coroutineStart(function()
      local acquireStart = Time:get_time()
      while not unity.acquireAsyncLock('unloadUnused') do
        coroutine.yield()
        if Time:get_time() - acquireStart > 15.0 then
          loge('unloadAllUnusedAssetsAsync: lock timeout')
          break
        end
      end

      BundleHelper.UnloadAllUnsuedAssetsAsync(function()
        unity.releaseAsyncLock('unloadUnused')
        onComplete()
      end, 0, {global = true})
    end)
  end

  unity.endSample()
end

function unity.acquireAsyncLock(tag)
  if unity.asyncLockTag then
    -- logd('%s acquireAsyncLock failed. oldTag = %s', tag, unity.asyncLockTag)
    return false
  end

  unity.asyncLockTag = tag
  return true
end

function unity.releaseAsyncLock(tag)
  if unity.asyncLockTag == tag then
    unity.asyncLockTag = nil
  end
end

function unity.clearAssetLoaders()
  if unity.assetLoaders then
    for k, v in pairs(unity.assetLoaders) do
      v:clear()
    end
  end
end

function unity.purgeAssetLoaders()
  if unity.assetLoaders then
    for k, v in pairs(unity.assetLoaders) do
      v:forceClear()
    end
    table.clear(unity.assetLoaders)
  end
end

function unity.resetBundles()
  -- unload all loaded resources, or there could be duplicate assets thereafter
  unity.purgeAssetLoaders()

  if unity.sceneAssets then
    table.clear(unity.sceneAssets)
  end

  if unity.dependBundles then
    table.clear(unity.dependBundles)
  end

  unity.asyncLockTag = nil
  unity.isLoadingLevel = nil

  LBoot.BundleManager.UnloadAll(true)
  return BundleHelper.Reset()
end

function unity.getLoadAfterUnloadHistories(maxTimeDiff)
  maxTimeDiff = maxTimeDiff or 180
  return LBoot.BundleManager.GetLoadAfterUnloadHistories(maxTimeDiff)
end

function unity.getRecentBundleLoadHistories(maxTimeDiff)
  maxTimeDiff = maxTimeDiff or 180
  return LBoot.BundleManager.GetRecentLoadHistories(maxTimeDiff)
end

function unity.clearRecentBundleLoadHistories(maxTimeDiff)
  maxTimeDiff = maxTimeDiff or 999999999
  return LBoot.BundleManager.ClearRecentLoadHistories(maxTimeDiff)
end

function unity.clearBundleLoadHistory(uri)
  return LBoot.BundleManager.ClearLoadHistory(uri)
end

function unity.getBundleLoadHistory(uri)
  return LBoot.BundleManager.GetLoadHistory(uri)
end

local bundleExistsCached = {}

local function doBundleExists(uri)
  if not uri then return false end
  if bundleExistsCached[uri] then return true end

  uri = uri:lower()
  local fullUri = uri ..'.ab'
  if uri:match('%.ab$') or uri:match('%.ab%.') then
    fullUri = uri
  end
  -- logd('bundle fullUri=%s', fullUri)

  -- this is slow (3ms/op on Nexus 6P)
  local res = FileUtils.IsFileExists(fullUri)

  -- once a bundle exists, it won't be removed during game
  if res then bundleExistsCached[uri] = true end
  return res
end

function unity.bundleExists(uri)
  unity.beginSample('unity.bundleExists')
  local res = doBundleExists(uri)
  unity.endSample()
  return res
end

function unity.prefabExists(uri)
  if not uri then return false end
  uri = uri:lower()
  if game.shouldLoadAssetInEditor() then
    local path = 'assets/'..uri .. '.prefab'
    return File.Exists(path)
  else
    return prefabBundlePath(uri) ~= nil
  end
end

function unity.getActiveScene()
  return SceneManager:GetActiveScene()
end

function unity.getActiveSceneName()
  local scene = SceneManager:GetActiveScene()
  if scene then
    return scene:get_name()
  else
    return 'no_scene'
  end
end

local lastTimeLabel = nil
local lastTimeRecorded = nil

function unity.recordTime(label, ...)
  local time = socket.gettime()
  local args = {...}
  local elapsed
  if #args >= 1 then
    if type(args[#args]) == 'number' then
      elapsed = args[#args]
      table.remove(args)
    end
    if #args > 0 then
      label = string.format(label, unpack(args))
    end
  end

  if elapsed then
    logd('recordTime: %s (%.3f secs from start)', label, elapsed)
  elseif lastTimeRecorded then
    elapsed = time - lastTimeRecorded
    logd('recordTime: %s (%.3f secs from "%s")', label, elapsed, lastTimeLabel)
  else
    logd('recordTime: %s', label)
  end

  lastTimeLabel = label
  lastTimeRecorded = time
end

local doSamples = nil
local lastSampleLabel = nil

function unity.enableSamples(val)
  doSamples = val
end

local function ensureStrings(array)
  for i = 1, #array do local v = array[i]
    array[i] = tostring(v)
  end
  return array
end

function unity.beginSample(label, ...)
  if doSamples then
    local args = ensureStrings({...})
    local label = string.format("[lua]"..label, unpack(args))
    -- logd('beginSample: %s %s', label, debug.traceback())
    UnityEngine.Profiler.BeginSample(label)
    lastSampleLabel = label
  end
end

function unity.endSample()
  if doSamples then
    --logd('endSample: %s %s', tostring(lastSampleLabel), debug.traceback())
    UnityEngine.Profiler.EndSample()
  end
end

