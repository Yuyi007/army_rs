-- preinit.lua: for Android, copy bundle from StreamingAssets to external storage

local function pushInitView(tree, onComplete)
  local loading = nil

  local loadingGo = GameObject.Find('/UIRoot/combat_loading')
  logd('pushInitView: loadingGo=%s', tostring(loadingGo))

  loading = LoadingView.new({
    tree = tree,
    bundleUI = loadingGo,
    nextView = nil,
    bg = 'update',
    startWhen = 'immediately',
    tipFunc = function ()
      return loc('str_preinit')
    end,
    onComplete = function ()
      logd('init view onComplete!')
      if loadingGo then
        loadingGo:GetComponent('Canvas'):set_enabled(false)
      else
        ui:remove(loading)
      end
      if onComplete then onComplete() end
    end,
  })

  if loadingGo then
    ui:initScaleMode()
    canvas:set_enabled(true)
  else
    ui:push(loading)
  end
end

local function copyBundles(onComplete)
  UpdateManager.clearUpdateRecords()

  local bundlesMap = {}
  local bundlesToCopy = {}
  local allBundles = cfg.all_bundles
  for _i, bundle in ipairs(allBundles) do
    if not bundlesMap[bundle] then
      bundlesMap[bundle] = true
      local bundleUri = bundle .. '.ab'
      if bundle:match('%.ab$') or bundle:match('%.ab%.') then
        bundleUri = bundle
      end
      bundlesToCopy[#bundlesToCopy + 1] = {copyBundle = bundleUri}
    end
  end

  logd('copyBundles: total=%d', #bundlesToCopy)
  local startTime = Time:get_realtimeSinceStartup()
  pushInitView(LoadingHelper.makeTreeWithAssets(bundlesToCopy), function ()
    local time = Time:get_realtimeSinceStartup()
    logd('copyBundles: finished time=%s', time - startTime)
    onComplete()
  end)
end

local function unzipOneFile(zipFiles, zipIndex, rootpath, signals, verifier, onComplete)
  logd('unzipOneFile: zipIndex=%s', zipIndex)

  local onUnzipProgress = function (index, path)
    if verifier then
      local file = string.gsub(path, '.*/bundles/', 'bundles/')
      local hash = verifier.hashVerifier:hashFile(path)
      logd('unzipBundles: zip=%s index=%s file=%s hash=%s', zipIndex, index, path, file, hash)

      verifier:onFileChanged(path, file, hash)
    end

    local file2 = string.gsub(path, '.*/bundles/', '')
    signals[file2]:fire()
  end

  local onUnzipComplete = function (success)
    logd('unzipOneFile: complete success=%s', success)

    if success or game.script ~= 'compiled' then
      onComplete(zipIndex)
    end
  end

  OsCommon.unpackZip(zipFiles[zipIndex], rootpath, onUnzipProgress, onUnzipComplete)
end

local function unzipBundles(onComplete)
  UpdateManager.clearUpdateRecords()

  local dataJson = engine.getCStringFromFile('data.json')
  if not dataJson and game.script ~= 'compiled' then onComplete() end

  local dataFiles = cjson.decode(dataJson)
  local zipFiles = {}
  local signals = {}
  local nodes = {}
  local count = 0

  for zipfile, bundleFiles in pairs(dataFiles) do
    zipFiles[#zipFiles + 1] = zipfile

    for file, size in pairs(bundleFiles) do
      count = count + 1
      signals[file] = Signal.new()
      nodes[count] = LoadRoutineNode.new({name = file, func = function (taskNode)
        local signal = signals[file]
        if signal == 'done' then
          taskNode:finish()
        else
          signal:addOnce(function ()
            -- logd('unzipBundles: file=%s finish', file)
            taskNode:finish()
          end)
        end
      end})
    end
  end

  logd('unzipBundles: zip=%d total=%d', #zipFiles, #nodes)
  local startTime = Time:get_realtimeSinceStartup()
  local rootpath = UpdateManager.rootpath() .. '/'
  mkpath(rootpath)

  local verifier = nil
  local metaJson = engine.getCStringFromFile('meta.json')
  if metaJson then
    local meta = cjson.decode(metaJson)
    verifier = CachedHashVerifier.new(meta.hasher, meta.seed)
  end

  local root = LoadBranchNode.new {name = 'root', parallel_count = count, nodes = nodes}
  pushInitView(root, onComplete)

  local oneFileComplete
  oneFileComplete = function (zipIndex)
    if zipIndex < #zipFiles then
      logd('unzipBundles: zipIndex=%s done', zipIndex)
      unzipOneFile(zipFiles, zipIndex + 1, rootpath, signals, verifier, oneFileComplete)
    else
      if verifier then
        verifier:flushCacheFile()
      end

      local time = Time:get_realtimeSinceStartup()
      logd('unzipBundles: done time=%s', time - startTime)
      for k, signal in pairs(signals) do
        signals[k]:fire()
        signals[k]:clear()
        signals[k] = 'done'
      end
    end
  end
  unzipOneFile(zipFiles, 1, rootpath, signals, verifier, oneFileComplete)
end

local function tryInitResources(onComplete)
  local versionCode = OsCommon.getVersionCode()
  local initKey = 'game-bundle-init'
  local initValue = unity.getString(initKey)
  logd('tryInitResources: versionCode=%s initValue=%s', versionCode, tostring(initValue))

  if initValue == 'true' then
    logd('tryInitResources: already inited before')
    onComplete()
  else
    unzipBundles(function ()
      unity.setString(initKey, 'true')
      onComplete()
    end)
  end
end

return function (onProgress, onComplete)
  logd('preinit...')
  -- preinit android bundles
  if game.platform == 'android' then
    -- tryInitResources(onComplete)
    onComplete()
  else
    onComplete()
  end
end
