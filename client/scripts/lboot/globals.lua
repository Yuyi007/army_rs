-- globals.lua

local tracemem = rawget(_G, 'TRACE_MEM')

if tracemem then traceMemory('globals 1') end

--
luaj    = require 'lboot/lib/luaj'
luaoc   = require 'lboot/lib/luaoc'
luacs   = require 'lboot/lib/luacs'
inspect = require 'lboot/ext/inspect'  -- inspect tables
mtwist  = require 'lboot/ext/mtwist'   -- Mersenne Twister PRNG
socket  = require 'lboot/net/socket/socket'
utf8    = require 'utf8'

-- slt2    = require 'lboot/ext/slt2'     -- template engine
-- SOR     = require 'lboot/ext/sor'      -- Linear Equation System Solver
-- Jumper            = {}
-- Jumper.Grid       = require 'lboot/ext/jumper/grid'
-- Jumper.Pathfinder = require 'lboot/ext/jumper/pathfinder'
-- pb                = requir-'lboot/ext/lua-pb/pb'
-- pb.load_proto('message Test {}', 'test', nil, nil) -- init pb internal global vars

if tracemem then traceMemory('globals 2') end

-- the game parameters
if game == nil then
  prt('init game global')
  game                     = {}                     -- App Constants
  game.location            = LOCATION or 'cn'
  game.deviceOrientation   = "landscape"
  game.isRetinaDisplay     = true
  game.mode                = MODE or 'production'   -- MODE set from config.lua
  game.script              = SCRIPT or 'debug'      -- SCRIPT set from config.lua
  game.devMode             = DEV_MODE or ''         -- DEV_MODE set from config.lua
  game.resourceFolder      = RESOURCE_FOLDER or nil -- RESOURCE_FOLDER set from config.lua
  game.appInited           = false                  -- not used at the moment
  game.appInForeground     = true                   -- whether the app is in foreground
  game.defaultHost         = "127.0.0.1"
  game.defaultPort         = 5081
  game.defaultPort2        = 4081
  game.usage               = USAGE or ''            -- USAGE set from config.lua
  game.server              = { host = game.defaultHost, port = game.defaultPort, port2 = game.defaultPort2 }
  game.platform            = PLATFORM or 'ios'      -- PLATFORM should be set from c host
  game.sdk                 = SDK or 'standard'      -- SDK should be set from c host
  game.market              = MARKET or ''           -- MARKET should be set from c host
  game.pkgVersion          = ''                     -- the package version
  game.version             = DISPLAY_VERSION or ''  -- version displayed to user, plz init in initGame.lua
  game.clientVersion       = ''                     -- client version, used for auto update, plz init in initGame.lua
  game.encoding            = 'msgpack-auto'         -- client encoding
  game.debug               = 2
  game.isStaging           = STAGING or false
  game.resolution          = 1
  game.inspect             = INSPECT or 1
  game.enableGizmos        = true and (game.platform == 'editor') -- You can open this in editor mode
  game.frameCount          = 0
  game.lastFrameScriptTime = 0
  game.lastFrameTime       = 0
  game.luaMemUsage         = 0
  game.luaMemRate          = 0
  game.lastFrameGCSteps    = 0
  game.lastFrameGCSize     = 0
end

game.sigEnterForeground  = Signal.new()

if tracemem then traceMemory('globals 3') end

-- hide output
if game.mode == 'production' then
  game.debug = 0
  setLogLevel('none')
end
setLogLevel('debug')

function game.editor()
  return game.platform == 'editor'
end

function game.ios()
  return game.platform == 'ios'
end

function game.android()
  return game.platform == 'android'
end

function game.isBangScreen()
  if game.platform == 'ios' then
    if game.safeArea.width ~= game.fullSize.width then
      return true
    end
  end
  return false    
end

function game.gizmos() return game.editor() and game.enableGizmos
end

