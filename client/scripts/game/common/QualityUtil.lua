class('QualityUtil')

local m = QualityUtil

m.lowFrameRate = 30
m.mediumFrameRate = 45
m.highFrameRate = 60

local qualitySettings = {
  ['insane'] = {
    name = 'insane',
    resolution = 1,                         --分辨率
    targetFrameRate = m.highFrameRate,      --帧率
    enableShadows = true,                   --阴影
    enableMovingCars = true,                --
    maxOnScreenPlayers = 20,                --
    farClipPlane = 1000,                    --远裁面
    npcClipPlane = 100,                     --近裁面
    enablePostEffects = true,               --抗锯齿
    enableHighQuality = true,               --
    enableBloomHdr = true,                  --HDR贴图
    bloomLevel=3,                           --
    enableFXAA = true,                      --快速近似抗锯齿
    -- music = true,                        --背景音乐
    -- sound = true,                        --音效
    textureVariant = 'hd',                  --
    batchLoadNum = 5,                       --
    waitMax = 10,                           --
    uianimation = true,                     --UI动画
    particleLevel = 0,                      --粒子特效
    maxLiveParticles = 0,                   --特效时长
    textureQuality=0,                       --贴图质量
    cameraStatus = 'horizontal',            --相机属性
    -- musicValue = 1,
    -- soundValue = 1,
  },
  ['ultra'] = {
    name = 'ultra',
    resolution = 1,
    targetFrameRate = m.highFrameRate,
    enableShadows = true,
    enableMovingCars = true,
    maxOnScreenPlayers = 15,
    farClipPlane = 750,
    npcClipPlane = 75,
    enablePostEffects = true,
    enableHighQuality = true,
    enableBloomHdr = false,
    bloomLevel=2,
    enableFXAA = true,
    -- music = true,
    -- sound = true,
    textureVariant = 'hd',
    batchLoadNum = 3,
    waitMax = 7,
    uianimation = true,
    particleLevel = 0,
    maxLiveParticles = 0,
    textureQuality=0,
    cameraStatus = 'horizontal',
    -- musicValue = 1,
    -- soundValue = 1,
  },
  ['high'] = {
    name = 'high',
    resolution = 0.8,
    targetFrameRate = m.mediumFrameRate,
    enableShadows = true,
    enableMovingCars = false,
    maxOnScreenPlayers = 10,
    farClipPlane = 750,
    npcClipPlane = 50,
    enablePostEffects = true,
    enableHighQuality = true,
    enableBloomHdr = false,
    bloomLevel=1,
    enableFXAA = false,
    -- music = true,
    -- sound = true,
    textureVariant = 'hd',
    batchLoadNum = 3,
    waitMax = 5,
    uianimation = true,
    particleLevel = 0,
    maxLiveParticles = 0,
    textureQuality=1,
    cameraStatus = 'high',
    -- musicValue = 0.5,
    -- soundValue = 0.5,
  },
  ['medium'] = {
    name = 'medium',
    resolution = 0.8,
    targetFrameRate = m.mediumFrameRate,
    enableShadows = true,
    enableMovingCars = false,
    maxOnScreenPlayers = 5,
    farClipPlane = 500,
    npcClipPlane = 50,
    enablePostEffects = true,
    enableHighQuality = true,
    enableBloomHdr = false,
    bloomLevel=0,
    enableFXAA = false,
    -- music = true,
    -- sound = true,
    textureVariant = 'hd',
    batchLoadNum = 2,
    waitMax = 3,
    uianimation = true,
    particleLevel = 1,
    maxLiveParticles = 8,
    textureQuality=2,
    cameraStatus = 'high',
    -- musicValue = 0,
    -- soundValue = 0,
  },
  ['low'] = {
    name = 'low',
    resolution = 0.6,
    targetFrameRate = m.lowFrameRate,
    enableShadows = false,
    enableMovingCars = false,
    maxOnScreenPlayers = 5,
    farClipPlane = 500,
    npcClipPlane = 50,
    enablePostEffects = true,
    enableHighQuality = true,
    enableBloomHdr = false,
    bloomLevel=0,
    enableFXAA = false,
    -- music = true,
    -- sound = true,
    textureVariant = 'hd',
    batchLoadNum = 2,
    waitMax = 2,
    uianimation = true,
    particleLevel = 2,
    maxLiveParticles = 6,
    textureQuality=3,
    cameraStatus = 'high',
    -- musicValue = 0,
    -- soundValue = 0,
  },
  ['power_saving'] = {
    name = 'power_saving',
    resolution = 0.6,
    targetFrameRate = m.lowFrameRate,
    enableShadows = false,
    enableMovingCars = false,
    maxOnScreenPlayers = 5,
    farClipPlane = 500,
    npcClipPlane = 50,
    enablePostEffects = false,
    enableHighQuality = false,
    enableBloomHdr = false,
    bloomLevel=0,
    enableFXAA = false,
    -- music = true,
    -- sound = true,
    textureVariant = 'hd',
    batchLoadNum = 2,
    waitMax = 2,
    uianimation = true,
    particleLevel = 2,
    maxLiveParticles = 6,
    textureQuality=2,
    cameraStatus = 'high',
    -- musicValue = 0,
    -- soundValue = 0,
  },
}
qualitySettings['default'] = clone(qualitySettings['high'])

