View('UpdatingScene', nil, function(self, options)
  self.retryNum = 0
  self.touched = false

  local defaultDevMode = nil
  local skipUpdate = false

  logd('skipUpdate = %s', skipUpdate)

  -- 选项
  self.options = table.merge({
    skipUpdate = skipUpdate,      -- 直接跳过更新，调试用
    devMode = defaultDevMode,
  }, options)
  

  self:bindScene()
end)

local m = UpdatingScene

-- because config sqlite files can be overwritten (without reopened) during updates
-- we should save all loc strings to local cache
local strCache = {}
local loc = function (key)
  if not strCache[key] then
    strCache[key] = rawget(_G, 'loc')(key)
  end
  return strCache[key]
end

function m.signalReconnect()
  return mp:signal('reconnect')
end

function m.signalCancelled()
  return mp:signal('cancelled')
end

function m.signalConnected()
  return mp:signal('ReconnectHandler_done')
end

function m:bindScene()
  local sceneName = unity.getActiveSceneName()
  log('UpdatingScene.bindScene: scene=%s', tostring(sceneName))
  if sceneName == 'EntryPoint' then
    local go = GameObject.Find('/UIRoot/combat_loading')
    if go then
      logd("UpdatingScene.bindeScene, use UIRoot combat loading")
      self.useEntryPoint = true
      self:bind(go)
      return
    end
  end

  self.useEntryPoint = false
  self:bind('prefab/ui/common/combat_loading')
end

function m:__goto()
  if self.useEntryPoint then
    local go = self.gameObject
    local canvas = go:GetComponent('Canvas')
    local scaler = go:GetComponent('CanvasScaler')

    -- ui:setupCanvasScale(canvas, scaler)
    logd("UpdatingScene enable canvas ")
    canvas:set_enabled(true)
  else
    self:baseGoto()
  end
end

function m:destroy()
  if self.useEntryPoint then
    logd('UpdatingScene.destroy: useEntryPoint=%s', tostring(self.useEntryPoint))
  else
    self:baseDestroy()
  end
end

function m:init()
  log('UpdatingScene.init: useEntryPoint=%s', tostring(self.useEntryPoint))

  -- 登陆账号后，重新再进入游戏，当界面上方显示账号信息时，不能全屏显示（如图）
  if game.platform == 'android' then
    UnityEngine.GL.Clear(true, true, Color.black)
  end

  if mp.setRetryFailOp then
    mp:setRetryFailOp("retry")
  end

  if game.platform == 'ios' or game.platform == 'android' then
    UpdateManager.setDownloader(NativeBatchDownloader)
  end
  
  if self.updateBg then 
    self.updateBg:setVisible(true) 
  end
  if self.loadingBg then self.loadingBg:setVisible(false) end

  self:performWithDelay(0.1, function()
    self:doInit()
    -- self:updateTips()
    self.loading_all_txtLoading:setString(loc('str_loading_resources'))
    if self.loading_all then self.loading_all:setVisible(true) end
    self:schedule(function()
      -- self:updateTips()
    end, 4)

    if game.mode == 'development' then
      self.node:onClick(function()
        self:enterDebug()
      end)   
    end
  end)
end

function m:exit()
  logd('UpdatingScene.exit: useEntryPoint=%s', tostring(self.useEntryPoint))

  if self.useEntryPoint then
    self.gameObject:GetComponent('Canvas'):set_enabled(false)
  end

  m.signalReconnect():clear()
  if um and type(um.stop) == 'function' then um:stop() end
  if self.um then self.um:stop() end
  self:clearRestartHandler()

  if mp.setRetryFailOp then
    mp:setRetryFailOp(nil)
  end
end

function m:clearRestartHandler()
  if self.restartHandler then
    scheduler.unschedule(self.restartHandler)
    self.restartHandler = nil
  end
end

function m:enterDebug()
  if game.mode == 'development' then
    if not self.touched then
      m.signalReconnect():clear()
      log('Entering DebugServerScene from UpdatingScene')
      ui:goto(DebugServerScene.new())
      self.touched = true
    else
      log('Already entered DebugServerScene')
    end
  end
end

function m:updateTips()
  if self.loading_all_txtTip then
    -- because config sqlite files can be overwritten (without reopened) during updates
    -- we should save all tips to memory
    if not self.tips then
      self.tips = {}
      for i, tip in ipairs(cfg.loadingtips) do
        table.insert(self.tips, loc(tip))
      end
    end

    local tip = self.tips[math.random(table.getn(self.tips))]
    self.loading_all_txtTip:setString(tip)
  end
end

