
local Pool = Pool
local Time = UnityEngine.Time
local unity = unity
local xt = require 'xt'

class('GameHelperReloader', function (self)
end)

function GameHelperReloader.onClassReloaded(_cls)
  frameManage()
  -- testMemory(999)
end

declare('gameAssert', function(o, errorMsg)
  if not o then loge(errorMsg) end
  return o
end)

declare('optimizeRenderer', function(renderer, materials)
  if renderer:get_motionVectors() then
    renderer:set_receiveShadows(false)
    renderer:set_shadowCastingMode(0)
    renderer:set_reflectionProbeUsage(0)
    renderer:set_lightProbeUsage(0)
    renderer:set_motionVectors(false)

    if materials then
      renderer:set_sharedMaterials(materials)
    end
  end
end)

local OCLASS_SDK_FV = 'LuaSDKFirevale'

declare('hideKeyboard', function()
  if game.platform == 'ios' then
    -- local ok, ret = luaoc.callStaticMethod(OCLASS_SDK_FV, 'hideKeyboard', {})
    return true
  end
end)

declare('reportGameData', function(reportType)
  if game.sdk == 'standard' then
    -- logd('reportGameData %s', reportType)
    return
  end
  --SDKFirevale.reportGameData(reportType)
end)

declare('resetUnityTimeScale', function(rate)
  rate = rate or 1
  Time.timeScale = rate
  Time.fixedDeltaTime = 0.02 * rate;
end)

-- test Unity Profiler Others - Objects memory
declare('testMemory', function (t)
  logd('testMemory t=%s', tostring(t))
  if t == 1 then
    logd('loading fighters')
    -- local bundle = 'prefab/characters/daoshi001_rda001'
    local bundle = 'prefab/characters/huyao001_rda021'
    for i = 1, 1000 do
      gp:createAsync(bundle, function(go)
        logd('go=%s', tostring(go))
        Destroy(go)
        -- if i == 1000 then gp:purgePrefabs(true) end
      end)
    end
  elseif t == 2 then
    logd('loading fighters')
    for i = 1, 1000 do
      local bundle = unity.loadBundle('prefab/characters/daoshi001', 10)
      local asset = bundle:LoadAsset('daoshi001_rda001')
      logd('asset=%s', tostring(asset))
      local go = GameObject.Instantiate(asset)
      logd('go=%s', tostring(go))
      Destroy(go)
    end
  elseif t == 3 then
    logd('clearing game objects')
    for i = 1, 1000 do
      local go = GameObject.Find('/daoshi001_rda001(Clone)')
      logd('go=%s', tostring(go))
      if go then Destroy(go) end
    end
  elseif t == 4 then
    logd('loading sprites')
    for i = 1, 1000 do
      local ss = unity.loadSpriteAsset('images/news/news')
      Destroy(ss)
    end
  elseif t == 5 then
    logd('loading animations')
    for i = 1, 1000 do
      local bundle = unity.loadBundle('model/animations/daoshi001', 10)
      local asset = bundle:LoadAsset('daoshi001_atk_kic01')
      logd('asset=%s', tostring(asset))
      if asset then
        local go = GameObject.Instantiate(asset)
        logd('go=%s', tostring(go))
        if go then Destroy(go) end
      end
    end
  elseif t == 6 then
    logd('loading meshes')
    for i = 1, 1000 do
      local bundle = unity.loadBundle('model/characters/daoshi001', 10)
      local asset = bundle:LoadAsset('daoshi001_eyewear_rda001')
      logd('asset=%s', tostring(asset))
      if asset then
        local go = GameObject.Instantiate(asset)
        logd('go=%s', tostring(go))
        if go then Destroy(go) end
      end
    end
  elseif t == 7 then
    logd('loading materials')
    for i = 1, 1000 do
      local bundle = unity.loadBundle('model/characters/daoshi001', 10)
      local asset = bundle:LoadAsset('daoshi001_rda001_face')
      logd('asset=%s', tostring(asset))
      if asset then
        local go = GameObject.Instantiate(asset)
        logd('go=%s', tostring(go))
        if go then Destroy(go) end
      end
    end
  elseif t == 999 then
    logd('unloading unused')
    Resources.UnloadUnusedAssets()
  end
end)

