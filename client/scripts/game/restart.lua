-- restart.lua

return function (options, onComplete)
  local opts = table.merge({
    toTitle = false,   -- if true, return to title, else return to login view
    initGame = false,  -- if true, init game again
    sdkLogin = false, -- if true, auto pop up sdk login dialog
    loadConfig = true, -- if false, do not load config
    toLogin = true,
  }, options)


  scheduler.performWithDelay(0, function ()

    local ui = rawget(_G, 'ui')
    if ui and ui.loading then
      if ui.loading.loadingManager then
        logd('restart: stop loading now')
        ui.loading.loadingManager:stop()
      end
    end

    -- unschedule all
    scheduler.unscheduleAll()

    -- return to title or login view
    if opts.toTitle then
      logd('======   return to Title   ======')
      xpcall(__main, __G__TRACKBACK__)
      logd('======   return to Title done  ======')
    else
      logd('======   return to Login   ======')

      if opts.initGame then
        logd('$$$ trying to initGame...')
        local initGameOpts = table.merge({
          showReconnectMask = false,
        }, opts)
        local initGame = (require 'game/initGame')['initGame']
        local status, err = pcall(function () initGame(initGameOpts) end)
        if status then
          logd('$$$ initGame success!')
        else
          logd('$$$ initGame failed: %s', tostring(err))
          loge(debug.traceback())
        end
        mp.options.showReconnectMask = true
      end

      if opts.playMusic then
        --sm:playEarlyLoginTheme({instant = true})
      end

      if opts.toLogin then
        ui:goto(LoginView.new())
      end
    end

    scheduler.performWithDelay(0, function ()
      -- purge cache
      logd('trying to purge cached data...')
      logd('purge cache done.')
    end)

    if type(onComplete) == 'function' then
      logd('restart complete: calling onComplete()')
      onComplete()
    end

  end, false)
end
