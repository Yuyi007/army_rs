-- sdk.lua

local function requireAll()
  local sdk = game.sdk
  logd('requireAll: sdk=%s', tostring(sdk))

  require 'game/sdk/standard/SDKStandard'

  if sdk == 'standard' then
    require 'game/sdk/standard/LoginViewStandard'
  elseif sdk == "yyb" then
    require 'game/sdk/yyb/LoginViewYyb'
    require 'game/sdk/firevale/SDKFirevale'
  else
    require 'game/sdk/firevale/LoginViewFirevale'
    require 'game/sdk/firevale/SDKFirevale'
  end
end

requireAll()

local function initSDK(onComplete)
  local sdk = game.sdk
  logd('initSDK sdk=%s, %s', tostring(sdk), debug.traceback())

  -- currently all sdks use the same account class
  require 'game/model/Account'

  if sdk == 'standard' then
    onComplete()
  else
    local onLogout = function ()
      logd('SDKFirevale logout')
      scheduler.performWithDelay(2.5, function ()
        -- FloatingTextFactory.makeNormal({text = '用户已登出'})
      end)
      md:forgetLogin()
      returnToLogin(function () end)
    end
    local onInit = function (result)
      logd('SDKFirevale init result=%s', peek(result))
      if result.success then
        onComplete()
      end
    end
    SDKFirevale.init(onLogout, onInit)
  end
end

-- init debug environment here: server host, server port etc.
local function initDebugEnv()
  if game.usage == 'test' then
    game.server.host = '127.0.0.1'--'192.168.33.53'
  elseif game.platform == 'editor' then
    unity.enableSamples(false)
  end
end

-- init production environment here: server host, server port etc.
local function initProdEnv()
  if game.usage == "demo" then
    game.server.host = "127.0.0.1"--'106.15.198.248'
  elseif game.usage == 'qatest' then
    game.server.host = "127.0.0.1"--'192.168.104.101'
  else
    game.server.host = "127.0.0.1"--'192.168.33.53'
  end
end

local function checkUpdate(onComplete)
  onComplete()
end

local function didBecomeActive()
end

local function onEnterBackground()
end

local function onEnterForeground()
end

local function onFinishLaunchingWithOptions()
end

local function onApplicationWillTerminate()
end

return {
  initSDK = initSDK,
  initDebugEnv = initDebugEnv,
  initProdEnv = initProdEnv,
  checkUpdate = checkUpdate,
  didBecomeActive = didBecomeActive,
  onEnterBackground = onEnterBackground,
  onEnterForeground = onEnterForeground,
  onFinishLaunchingWithOptions = onFinishLaunchingWithOptions,
  onApplicationWillTerminate = onApplicationWillTerminate,
}