-- synchronized time with server
declare('stime', function ()
  return ServerTime.time()
end)

declare('mpSendMsg', function(t, msg, onComplete, opts)
  mp:sendMsg(t, msg, onComplete, opts)
end)

-- This is used for return to LoginView at abnormal situations (usually when something wrong happened)
-- For normal process go to login, use goto directly
declare('returnToLogin', function (onComplete)
  local ui = rawget(_G, 'ui')

  local gotoLogin = function ()
    local view = LoginView.new()
    ui:goto(view)
    -- delay some time to avoid onComplete visual missed when low frame rate
    if onComplete then
      scheduler.performWithDelay(1.5, function ()
        onComplete(view)
      end)
    end
  end

  if not ui then
    logd('returnToLogin: no ui yet, go to login')
    gotoLogin()
    return
  end

  if ui.loading then
    if ui.loading.loadingManager then
      logd('returnToLogin: stop loading now')
      ui.loading.loadingManager:stop()
    end

    -- remove loading so that LoginView can be seen
    logd('returnToLogin: remove loading now')
    ui:removeLoading()
  end

  local curViewName = ui:curViewName()
  if curViewName == 'LoginView' or curViewName == 'UpdatingScene' then
    logd('returnToLogin: no need to go to login')
    if onComplete then
      onComplete(nil)
    end
  else
    logd('returnToLogin: success, go to login')
    Util.exitGameCleanup()
    gotoLogin()
  end
end)

-- lighter inspect, with default depth 3
declare('peek', function(t, depth)
  if game.mode == 'production' then return '' end

  depth = depth or 3
  return inspect.inspect(t, { depth = depth })
end)

declare('hexToColor', function(hex)
  return unity.hexToColor(hex)
end)

declare('createParticle', function(opts)
  if opts.tid then
    local efxType = cfg:efxAsset(opts.tid)
    local go = gp:create(BundleUtil.getEffectBundleFile(efxType.asset))
    return go, efxType
  elseif opts.name then
    local go = gp:create(BundleUtil.getEffectBundleFile(opts.name))
    return go
  end
end)

declare('createParticleAsync', function(opts, onComplete)
  local path = opts.path or 'prefab/misc/'
  if opts.tid then
    local efxType = cfg:efxAsset(opts.tid)
    gp:createAsync(path..efxType.asset, onComplete)
  elseif opts.name then
    gp:createAsync(path..opts.name, onComplete)
  end
end)

declare('peekFunction', function (f, level)
  local info = (type(f) == 'function' and peek(debug.getinfo(f, 'S')) or type(f))
  logd('peekFunction[%s]: info=%s', tostring(f), info)
  peekUpvalues(f, level)
end)

declare('peekUpvalues', function (f, level)
  level = level or 1
  if level > 5 then
    -- logd('peekUpvalues[%s]: level=%d (too deep)', tostring(f), level)
    return
  end

  local t = type(f)
  if t == 'function' then
    local i = 1
    local name, value = 1, 1
    while name do
      name, value = debug.getupvalue(f, i)
      if name and value then
        logd('peekUpvalues[%s]: level=%d i=%d name=%s value=%s-%s',
          tostring(f), level, i, tostring(name), tostring(value), peek(value))
        peekFunction(value, level + 1)
      end
      i = i + 1
    end
  elseif t == 'table' then
    logd('peekUpvalues[%s]: level=%d', tostring(f), level)
    for k, v in pairs(f) do
      peekUpvalues(v, level + 1)
    end
  end
end)

declare('peekAllRegistryItems', function ()
  local total = 0
  local reg = debug.getregistry()
  for k, v in pairs(reg) do
    local ok, valueStr = pcall(tostring, v)
    logd('peekAllRegistryItems: k=%s v=%s', tostring(k), valueStr)
    -- peekRegistryItem(k, v)
    total = total + 1
  end
  logd('peekAllRegistryItems: total=%d', total)
end)

