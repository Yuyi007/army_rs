-- initApp.lua

require 'lboot/lboot'
require 'lboot/lboot_unity'
require 'lboot/globals'
require 'game/rss'

local sdkFuncs = require 'game/sdk'
local tracemem = rawget(_G, 'TRACE_MEM')

local function loadEnv()
  local host = unity.getString('app.server.host')
  local port = unity.getString('app.server.port')
  local port2 = unity.getString('app.server.port2')

  if host == '' then host = game.defaultHost end
  if port == '' then port = game.defaultPort end
  if port2 == '' then port2 = game.defaultPort2 end

  game.server = {
    host = host,
    port = tonumber(port),
    port2 = tonumber(port2),
  }
end

local function initEnv()
  log('initApp: initEnv')

  if game.mode == 'production' then
    sdkFuncs.initProdEnv()
  else
    -- development mode: load environment from config
    loadEnv()
    sdkFuncs.initDebugEnv()
  end
end

local function initQuality()
  logd('initApp: initQuality')

  local qualitySettings = QualityUtil.initQualitySettings()
  QualityUtil.applyQualitySettings(qualitySettings)
end

local function initScene()
  log('initApp: initScene')

  -- splash go in EntryPoint is visible by default,
  -- change it to invisible when lua inited
  local splashGo = GameObject.Find('/UIRoot/splash')
  if splashGo then
    logd('set splash to invisible')
    local canvas = splashGo:GetComponent('Canvas')
    canvas:set_enabled(false)
  end

  ui:goto(UpdatingScene.new())

  -- -- try to fix
  -- -- 登陆账号后，重新再进入游戏，当界面上方显示账号信息时，不能全屏显示（如图）
  -- if game.platform == 'android' then
  --   UnityEngine.GL.Clear(true, true, Color.black)
  -- end
end

local function initGame()
  log('initApp: initGame')

  local g = require 'game/gameGlobals'; g({
    loadConfig = false,
  })

  logd('initApp: preinit')
  local preinit = require 'game/preinit'
  preinit(nil, function ()
    if not game.appInited then
      -- hide splash
      SplashUtil.hideSplash()
      -- Util.playMovie('episode1.mp4')
    end

    -- This fixes android scratched screen after play movie
    -- if game.platform == 'android' then
    --   UnityEngine.GL.Clear(true, true, Color.black)
    -- end
    -- local mpInit = require 'game/initGame'
    -- if mpInit.initGame then mpInit.initGame() end
    log('initApp: preinit done')
    initScene()
  end)
end

local function initApp()
  if game.debug > 0 then
    logd("initApp: %s", debug.traceback())
  end

  if LBoot.FVAlert then
    LBoot.FVAlert.Init()
  end

  OsCommon.setAudioSessionPlayback()

  if tracemem then traceMemory('initApp 1') end

  if game.debug > 0 and game.mode == 'development' then
    -- require 'lboot/test/PerformanceTest'
    -- require 'lboot/unity/test/PerformanceTest'
    -- require 'lboot/test/MTwistTest'
    -- require 'lboot/test/LKcpTest'
    -- require 'game/test/PerformanceTest'
  end

  -- initEnv()


  if tracemem then traceMemory('initApp 2') end

  local ok, err = pcall(initQuality)
  if not ok then
    loge('initApp: initQuality failed! err=%s', tostring(err))
  end

  if tracemem then traceMemory('initApp 3') end

  initGame()

  game.appInited = true
end

return function ()
  setLogLevel('debug')
  sdkFuncs.initSDK(initApp)
end