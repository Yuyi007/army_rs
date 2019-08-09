-- DebugServerScene.lua

ViewScene('DebugServerScene', 'scenes/game/debug', function (self)
  local sceneName = unity.getActiveSceneName()
  logd('DebugServerScene.new scene=%s', tostring(sceneName))
  if sceneName == 'EntryPoint' then
    -- for android, use unpacked bundles before loading any bundles
    addSearchPath(UpdateManager.rootpath() .. '/bundles/')
  end
end)

local m = DebugServerScene
m.__bindNodes = true

local nonempty = function(a, b)
  if a and string.len(a) > 0 then
    return a
  else
    return b
  end
end

function m:init()
  logd('DebugServerScene.init previousSdk=%s game.sdk=%s', tostring(unity.getString('app.sdk')), tostring(game.sdk))

  self.previousHost = unity.getString('app.server.host')
  self.previousPort = unity.getString('app.server.port')
  self.previousSdk = unity.getString('app.sdk')
  self.previousLocation = unity.getString('app.location')
  self.previousResoution = unity.getString('app.resolution')

  self.txtHostInput:setString(nonempty(self.previousHost, game.server.host))
  self.txtPortInput:setString(nonempty(self.previousPort, game.server.port))
  self.txtSdkInput:setString(nonempty(self.previousSdk, game.sdk))
  self.txtLocationInput:setString(nonempty(self.previousLocation, game.location))
  self.txtResolution:setString(nonempty(self.previousResoution, game.resolution))
  self.txtCustomInput:setString('')
end

function m:onBtnSave()
  game.server.host = self.txtHostInput:getString()
  game.server.port = self.txtPortInput:getString()
  game.server.port2 = game.defaultPort2
  game.server.ip = nil
  game.sdk = self.txtSdkInput:getString()
  game.location = self.txtLocationInput:getString()
  game.resolution = self.txtResolution:getString()

  local status, err = pcall(function ()
    local custom = self.txtCustomInput:getString()
    if custom and string.len(custom) > 0 then
      local func, e = loadstring(custom)
      if func then
        logd('exec custom script: ' .. custom)
        func()
      else
        logd('exec custom script failed! error is ' .. tostring(e))
      end
    end
  end)

  logd('terminating current connection...')
  mp:destroy()

  logd('testing new connection...')
  mp:init(game.server.host, game.server.port)

  logd('terminating new connection...')
  mp:destroy()

  self:close()
end

function m:onBtnClearUpdates()
  local res
  res = UpdateManager.clearUpdates()
  game.clientVersion = UpdateManager.getClientVersion()
  logd('clearUpdates: res=%s game.clientVersion=%s', tostring(res), tostring(game.clientVersion))

  local initKey = 'android-bundle-init'
  unity.setString(initKey, '')

  self:close()
end

function m:onBtnSkipUpdates()
  local res
  game.clientVersion = UpdateManager.getClientVersion()
  logd('game.clientVersion = ' .. tostring(game.clientVersion))
end

function m:onBtnVerifyUpdate()
  UpdateManager.verifyFiles()
end

function m:close(options)
  logd('closing DebugServerScene...')

  -- save settings
  unity.setString('app.server.host', game.server.host)
  unity.setString('app.server.port', game.server.port)
  unity.setString('app.sdk', game.sdk)
  unity.setString('app.location', game.location)
  unity.setString('app.resolution', game.resolution)

  logd("app.server.host = " .. tostring(game.server.host))
  logd("app.server.port = " .. tostring(game.server.port))
  logd("app.server.port2 = " .. tostring(game.server.port2))
  logd("app.server.ip = " .. tostring(game.server.ip))
  logd("app.sdk = " .. tostring(game.sdk))
  logd("app.location = " .. tostring(game.location))

  clearRequires()
  require 'lboot/lboot'
  require 'lboot/lboot_unity'
  require 'lboot/globals'

  local restart = require 'game/restart'
  restart{ toTitle = true, loadConfig = false }
end