declare('peekRegistryItem', function (key, item)
  local keyStr = tostring(key)
  if not item then
    local reg = debug.getregistry()
    item = reg[key]
  end
  logd('peekRegistryItem[%s]: content=%s', keyStr, peek(item))
  if type(item) == 'function' then
    logd('peekRegistryItem[%s]: info=%s', keyStr, peek(debug.getinfo(item, 'S')))
    peekUpvalues(item)
  elseif type(item) == 'table' then
    logd('peekRegistryItem[%s]: id=%s', keyStr, tostring(item.id))
    if item.gameObject then
      logd('peekRegistryItem[%s]: gameObject=%s', keyStr, tostring(item.gameObject.name))
    end
  end
  return item
end)

declare('peekSchedulerData', function (onlyGlobal)
  for _, key in ipairs({'updateClocks', 'fixedUpdateClocks', 'lateUpdateClocks', 'finalUpdateClocks'}) do
    logd('peekSchedulerData: key=%s', key)
    local clocks = _G.schedulerData[key]
    for i = 1, #clocks do
      local clock = clocks[i]
      if onlyGlobal and clock.global then
        logd('peekSchedulerData: i=%d clock=%s', i, peek(clock))
        logd('peekSchedulerData: info=%s', peek(debug.getinfo(clock.func, 'S')))
      end
    end
  end
end)

declare('peekAllComponents', function (compType)
  local rcs = unity.Object.FindObjectsOfType(compType)
  for i = 1, #rcs do
    local comp = rcs[i]
    logd('peekAllComponents: i=%d enabled=%s comp=%s',
      i, tostring(comp:get_enabled()), tostring(comp))
  end
end)
-- peekAllComponents(UI.GraphicRaycaster)

declare('printMonoMemory', function (object)
  local Profiler = UnityEngine.Profiler
  logd('printMonoMemory: ')
  logd('usedHeapSize=%d', Profiler.usedHeapSize)
  logd('GetMonoHeapSize=%d', Profiler:GetMonoHeapSize())
  logd('GetMonoUsedSize=%d', Profiler:GetMonoUsedSize())
  logd('GetTotalAllocatedMemory=%d', Profiler:GetTotalAllocatedMemory())
  logd('GetTotalReservedMemory=%d', Profiler:GetTotalReservedMemory())
  logd('GetTotalUnusedReservedMemory=%d', Profiler:GetTotalUnusedReservedMemory())
  if object then
    logd('GetRuntimeMemorySize=%d', Profiler:GetRuntimeMemorySize(object))
  end
end)


-- clear references, prepare for a throrough garbage collection
declare('prepareForFullGC', function ()
  -- logd('invoke prepareForFullGC' .. debug.traceback())
  unity.beginSample('prepareForFullGC')

  Go.destroyAll()

  -- FloatingTextList.setInstance(nil)
  -- FloatingIconTextList.setInstance(nil)

  scheduler.clearPools()
  md:resetSignals()

  unity.endSample()
end)

declare('luagc', function ()
  unity.beginSample('luagc')

  -- Free up as much memory as possible by purging cached data objects
  -- that can be recreated (or reloaded from disk) later.
  local used = tonumber(collectgarbage("count"))
  logwarn(string.format("[LUA] MEMORY USED: %0.2f KB", used))

  collectgarbage("collect")

  used = tonumber(collectgarbage("count"))
  logwarn(string.format("[LUA] MEMORY USED: %0.2f KB", used))

  unity.endSample()
end)


-- Mono garbage collector tends to run sparingly,
-- the managed heap expands quickly if too much memory is allocated.
-- Doing manual mono gc strategically mitigates the heap expansion, thus reduce RSS usage.
local lastMonoGCWithIntervalTime = 0
declare('monoGCWithInterval', function (interval)
  if not QualityUtil.isMemoryTight() then return end

  interval = interval or 2.0
  local now = Time:get_realtimeSinceStartup()
  if now - lastMonoGCWithIntervalTime > interval then
    monoGC()
    lastMonoGCWithIntervalTime = now
  end
end)

declare('monoGC', function ()
  unity.beginSample('monoGC')

  local used = LBoot.LuaUtils.GetTotalMemory() / 1024
  logwarn(string.format("[LUA] MONO MEMORY USED: %0.2f KB", used))

  LBoot.LuaUtils.GCCollect(-1)
  LBoot.LuaUtils.GCWaitForPendingFinalizers()

  local used = LBoot.LuaUtils.GetTotalMemory() / 1024
  logwarn(string.format("[LUA] MONO MEMORY USED: %0.2f KB", used))

  unity.endSample()
end)