local SETTINGS_KEY = 'app.qualitySettings11'


-- called in initApp.lua
function m.initQualitySettings()
  local settings = m.loadQualitySettings()
  if settings then
    logd("QualityUtil: load previous settings")
    return table.merge(qualitySettings['default'], settings)
  else
    local autoLevel = m.getQualityLevel('smart')
    logd("QualityUtil: first time enter game, auto choose quality: %s", tostring(autoLevel))
    local settings = m.getQualitySettings(autoLevel)
    m.saveQualitySettings(settings)
    m.firstTimeChooseQuality = autoLevel
    return settings
  end
end

function m.cachedQualitySettings()
  if not m.cachedSettings then
    local settings = m.loadQualitySettings()
    m.cachedSettings = table.merge(clone(qualitySettings.default), settings)
  end
  return m.cachedSettings
end

function m.loadQualitySettings()
  --return qualitySettings.insane
   local text = unity.getString(SETTINGS_KEY)
   local settings = nil

   if text and text ~= '' then
     local ok, res = pcall(function () return cjson.decode(text) end)
     if ok then settings = res end
   end

   return settings
end

function m.saveQualitySettings(settings)
  local json = cjson.encode(settings)
  unity.setString(SETTINGS_KEY, json)
  m.cachedSettings = nil
end

function m.applyQualitySettings(settings)
  if m.isMemoryTight() and game.platform == 'android' then
    settings.textureVariant = 'ld'
    settings.npcClipPlane = math.max(settings.npcClipPlane, 20)
  end

  unity.setTextureLmt(settings.textureQuality)

  if settings.enableFXAA then
    unity.setAAMode(4)
  else
    unity.setAAMode(0)
  end

  unity.setPixelLightCount(1)              --正向渲染时像素光源的最大数目
  unity.setVsync(0)                        --垂直消隐，防止撕裂现象
  unity.setAnisotropicFiltering(0)
  local s = settings.enableShadows and 1 or 0
  unity.setCastShadow(s)

  -- settings.resolution = 0.8
  unity.setResolution(settings.resolution)
  logd("settings.targetFrameRate:%s", tostring(settings.targetFrameRate))
  unity.setTargetFrameRate(settings.targetFrameRate)
  unity.setTextureVariant(settings.textureVariant)

  unity.QualitySettings:set_particleRaycastBudget(2)

  logd('QualityUtil: enablePowerSave=%s', tostring(settings.enablePowerSave))

  if settings.enablePowerSave then
    unity.QualitySettings:set_blendWeights(1)
    UnityEngine.Screen:set_sleepTimeout(UnityEngine.SleepTimeout:get_SystemSetting())
  else
    unity.QualitySettings:set_blendWeights(4)
    UnityEngine.Screen:set_sleepTimeout(UnityEngine.SleepTimeout:get_NeverSleep())
  end

  local cameraStatus = settings.cameraStatus or 'horizontal'

  -- if MainSceneCamera.curInstance then
  --   MainSceneCamera.curInstance:switchStatus(cameraStatus)
  --   MainSceneCamera.curInstance:initLayers()
  -- end

  if rawget(_G, 'sm') then
    sm:setEnableMusic(settings.music)
    sm:setEnableSound(settings.sound)
  end

  if rawget(_G, 'cc') then
    --cc.trimOnScreenPlayers()

    local scene = cc.scene
    if scene and not scene.isFightScene and
       scene.updateLoaderByQuality then
      scene:updateLoaderByQuality()
    end

    if cc.camera then
      UIUtil.initFullScreenCtrlRects(cc.camera)
    end
  end

  UIUtil.initCtrlRectPointCache()
end

function m.getQualityLevel(t)
  if t == 'smart' then
    t = QualityUtil.getDeviceClass()
    logd("QualityUtil.getQualityLevel: smart decide device class is %s", tostring(t))
  end

  return t
end