function m:doInit()
  self:initGame()

  local doUpdate = function ()
    log('UpdatingScene: doUpdate')

    local sdkFuncs = require 'game/sdk'

    sdkFuncs.checkUpdate(function ()
      self:checkInAppUpdate()
    end)
  end

  local onReconnect = function ()
    local text = {
      loc('str_connect_fail')..'.',
      loc('str_connect_fail')..'..',
      loc('str_connect_fail')..'...',
      loc('str_connect_fail')..'....',
      loc('str_connect_fail')..'.....',
    }
    if self.loading_all_txtLoading then
      self.loading_all_txtLoading:setString (text[self.retryNum % 5 + 1])
    end
    self.retryNum = self.retryNum + 1
    log('UpdatingScene: onReconnect retryNum=%d', self.retryNum)

    ------------------------------------------
    -- When there is a connection failure:
    ------------------------------------------

    -- 1. try resolve host to ip
    if mp:tryResolveAndReplaceHost() then
      log("UpdatingScene: set server ip to %s", tostring(mp.host))
      game.server.ip = mp.host
    end

    -- 2. try swap port and optional port
    -- local port = game.server.port2
    -- game.server.port2 = game.server.port
    -- game.server.port = port
    -- logd("set server port to %s", tostring(port))
  end

  local onConnected = function ()
    log('UpdatingScene: onConnected retryNum=%s', tostring(self.retryNum))

    m.signalReconnect():remove(onReconnect)
    mp.options.showReconnectMask = true

    self:update()

    if game.mode == 'development' then
      self:performWithDelay(0, doUpdate, false)
    else
      doUpdate()
    end
  end
  if mp:isConnected() then
    onConnected()
  else
    m.signalReconnect():add(onReconnect)
    m.signalConnected():addOnce(onConnected)
  end
end

function m:initGame()
  local initGame = (require 'game/initGame').initGame
  local status, err = pcall(function () initGame({
    showReconnectMask = false,
    loadConfig = true,
    loadConfigOptions = {optimize = true},
    initUI = false,
  }) end)
  if status then
    log('$$$ initGame success!')
  else
    log('$$$ initGame failed: %s', tostring(err))
    log(debug.traceback())
  end
end

local retryHandle = nil

