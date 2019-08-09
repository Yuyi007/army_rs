
local engine = engine

--------------------------------------------------------
-- Handle game rpc requests after mp is reconnected
--------------------------------------------------------

class('ReconnectHandler', function (mp)
end)

local m = ReconnectHandler

function m.init()
  local destroy = mp:signal('destroy')
  if not destroy:added(m.handleDestroy) then
    destroy:add(m.handleDestroy)
  end

  local reconnected = mp:signal('reconnected')
  if not reconnected:added(m.handleReconnect) then
    reconnected:add(m.handleReconnect)
  end

  mp:signal('ReconnectHandler_done'):clear()
end

function m.handleDestroy()
  mp:signal('destroy'):remove(m.handleDestroy)
  mp:signal('reconnected'):remove(m.handleReconnect)

  mp:reinitCodecState()
end

local retryHandle = nil
local maxRetry = nil

local reinitGame = function ()
  logd("mp[%d]: have to reinit game when reconnecting...", mp.id)
  local restart = require 'game/restart'
  restart{ toTitle = true, }
end

local restartGame = function (options)
  -- restart game
  local delay = 0
  logd("mp[%d]: have to restart game when reconnecting, after %f secs...", mp.id, delay)
  hideKeyboard()
  scheduler.performWithDelay(delay, function ()
    local restart = require 'game/restart'
    local opts = { toTitle = false, initGame = false, }
    if options then opts.sdkLogin = options.sdkLogin end
    restart(opts, function ()
      mp:showHint('str_restart_game')
    end)
  end, false)
end

local unscheduleRetry = function ()
  if retryHandle then
    logd('mp[%d]: unschedule last retry', mp.id)
    scheduler.unschedule(retryHandle)
    retryHandle = nil
  end
end

function m.handleReconnect()
  logd("mp[%d]: handleReconnect", mp.id)

  if mp.id == -1 then
    logd('mp[%d]: not inited!', mp.id)
    return
  end

  mp:reinitCodecState()

  -- unschedule current retry immediately
  unscheduleRetry()

  local onReconnectInitDone = function ()
    mp:signal('cancelled'):clear()
    m.onReconnectInitDone()
  end

  ---------------------------------------------------
  -- try resume game data
  ---------------------------------------------------

  local onRpcResumeGameData = function(msg)
    logd('mp[%d]: resume game data done', mp.id)
    onReconnectInitDone()
  end

  ---------------------------------------------------
  -- try relogin
  ---------------------------------------------------

  local tryRelogin = nil
  local onRpcLoginError = function (opts)
    logd('mp[%d]: onRpcLoginError maxRetry=%d', mp.id, maxRetry)
    mp.allowSend = true
    opts = opts or {}
    if opts.retry and maxRetry > 0 then
      unscheduleRetry()
      logd('mp[%d]: schedule retry login maxRetry=%d...', mp.id, maxRetry)
      retryHandle = scheduler.performWithDelay(2.0, tryRelogin, false)
      maxRetry = maxRetry - 1
    else
      restartGame()
    end
  end

  local onRpcLogin = function (msg)
    mp.allowSend = true
    mp:signal('cancelled'):clear()
    unscheduleRetry()

    if msg and msg.success == true then
      local view = ui:curViewName()
      if view == 'LoginView' or view == 'UpdatingScene' then
        -- don't reload game data
        logd('mp[%d]: relogin success', mp.id)
        onReconnectInitDone()
      else
        -- reload data from server
        logd('mp[%d]: relogin success, trying to resume game data', mp.id)
        md:rpcResumeGameData(onRpcResumeGameData)
      end
    else
      -- restart game
      logd('mp[%d]: relogin failed', mp.id)
      onRpcLoginError()
    end
  end

  tryRelogin = function ()
    unscheduleRetry()
    maxRetry = 3

    if md and type(md.loginFunc) == 'function' then
      logd('mp[%d]: trying to relogin', mp.id)
      mp:signal('cancelled'):clear()
      mp:signal('cancelled'):addOnce(function ()
        onRpcLoginError({retry = true})
      end)
      md:loginFunc(onRpcLogin, true)
      mp.allowSend = false
    else
      -- probably hasn't login yet
      logd("mp[%d]: not trying to login", mp.id)
      onReconnectInitDone()
      -- onRpcLoginError()
    end
  end

  ---------------------------------------------------
  -- try update
  ---------------------------------------------------

  local tryUpdate = nil
  local onRpcUpdateError = function ()
    logd('mp[%d]: onRpcUpdateError maxRetry=%d', mp.id, maxRetry)
    mp.allowSend = true
    unscheduleRetry()
    if maxRetry > 0 then
      logd('mp[%d]: schedule retry update maxRetry=%d...', mp.id, maxRetry)
      retryHandle = scheduler.performWithDelay(2.0, tryUpdate, false)
      maxRetry = maxRetry - 1
    else
      restartGame()
    end
  end

  local onRpcUpdate = function (msg)
    -- NOTE on allowSend
    -- when update was sent, and return message is still on the way,
    -- no other messages should be send to the server, because the server
    -- may have changed its nonce at any time in between. Messages sent
    -- during this period may be rejected by the server, and the connection
    -- will be closed.
    mp.allowSend = true
    mp:signal('cancelled'):clear()
    unscheduleRetry()

    if msg.success == false then
      -- something wrong in the server
      onRpcUpdateError()
    elseif (msg.url and msg.client_version and (not game.skipUpdate) and
      string.len(msg.url) > 0 and string.len(msg.client_version) > 0) or
      (msg.pkg_url and msg.pkg_version and
      string.len(msg.pkg_url) > 0 and string.len(msg.pkg_version) > 0) then
      -- got an update, restart game
      logd('mp[%d]: got update, reinit game......', mp.id)
      reinitGame()
      logd('mp[%d]: game reinit done.', mp.id)
    else
      -- no update received, try login
      tryRelogin()
    end
  end

  tryUpdate = function ()
    logd('mp[%d]: try update...', mp.id)
    unscheduleRetry()
    maxRetry = 999

    mp:signal('cancelled'):clear()
    mp:signal('cancelled'):addOnce(onRpcUpdateError)
    md:rpcUpdate(onRpcUpdate)
    mp.allowSend = false
  end

  ---------------------------------------------------
  -- start by try update
  ---------------------------------------------------

  local view = ui:curViewName()
  logd('mp[%d]: handleReconnect view=%s', mp.id, tostring(view))
  if view == 'UpdatingScene' or view == 'DebugServerScene' then
    logd("mp[%d]: check updates again", mp.id)
    tryUpdate()
  else
    logd("mp[%d]: check if there are new updates", mp.id)
    tryUpdate()
  end
