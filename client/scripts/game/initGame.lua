
require 'game/rss'
require 'game/sdk'

local tracemem = rawget(_G, 'TRACE_MEM')

local function closeConnection()
  local mp = rawget(_G, 'mp')
  if mp then mp:destroy() end
end

local function resetResources()
end

local function initConnection()
  local hostOrIp = game.server.ip or game.server.host
  mp:init(hostOrIp, game.server.port)

  MessageHandler.init()
  ReconnectHandler.init()
end

local function initQuality()
  local qualitySettings = QualityUtil.initQualitySettings()
  QualityUtil.applyQualitySettings(qualitySettings)
end

local function initGame(options)
  if game.debug > 0 then
    logd('initGame: %s', debug.traceback())
  end
  
  if tracemem then traceMemory('initGame 1') end

  -- first destroy the old game environment
  -- closeConnection()
  -- resetResources()

  if tracemem then traceMemory('initGame 2') end
  -- init new game environment
  local v = require 'game/version'; v()
  local g = require 'game/gameGlobals'; g(options)

  if tracemem then traceMemory('initGame 3') end

  unity.init()
  ColorUtil.init()
  loc.init()
  frameManage()

  -- fix sdkInited for old packages
  game.sdkInited = true

  if tracemem then traceMemory('initGame 4') end

  initQuality()

  -- initConnection()

  -- scheduleLocalNotifications()
  -- GuildUtil.showDungeonNotification()
  -- VerifyCenter.Start("192.168.105.8",7668)
  

  if tracemem then traceMemory('initGame end') end
end

return {
  initGame = initGame,
}