function m.getQualitySettings(t)
  if t == nil or t == 'smart' then
    t = m.getQualityLevel('smart')
  end

  local settings = qualitySettings.default
  if qualitySettings[t] then settings = qualitySettings[t] end

  settings = clone(settings)

  --if m.isMemoryTightStrict() or m.getGpuScore() < 30000 then
  --  logd('QualityUtil.getQualitySettings: disabling bloom and FXAA')
  --  settings.enableBloomHdr = false
  --  settings.enableFXAA = false
  --  settings.enableHighQuality = false
  --  settings.enablePostEffects = false
  --end

  --if m.isMemoryTightStrict() and (t == 'low' or t == 'medium' or t == 'power_saving') then
  --  settings.textureVariant = 'ld'
  --end

  return settings
end

function m.getDeviceMem()
  local mem = game.systemInfo.systemMemorySize

  -- some devices are like mem=2097152
  -- some devices are like mem=2048
  -- some devices are like mem=5.8
  if mem > 100000 then
    mem = mem / 1000.0
  elseif mem < 10 then
    mem = mem * 1000.0
  end

  return mem
end

function m.isMemoryTight()
  -- if game.platform == 'ios' then return false end

  if m._isMemoryTight == nil then
    m._isMemoryTight = m.isMemoryTightStrict()
  end

  return m._isMemoryTight
end

function m.isMemoryTightStrict()
  return m.getDeviceMem() < 1600
end

function m.getGpuScore()
  local gpu = m.matchGpu()
  if gpu then
    return gpu.score or 0
  else
    return 0
  end
end

function m.getDeviceClass()
  local deviceModel = game.systemInfo.deviceModel
  local deviceName = game.systemInfo.graphicsDeviceName
  local freq = game.systemInfo.processorFrequency
  local mem = m.getDeviceMem()

  logd('getDeviceClass: deviceModel=%s deviceName=%s mem=%s freq=%s',
    tostring(deviceModel), tostring(deviceName), tostring(mem), tostring(freq))
  
  if string.match(deviceName, '^Emulated') then
    -- the editor
    return 'insane'
  elseif string.match(deviceModel, 'iPhoneX') or
    string.match(deviceModel, 'iPhone10') or
    string.match(deviceModel, 'iPhone9') or
    string.match(deviceModel, 'iPhone8') or
    string.match(deviceModel, 'iPad7') or
    string.match(deviceModel, 'iPad6') or
    string.match(deviceModel, 'iPad5,4') or
    string.match(deviceModel, 'iPad5,3') then
    -- iPhone X, 8, 8Plus, 7, 7Plus, 6s, 6sPlus, iPad air2, iPad Pro
    return 'insane'
  elseif string.match(deviceModel, 'iPhone7') or
    string.match(deviceModel, 'iPad5') then
    -- iPhone 6, 6Plus, iPad mini 4
    return 'high'
  elseif string.match(deviceModel, 'iPhone6') or
    string.match(deviceModel, 'iPad4') then
    -- iPhone 5s, iPad mini2, mini3
    return 'high'
  elseif string.match(deviceModel, 'iPhone5') then
    -- iPhone 5, 5c
    return 'medium'
  elseif string.match(deviceModel, 'iPad2') then
    -- iPad mini
    return 'low'
  end

  local gpu = m.matchGpu()
  if gpu then
    gpu.score = gpu.score or 0
    if (gpu.rank < 350 or gpu.score > 32000) and mem >= 1800 then
      return 'insane'
    elseif (gpu.rank < 450 or gpu.score > 28000) and mem >= 1600 then
      return 'ultra'
    elseif (gpu.rank < 550 or gpu.score > 20000) and mem >= 1200 then
      return 'high'
    elseif (gpu.rank < 650 or gpu.score > 10000) and mem >= 900 then
      return 'medium'
    else
      return 'low'
    end
  end

  logd('getDeviceClass: use default setting')
  return 'high'
end

function m.matchGpu()
  local deviceName = game.systemInfo.graphicsDeviceName
  local gpulist = require 'lboot/utils/gpulist'

  for i = 1, #gpulist do
    local gpu = gpulist[i]
    if m.deviceNameMatchGpu(deviceName, gpu) then
      logd('QualityUtil.matchGpu: %s', tostring(gpu.name))
      return gpu
    end
  end
  return nil
end

function m.deviceNameMatchGpu(deviceName, gpu)
  if deviceName == gpu.name then return true end

  if #gpu.keywords == 0 then
    return false
  else
    for _, keyword in ipairs(gpu.keywords) do
      if string.match(deviceName, keyword) then
        -- strict match
      else
        if string.match(deviceName, '^Mali.+MP') and string.match(keyword, '^MP') then
          -- weak match
        else
          -- not match
          return false
        end
      end
    end
  end

  return true
end

function m:isBangScreen()
  if game.platform == 'ios' then
    if game.safeArea.width ~= game.fullSize.width then
      return true
    end
  end
  return false    
end