function m:checkInAppUpdate()
  -- update with UpdateManager
  local onProgress = function(info, msg)
    local totalMB = math.round(info.sizeTotal / 1024.0 / 1024, 2)
    local doneMB = math.round(info.sizeDone / 1024.0 / 1024, 2)
    local percentage = 0
    if info.sizeTotal > 0 then
      percentage = math.round(info.sizeDone / info.sizeTotal * 100, 1)
    end

    -- self.progressBar:setPercentage(percentage)
    -- self.mcLight:setPositionX(184+5.84*percentage)
    if self.loading_all_txtLoading then
      if msg == '_downloading' then
        self.loading_all_txtLoading:setString (loc('str_loading_update_content') .. ' ' ..
          percentage .. "% " .. info.speed .. "KB/s ")
        self.loading_all_progress:setProgress(percentage / 100)
      elseif msg == '_extracting' then
        self.loading_all_txtLoading:setString (loc('str_extracting_update_content') .. ' ' ..
          percentage .. "% ")
      else
        self.loading_all_txtLoading:setString (msg)
      end
    end
  end
  local num = math.random(24)
  self.loading_all_txtTip:setString(loc('str_loadingTip'..num))
  local settings = clone(QualityUtil.cachedQualitySettings())
  if settings.music == nil then
    settings.music = true
  end
  if settings.sound == nil then
    settings.sound = true
  end
  if settings.yellowGuideLine == nil then
    settings.yellowGuideLine = true
  end
  if settings.blueGuideLine == nil then
    settings.blueGuideLine = true
  end
  if settings.shake == nil then
    settings.shake = true
  end
  QualityUtil.applyQualitySettings(settings)
  QualityUtil.saveQualitySettings(settings)
  sm:playMusic('ui_common/sign_in')
  local onError = function(info, msg)
    logd('UpdatingScene: onError %s', msg)

    if self.loading_all_txtLoading then
      self.loading_all_txtLoading:setString (loc('str_loading_error_content'))
    end
  end

  local onComplete = function(info, msg)
    log('UpdatingScene: onComplete %s', tostring(msg))
    -- self.mcLight:setPositionX(768)
    -- self.progressBar:setPercentage(100)
    if self.loading_all_txtLoading then
      self.loading_all_txtLoading:setString (loc('str_loading_resources'))
    end

    -- switch runtime environment
    -- game.resourceFolder is used in android debug mode
    -- if game.resourceFolder is nil then normal update folder is used
    local status, err = pcall(function ()
      switchEnv(game.resourceFolder)
    end)
    if status then
      logd('$$$ switchEnv success!')
    else
      loge('$$$ switchEnv failed: ' .. tostring(err))
    end

    require 'lboot/lboot'
    require 'lboot/lboot_unity'
    require 'lboot/globals'
    require 'game/initGame'

    -- update client version
    game.clientVersion = UpdateManager.getClientVersion()
    log('UpdatingScene: clientVersion=' .. tostring(game.clientVersion))

    -- do rpc update again, enter game
    md:rpcUpdate(function (msg)
      local devMode = self.options.devMode
      log('UpdatingScene: devMode=%s', tostring(devMode))

      if devMode == 'none' then
        game.devMode = nil
      elseif devMode then
        game.devMode = devMode
      end

      local restart = require 'game/restart'

      self:clearRestartHandler()
      local delay = 0
      -- use a longer delay for clicking to enter debug server view
      if game.mode == 'development' then delay = 1 end

      self.restartHandler = scheduler.performWithDelay(delay, function()
        -- should restart before preload
        -- otherwise all the manager instances used in LoadingManager (gp, ui, sm etc) would be old
        restart({ toTitle = false, initGame = true, toLogin = false}, function()
          local preload = require 'game/preload'
          preload(self, nil, function()
              if game.mode == 'development' then
                ui:goto(LoginViewTest.new())
              else
                ui:goto(LoginView.new())
              end
            end)
        end)
      end)
    end)
  end

  local unscheduleRetry = function ()
    if retryHandle then
      self:unschedule(retryHandle)
      retryHandle = nil
    end
  end

  local onRpcError = function ()
    log('UpdatingScene: onRpcError')

    if self.loading_all_txtLoading then
      self.loading_all_txtLoading:setString (loc('str_error_version'))
    end
    unscheduleRetry()
    retryHandle = self:performWithDelay(5.0, function () self:checkInAppUpdate() end, false)
  end

  m.signalCancelled():clear()
  m.signalCancelled():addOnce(onRpcError)

  local sent = md:rpcUpdate(function (msg)
    m.signalCancelled():clear()
    unscheduleRetry()
    if msg.success == false then
      -- 出错，重新请求
      onRpcError()
    elseif msg.pkg_url and msg.pkg_version and string.len(msg.pkg_url) > 0 and
      string.len(msg.pkg_version) > 0 then
      -- 强制更新
      local doForceUpdate = function ()
        OsCommon.showMessageBox{
          title = loc('str_new_version'),
          message = loc('str_update_hint'),
          button = loc('str_lua_7'),
          onComplete = function ()
            if game.platform == 'ios' then
              CCNative:openURL(msg.pkg_url)
              doForceUpdate()
            elseif game.platform == 'android' then
              local filename = string.sub(msg.pkg_url, string.rfind(msg.pkg_url, '/') + 1)
              downloadFile{
                url = msg.pkg_url,
                filename = filename,
                title = loc('str_lua_36'),
                desc = loc('str_lua_140'),
                onRequestSuccess = function ()
                  logd('onRequestSuccess: exiting')
                  local exit = require 'scripts/exit'
                  exit()
                end,
              }
            end
          end,
          cancelable = false,
        }
      end
      doForceUpdate()
      game.appNeedForceUpdate = true
    elseif msg.url and msg.client_version and string.len(msg.url) > 0 and
      string.len(msg.client_version) > 0 then
      -- 游戏内更新
      local skipUpdate = self.options.skipUpdate
      if game.editor() then
        skipUpdate = true
      end

      local skipVersion = nil

      local concurrentDownloads = 2
      if msg.concurrent_downloads and msg.concurrent_downloads ~= cjson.null then
        concurrentDownloads = msg.concurrent_downloads
      end
      local excludesTagPattern = nil

      local callback = function()
        if self.um then self.um:stop() end

        local curView = ui.curView
        if curView and curView ~= self then
          logd('UpdatingScene: skip no wifi update because you have switched to other scenes! curView=%s %s',
            tostring(curView), tostring(curView.classname))
          return
        end

        self.um = UpdateManager.new(msg.client_version, msg.url, onProgress, onError, onComplete,
          {
          skipUpdate=skipUpdate,
          skipVersion=skipVersion,
          allowStart = function ()
            local curView = ui.curView
            if curView and curView ~= self then
              logd('UpdatingScene: skip download because you have switched to other scenes! curView=%s %s',
                tostring(curView), tostring(curView.classname))
              return false
            end
            return true
          end,
          concurrentDownloads=concurrentDownloads,
          excludesTagPattern=excludesTagPattern,
          }):start()
      end

      local wifi = OsCommon.isLocalWifiAvailable()

      if wifi then
        logd('checkConnection: wifi available')
        callback()
      else
        logd('checkConnection: NO WIFI')
        OsCommon.showMessageBox{
          title = loc('str_lua_77'),
          message = loc('str_wlan_download_warning'),
          button = loc('str_lua_7'),
          onComplete = callback
        }
      end

    else
      -- 无更新
      log('no update, skipping...')
      if self.loading_all_txtLoading then
        self.loading_all_txtLoading:setString (loc('str_lua_80'))
      end
      onComplete(nil, loc('str_lua_80'))
    end
  end)

  if not sent then
    logd('UpdatingScene: request not sent')
    onRpcError()
  end
end