declare('fullGC', function (everything, opts)
  unity.beginSample('fullGC')

  opts = opts or {}

  logd('performing full GC everything=%s', tostring(everything))
  if everything then
    -- this clears all references, should only be used when loading
    prepareForFullGC()
  end

  luagc()
  monoGC()

  if not everything then
    unity.unloadAllUnusedAssetsAsync(opts.onComplete)
  else
    -- wait until next frame, when all rendering and animation stops
    logd('before force unload bundles...')
    scheduler.performWithDelay(0, function ()
      logd('force unload bundles...')
      forceUnloadBundles(opts.keepBundlesList)
      if opts.onComplete then
        unity.unloadAllUnusedAssetsAsync(opts.onComplete)
        -- opts.onComplete()
      end
    end)
  end

  unity.endSample()
end)

declare('getLastCrashReport', function ()
  if not unity.CrashReport then
    return 'crash report not supported'
  end

  local report = unity.CrashReport.lastReport
  if report and report:get_text() then
    return report:get_text()
  else
    return 'no crash report'
  end
end)

declare('cleanupDanglingAssets', function()
  if not game.shouldLoadAssetInEditor() then
    local animControllers = unity.Resources.FindObjectsOfTypeAll(unity.RuntimeAnimatorController)
    for i = 1, #animControllers do
      local v = unity.as(animControllers[i], unity.RuntimeAnimatorController)
      local name = v:get_name()
      if name:match('^female') or name:match('^male') then
        unity.Resources.UnloadAsset(v)
      end
    end

    local animClips = unity.Resources.FindObjectsOfTypeAll(unity.AnimationClip)
    for i = 1, #animClips do
      local v = animClips[i]
      unity.Resources.UnloadAsset(v)
    end

    local textures = unity.Resources.FindObjectsOfTypeAll(unity.Texture)
    for i = 1, #textures do
      local v = unity.as(textures[i], unity.Texture)
      local name = v:get_name()
      if name:match('^female') or name:match('^male') then
        unity.Resources.UnloadAsset(v)
      end
    end

    local meshes = unity.Resources.FindObjectsOfTypeAll(unity.Mesh)
    for i = 1, #meshes do
      local v = meshes[i]
      local name = v:get_name()
      if name == '' then
      elseif name == 'TextMesh' then
      elseif name == 'Shared UI Mesh' then
      elseif name:match('^male') or name:match('^female') then
        unity.Resources.UnloadAsset(v)
      end
    end
  end
end)

-- It's hard to find all memory leaks and fix them
-- Instead, just ensure all scene and character assets are unloaded fully when scene switch
declare('forceUnloadBundles', function (keepBundlesList)
  unity.beginSample('forceUnloadBundles')

  local BundleManager = LBoot.BundleManager
  local bundleUris = BundleManager.ListAssetBundleUris:ToArray().Table

  for i = 1, #bundleUris do
    local uri = bundleUris[i]
    local unload, unloadAssets = LoadingHelper.isForceUnloadBundle(uri, keepBundlesList)
    if unload then
      logd('unload bundle %s unloadAssets=%s', uri, tostring(unloadAssets))
      unity.unloadBundle(uri, unloadAssets)
    end
  end

  -- ss:unloadSheet('images/ui/creation')
  -- ss:unloadSheet('images/icons/creation_portrait')

  -- if not game.shouldLoadAssetInEditor() then
  --   local animControllers = unity.Resources.FindObjectsOfTypeAll(unity.RuntimeAnimatorController)
  --   for i = 1, #animControllers do
  --     local v = unity.as(animControllers[i], unity.RuntimeAnimatorController)
  --     local name = v:get_name()
  --     if name:match('^female') or name:match('^male') then
  --       unity.Resources.UnloadAsset(v)
  --     end
  --   end
  -- end

  --   -- local prefabs = unity.Resources.FindObjectsOfTypeAll(unity.GameObject)
  --   -- for i = 1, #prefabs do
  --   --   local v = prefabs[i]
  --   --   local name = v:get_name()
  --   --   if name:match('^female') or name:match('^male') then
  --   --     unity.Resources.UnloadAsset(v)
  --   --   end
  --   -- end

  --   local animClips = unity.Resources.FindObjectsOfTypeAll(unity.AnimationClip)
  --   for i = 1, #animClips do
  --     local v = animClips[i]
  --     unity.Resources.UnloadAsset(v)
  --   end

  --   local textures = unity.Resources.FindObjectsOfTypeAll(unity.Texture)
  --   for i = 1, #textures do
  --     local v = textures[i]
  --     local name = v:get_name()
  --     if name:match('^female') or name:match('^male') then
  --       unity.Resources.UnloadAsset(v)
  --     end
  --   end

  --   local meshes = unity.Resources.FindObjectsOfTypeAll(unity.Mesh)
  --   for i = 1, #meshes do
  --     local v = meshes[i]
  --     local name = v:get_name()
  --     if name == '' then
  --     elseif name == 'TextMesh' then
  --     elseif name == 'Shared UI Mesh' then
  --     elseif name:match('^male') or name:match('^female') then
  --       unity.Resources.UnloadAsset(v)
  --     end
  --   end

  -- end

  if unity.sceneAssets then
    for k, asset in pairs(unity.sceneAssets) do
      unity.Resources.UnloadAsset(asset)
    end
    table.clear(unity.sceneAssets)
  end

  unity.endSample()
end)