function game.shouldLoadAssetInEditor()
  if game.platform ~= 'editor' then return false end

  local useBundles = {
    -- jenkins = true
  }

  local user = os.getenv("USER")
  if user and useBundles[user] then return false end

  return true
end

if tracemem then traceMemory('globals 4') end

if rawget(_G, 'unity') then
  if not game.safeArea then
    game.safeArea = { width = unity.Screen.safeArea.width , height = unity.Screen.safeArea.height}
  end  
  if not game.fullSize then
    local curResolution = unity.getResolution()
    if game.platform == 'editor' then
      game.fullSize = { width = unity.Screen.width, height = unity.Screen.height }
    else
      game.fullSize = { width = curResolution.width, height = curResolution.height }

      local SystemInfo = UnityEngine.SystemInfo
      local deviceModel = SystemInfo.deviceModel

      local capHeight = 1080

      if game.platform == 'android' then
        capHeight = 1080
      end

      local forceLowRes = {
        ['iPhone7,1'] = true,
        ['iPhone7,2'] = true,
        ['Xiaomi Redmi Note 4X'] = true,
        ['Xiaomi MI 5s'] = true,
      }

      if forceLowRes[deviceModel] then
        capHeight = 720
      end
      logd("[capHeight] capHeight:%s", tostring(capHeight))
      -- cap to capHeight as height
      if game.fullSize.height > capHeight then
        local ratio = capHeight / game.fullSize.height
        game.fullSize.width = math.round(game.fullSize.width * ratio)
        game.fullSize.height = math.round(game.fullSize.height * ratio)
        game.screenRatio = ratio
      end
    end
  end
  local SystemInfo = UnityEngine.SystemInfo
  prt("deviceModel:%s", tostring(SystemInfo.deviceModel))

  game.size = { width = game.fullSize.width, height = game.fullSize.height }
  prt("screen size width=%s, height=%s", unity.Screen.width, unity.Screen.height)
  prt("game size width=%s, height=%s", game.size.width, game.size.height)

  game.frameTime = 1000.0 / UnityEngine.Application.targetFrameRate
  game.monoMemUsage = 0
  game.monoMemRate = 0

  local SystemInfo = UnityEngine.SystemInfo
  game.systemInfo = {
    deviceModel            = SystemInfo.deviceModel,
    deviceName             = SystemInfo.deviceName,
    deviceType             = SystemInfo.deviceType,
    deviceId               = SystemInfo.deviceUniqueIdentifier,
    graphicsDeviceID       = SystemInfo.graphicsDeviceID,
    graphicsDeviceName     = SystemInfo.graphicsDeviceName,
    graphicsDeviceType     = SystemInfo.graphicsDeviceType,
    graphicsDeviceVendor   = SystemInfo.graphicsDeviceVendor,
    graphicsDeviceVendorID = SystemInfo.graphicsDeviceVendorID,
    graphicsDeviceVersion  = SystemInfo.graphicsDeviceVersion,
    graphicsMemorySize     = SystemInfo.graphicsMemorySize,
    npotSupport            = SystemInfo.npotSupport,
    operatingSystem        = SystemInfo.operatingSystem,
    processorCount         = SystemInfo.processorCount,
    processorType          = SystemInfo.processorType,
    processorFrequency     = SystemInfo.processorFrequency,
    supportsImageEffects   = SystemInfo.supportsImageEffects,
    systemMemorySize       = SystemInfo.systemMemorySize,
    -- supportsStencil        = SystemInfo.supportsStencil,
  }


else
  game.systemInfo = {
    model      = '',
    product    = '',
    glVendor   = GL_VENDOR or '',
    glRenderer = GL_RENDERER or '',
    glVersion  = GL_VERSION or '',
    deviceId   = DEVICE_ID or '',
  }
end

if tracemem then traceMemory('globals 5') end

dumpSystemInfo()
setInitialSearchPaths()
disableGlobalVarsOnwards()
setLuaGC()

if tracemem then traceMemory('globals end') end