end

function m.onReconnectInitDone()
  if md and type(md.onReconnectSuccess) == 'function' then
    logd('mp[%d]: calling md:onReconnectSuccess()', mp.id)
    md:onReconnectSuccess()
  else
    logd('mp[%d]: skip calling md:onReconnectSuccess(): model was not inited', mp.id)
  end

  if pm and type(pm.onReconnectSuccess) == 'function' then
    logd('mp[%d]: calling pm:onReconnectSuccess()', mp.id)
    pm:onReconnectSuccess()
  end

  mp:signal('ReconnectHandler_done'):fire()
end

-------------------------------------------------------------------------
-- Overridding View related part of MsgEndpoint (MsgEndpointView.lua)
-------------------------------------------------------------------------

--------------------------------------------------------
-- display a view to indicate the game is reconnecting
function MsgEndpoint:showReconnecting()
  -- user should typing address and port in develop mode
  if game.mode=='production'then
    self:showBusy()
  end
end

-- hide game reconnecting view
function MsgEndpoint:hideReconnecting()
  self:hideBusy()
end

-- check if reconnect view is shown at the moment
function MsgEndpoint:isReconnectingShown()
  return self:isBusyShown()
end

--------------------------------------------------------
-- display a view to indicate the game is in busy status (where no message should be sent)
function MsgEndpoint:showBusy(forceMpBusy)
  -- loge('showBusy %s', debug.traceback())
  engine.beginSample('showBusy')

  local sceneName = unity.getActiveSceneName()
  if sceneName == 'EntryPoint' then
    logd('in EntryPoint, skip showBusy')
    engine.endSample()
    return
  end

  if not self.busyView then
    self.busyView = ViewFactory.make('BusyView')
  end

  if not self.busyView then
    engine.endSample()
    return
  end
  local cc = rawget(_G, 'cc')
  if cc and not self.busyView.destroyed then 
    self.busyView:hide()
  elseif not self.busyView.destroyed then
    self.busyView:show()
  end

  self.forceMpBusy = forceMpBusy

  engine.endSample()
end

-- hide game busy view
function MsgEndpoint:hideBusy()
  -- loge('hideBusy %s', debug.traceback())
  engine.beginSample('hideBusy')

  self.forceMpBusy = nil
  if self.busyView and not self.busyView.destroyed then
    self.busyView:hide()
  end
  self.busyView = nil

  engine.endSample()
end

-- check if busy view is shown at the moment
function MsgEndpoint:isBusyShown()
  return (self.busyView ~= nil)
end

--------------------------------------------------------------------------
-- display a view for user to confirm to reconnect, or reconnect directly
function MsgEndpoint:showConfirmReconnect(onOk, onCancel)
  local sceneName = unity.getActiveSceneName()
  local curViewName = ui:curViewName()
  logd('mp[%d]: show confirm reconnect sceneName=%s curViewName=%s', self.id,
    tostring(sceneName), tostring(curViewName))

  if sceneName == 'EntryPoint' then
    logd('in EntryPoint, tryReconnect...')
    self:tryReconnect()
    return
  end

  if curViewName == 'DebugServerScene' then
    -- do not block user input to change server
    self:tryReconnect()
    return
  end

  -- if curViewName == 'UpdatingScene' then
  --   -- no need to confirm, just try reconnect
  --   -- this is a better experience than a confirm popup when player enters fresh game
  --   self:tryReconnect()
  --   return
  -- end

  if not self.confirmView then
    require 'game/login/ConfirmReconnectPopup'
    self.confirmView = ConfirmReconnectPopup.new({
      onOk = onOk,
      onCancel = onCancel,
      onClosed = function () self.confirmView = nil end,
    })
    -- remove loading so that confirm popup can be seen
    if ui.loading then ui:removeLoading() end
    ui:push(self.confirmView)
  end
end

-- hide game reconnect confirm view
function MsgEndpoint:hideConfirmReconnect()
  if self.confirmView then
    ui:remove(self.confirmView)
    self.confirmView = nil
  end
end

-- check if reconnect confirm view is shown at the moment
function MsgEndpoint:isConfirmReconnectShown()
  return (self.confirmView ~= nil)
end