local cmsgpackpack = cmsgpack.pack
local cmsgpackunpack = cmsgpack.unpack

declare('deepCopy', function(t)
  local json = cmsgpackpack(t)
  return cmsgpackunpack(json)
end)

declare('testReconnect', function ()
  mp:close()
  mp:showConfirmReconnect()
  mp:hideBusy()
end)

declare('adjustTextRect', function (txt)
  local rcTran = txt.gameObject:GetComponent(RectTransform)
  rcTran.transform:set_anchoredPosition(Vector2(rcTran.transform:get_anchoredPosition()[1], 0))
  if txt.textField then
    rcTran:set_sizeDelta(Vector2(rcTran.rect:get_width(), txt.textField:get_preferredHeight()))
  end
  if txt.textWithIcon then
    rcTran:set_sizeDelta(Vector2(rcTran.rect:get_width(), txt.textWithIcon:get_preferredHeight()))
  end
end)

declare('fixInitScroll', function (sv, view)
  local scroll = sv
  -- logd("check scroll:"..tostring(scroll))
  if type(sv) == 'string' then
    scroll = view.transform:find(sv)
  end
  -- logd("check scroll2:"..tostring(scroll))
  local rc = scroll:GetComponent(UI.ScrollRect)
  if rc then
    scheduler.performWithDelay(0, function()
      rc:StopMovement()
    end)
  end
end)

declare('decodePid', function(pid)
  local parts = string.split(pid, '_')
  local zone, cid, iid = 0, nil, nil
  if #parts == 3 then
    zone, cid, iid = parts[1], parts[2], parts[3]
  elseif #parts == 1 then
    cid = parts[1]
  end

  return zone, cid, iid
end)


local FVAlert = LBoot.FVAlert
declare('scheduleLocalNotifications', function()
  if not FVAlert then return end

  local platform = game.platform
  local message1 = '未来赛车： 测试定时提醒功能....1'
  local message2 = '未来赛车： 测试定时提醒功能....2'
  local time1 =  math.floor(ServerTime.getTimeInHour(12))
  local time2 =  math.floor(ServerTime.getTimeInHour(18))
  local now = math.floor(stime())
  local title = '未来赛车'

  if time1 < now then
    time1 = time1 + 3600 * 24
  end

  if time2 < now then
    time2 = time2 + 3600 * 24
  end

  logd('scheduleLocalNotifications: time1=%s time2=%s now=%s',
    tostring(time1), tostring(time2), tostring(now))

  if platform == 'ios' then
    FVAlert.ClearAlerts()
    FVAlert.ScheduleAlert(message1, title, time1)
    FVAlert.ScheduleAlert(message2, title, time2)
  elseif platform == 'android' then
    OsCommon.cancelNotification(1)
    OsCommon.setRepeatingNotification(message1, title, time1, 1)
    OsCommon.cancelNotification(2)
    OsCommon.setRepeatingNotification(message2, title, time2, 2)
    -- OsCommon.cancelNotification(3)
    -- OsCommon.setRepeatingNotification(message, title, now + 30, 3)
  end
  logd('scheduleLocalNotifications: success')
end)

