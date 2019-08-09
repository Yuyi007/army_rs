-- delegate.lua

declare('didEnterBackground', function ()
  logd('didEnterBackground, set game.appInForeground = false, game.keepConnection is %s', tostring(game.keepConnection))

  game.appInForeground = false

  local cfg = rawget(_G, 'cfg')

  if cfg then
    -- scheduleLocalNotifications()
    -- GuildUtil.showDungeonNotification()
  end

  if sm and type(sm.onEnterBackground) == 'function' then
    sm:onEnterBackground()
  end

  if mp and type(mp.onEnterBackground) == 'function' and not game.keepConnection then
    logd('calling msgEndPoint: onEnterBackground, will disconnect from server')
    mp:onEnterBackground()
  end

  if md and type(md.onEnterBackground) == 'function' and not game.keepConnection then
    md:onEnterBackground()
  end

  if um and type(um.onEnterBackground) == 'function' then
    um:onEnterBackground()
  end

  local cc = rawget(_G, 'cc')

  if cc and type(cc.onEnterBackground) == 'function' and cc:isInited() then
    cc:onEnterBackground()
  end
end)

declare('willEnterForeground', function ()
  logd('willEnterForeground, set game.appInForeground = true, game.keepConnection is %s', tostring(game.keepConnection))
  if game.appNeedForceUpdate then
    game.appInForeground = true
    return
  end

  if sm and type(sm.onEnterForeground) == 'function' then
    sm:onEnterForeground()
  end

  if mp and type(mp.onEnterForeground) == 'function' and not game.keepConnection then
    logd('calling msgEndPoint: onEnterForeground, will rebuild connection to server')
    mp:onEnterForeground()
  end

  if md and type(md.onEnterForeground) == 'function' then
    md:onEnterForeground()
  end

  if um and type(um.onEnterForeground) == 'function' then
    um:onEnterForeground()
  end

  local cc = rawget(_G, 'cc')

  if cc and type(cc.onEnterForeground) == 'function' and cc:isInited() then
    cc:onEnterForeground()
  end

  game.appInForeground = true

  -- fix gionee payment no callback (dialog disappear) when game resume
  if game.platform == 'android' and game.lockKeepConnection then
    logd('reset lockKeepConnection !!!!!')
    game.lockKeepConnection = nil
  end

  keepConnectionEnd()

  scheduler.performWithDelay(0, function ()
    game.sigEnterForeground:fire()
  end)
end)

declare('applicationWillTerminate', function ()
  logd('applicationWillTerminate')
  game.terminating = true
  mp:close()

  local cc = rawget(_G, 'cc')
  if cc then cc:exit() end
  scheduler.unscheduleAll()
  SqliteConfigFile.closeAll()
  -- if game.editor() then
  --   cleanupDanglingAssets()
  --   fullGC()
  -- end

  -- CombatVerify.exit()
end)

-----------------
-- IOS only
-----------------
declare('applicationDidReceiveMemoryWarning', function ()
  logd('applicationDidReceiveMemoryWarning')

  -- for debug only
  if game.mode == 'development' and game.debug > 0 then
    FloatingTextFactory.makeNormal{text = '内存压力大，清理内存中...'}
  end

  fullGC(false)
end)

-----------------
-- Android only
-----------------
declare('onKeyDown', function (key)
  logd('key ' .. tostring(key) .. ' pressed')

  if key == 'back' then
    local doExit = (require 'game/exit')
    local exit = function ()
      logd('exit...')
      if um and type(um.stop) == 'function' then um:stop() end
      doExit()
    end

    local sdk = game.sdk
    if sdk ~= 'standard' then
      SDKFirevale.exitGame(exit)
    else
      OsCommon.showDialog{
        title = loc('str_lua_4'),  -- title
        message = loc('str_lua_11'), -- message
        buttonOk = loc('str_lua_7'),  -- ok
        buttonCancel = loc('str_lua_12'), -- cancel
        onOk = exit,
        onCancel = function () end,
        cancelable = true,
      }
    end
  elseif key == 'menu' then
    if game.mode == 'development' then
      dumpMemoryDebugInfo()
    end
  end
end)