declare('clampScroll', function(scrollView)
    local svRect = scrollView:getComponent(UI.ScrollRect)
    local bElastic = (svRect.movementType ==  UI.ScrollRect.MovementType.Elastic)
    if bElastic then
      svRect.movementType = UI.ScrollRect.MovementType.Clamped
    end
    return bElastic
  end)

declare('fixScrollTxtMove', function(scrollView, text, bElastic, value)
  value = value or 0
  local rcSv = scrollView:getComponent(RectTransform)
  local yMax = text.textField.preferredHeight - rcSv.rect.height
  if yMax < 0 then yMax = 0 end

  local y = yMax * value
  local rcTxt = text.gameObject:getComponent(RectTransform)
  rcTxt.transform.anchoredPosition = Vector2(rcTxt.transform.anchoredPosition.x, y)
  local svRect = scrollView:getComponent(UI.ScrollRect)
  svRect:StopMovement()

  if bElastic then
    scheduler.performWithDelay(0.5, function()
      svRect.movementType = UI.ScrollRect.MovementType.Elastic
    end)
  end
end)

declare('fixScrollMove', function(scrollView, bElastic, value)
  value = value or 0
  local rcSv = scrollView.gameObject:getComponent(RectTransform)
  local goList = scrollView.transform:find("List")
  local rcList = goList:getComponent(RectTransform)
  -- logd(">>>>>>>rcList.rect.height"..inspect(rcList.rect.height))
  -- logd(">>>>>>>rcSv.rect.height"..inspect(rcSv.rect.height))
  local yMax = rcList.rect.height - rcSv.rect.height
  if yMax < 0 then yMax = 0 end

  local y = yMax * value
  --logd(">>>>>>>y"..inspect(y))
  rcList.transform:set_anchoredPosition(Vector2(rcList.transform:get_anchoredPosition()[1], y))
  local svRect = scrollView:getComponent(UI.ScrollRect)
  svRect:StopMovement()

  if bElastic then
    scheduler.performWithDelay(0.5, function()
      svRect.movementType = UI.ScrollRect.MovementType.Elastic
    end)
  end
end)

declare('decideChance', function(chance)
  if not chance then return false end
  if type(chance) ~= 'number' then return false end
  return math.random(100) < chance * 100
end)

declare('timedRun', function (f, title)
  local t1 = Time:get_realtimeSinceStartup()
  local res = f()
  local time = Time:get_realtimeSinceStartup() - t1
  logd('timedRun[%s]: %.3fms', tostring(title), time * 1000)
  return res
end)

-- yield only when a minimum time has passed
declare('smartYieldCreate', function (minSeconds)
  return {
    lastYield = Time:get_realtimeSinceStartup(),
    minSeconds = minSeconds,
    count = 0,
  }
end)

-- hot patch client code
declare('hotPatchCode', function (codeStr)
  if not codeStr then
    logd('hotPatchCode nothing to patch!')
    return
  end
  logd('gameHelper: hotPatchCode=%s', tostring(codeStr))
  local ok, ret = pcall(function ()
    local f = loadstring(codeStr)
    if type(f) == 'function' then
      return f()
    else
      return f
    end
  end)
  if ok then
    logd('gameHelper lua_script: success result=%s', peek(ret))
  else
    logd('gameHelper lua_script: failed! err=%s', tostring(ret))
  end
end)

declare('smartYield', function (yield)
  if yield then
    local now = Time:get_realtimeSinceStartup()
    local secs = now - yield.lastYield
    if secs > yield.minSeconds then
      yield.lastYield = now
      yield.count = yield.count + 1
      coroutine.yield()
    end
  end
end)

declare('recycleFixedFramePools', function()
  local pools = FixedFramePool.pools
  for i = 1, #pools do
    local pool = pools[i]
    if pool.class.classname == 'FixedFramePool' and pool.lentSize > 0 then
      pool:recycleAll()
    end
    if game.debug and pool.lentSize > pool.maxSize then
      -- logd('pool[%s]: lentSize(%d) > maxSize(%d) consider increasing maxSize?',
      --   pool.tag, pool.lentSize, pool.maxSize)
    end
  end
end)

declare('recycleFramePools', function ()
  local pools = FramePool.pools
  for i = 1, #pools do
    local pool = pools[i]
    if pool.class.classname == 'FramePool' and pool.lentSize > 0 then
      pool:recycleAll()
    end
    if game.debug and pool.lentSize > pool.maxSize then
      -- logd('pool[%s]: lentSize(%d) > maxSize(%d) consider increasing maxSize?',
      --   pool.tag, pool.lentSize, pool.maxSize)
    end
  end
  -- ActionFactory.releaseFrameActions()
end)

declare('printBundleLoadHint', function ()
  -- help to find out bundles that should be staying in memory instead of unloaded
  local histories = unity.getLoadAfterUnloadHistories()
  for history in Slua.iter(histories) do
    logw('Bundle: %s load after unload %f secs', history.uri,
      history.loadTimes[1] - history.unloadTimes[1])
    unity.clearBundleLoadHistory(history.uri)
  end
end)

local maxGCMilliSecond, maxGCStep = 1.200, 20

declare('frameGC', function ()
  local gcTime = math.floor(math.min(math.abs(
    game.frameTime - game.lastFrameScriptTime - 8.000), maxGCMilliSecond) * 1000)

  if gcTime > 0 then
    game.lastFrameGCSteps, game.lastFrameGCSize = xt.gc_step_for(gcTime, maxGCStep)
  else
    game.lastFrameGCSteps = 0
    game.lastFrameGCSize = 0
  end
end)

declare('frameManage', function ()
  if game.frameManageHandle1 then
    scheduler.unschedule(game.frameManageHandle1)
  end
  if game.frameManageHandle2 then
    scheduler.unschedule(game.frameManageHandle2)
  end

  local realtimeSinceStartup     = Time:get_realtimeSinceStartup()
  local lastFinalUpdateTime      = realtimeSinceStartup
  -- local frameStartTime           = realtimeSinceStartup
  local lastMonoMemUsage         = LBoot.LuaUtils.GetTotalMemory()
  local lastLuaMemUsage          = tonumber(collectgarbage("count"))
  local lastUnloadDeadBundleTime = realtimeSinceStartup
  local lastPrintMpStatsTime     = realtimeSinceStartup

  -- game.frameManageHandle1 = scheduler.scheduleWithUpdate(function ()
  --   frameStartTime = Time:get_realtimeSinceStartup()
  -- end, 0, false, true, -1, 1)

  game.frameManageHandle2 = scheduler.scheduleWithFinalUpdate(function ()
    unity.beginSample('frameManage')

    InputSource.clearInputs()

    recycleFramePools()

    local now = Time:get_realtimeSinceStartup()
    if now - lastUnloadDeadBundleTime > 0.5 then
      unity.unloadDeadBundles(1)
      lastUnloadDeadBundleTime = now

      -- if game.debug > 0 then
      --   printBundleLoadHint()
      -- end
    end

    game.lastFrameTime = (now - lastFinalUpdateTime) * 1000
    lastFinalUpdateTime = now

    if game.globalsDefined then
      mp:sampleFrameTime(game.lastFrameTime)
    end

    if game.debug > 0 then
      game.frameCount = (game.frameCount or 0) + 1
      game.lastFrameScriptTime = scheduler.lastFrameScriptTime() * 1000
      game.monoMemUsage = LBoot.LuaUtils.GetTotalMemory()
      game.monoMemRate = (game.monoMemUsage - lastMonoMemUsage) / game.lastFrameTime
      game.luaMemUsage = tonumber(collectgarbage("count"))
      game.luaMemRate = (game.luaMemUsage - lastLuaMemUsage) * 1024 / game.lastFrameTime
      lastMonoMemUsage = game.monoMemUsage
      lastLuaMemUsage = game.luaMemUsage

      if now - lastPrintMpStatsTime > 800 then
        mp:printStats()
        lastPrintMpStatsTime = now
      end
    end

    frameGC()

    unity.endSample()
  end, 0, false, true)
end)

