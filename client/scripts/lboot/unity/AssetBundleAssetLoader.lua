class('AssetBundleAssetLoader', function(self, bundlePath, ttl)
  self.ttl = ttl
  self.bundlePath = bundlePath
  self:init()
end)

local m = AssetBundleAssetLoader

function m:init()
  self.signals = {}
  self.requests = {}
  self.loadingAssets = {}
  self.loadedAssets = {}
end

function m:clear()
  for _, v in pairs(self.signals) do
    v:clear()
  end

  table.clear(self.loadedAssets)
  table.clear(self.requests)
  table.clear(self.signals)

  -- do not clear the loadingAssets and
  -- do not set loading to nil and
  -- do not unschedule the coroutine
  -- let it run its course and stops itself
end

function m:forceClear()
  self:clear()
  table.clear(self.loadingAssets)
  self.loading = nil
  if self.handle then
    scheduler.unschedule(self.handle)
    self.handle = nil
  end
  unity.releaseAsyncLock(self.bundlePath)
end

function m:addOnce(assetPath, onComplete)
  local signal = self.signals[assetPath] or Signal.new()
  self.signals[assetPath] = signal
  table.insert(self.requests, assetPath)
  signal:addOnce(onComplete)
end

function m:load(assetPath)
  if not_null(self.loadedAssets[assetPath]) then
    return self.loadedAssets[assetPath]
  end
  logd(">>>>>[bundle] assetPath:%s", tostring(assetPath))
  logd(">>>>>[bundle] self.bundlePath:%s", tostring(self.bundlePath))
  local bundle = unity.loadBundleWithDependencies(self.bundlePath, self.ttl)
  if bundle then
    local asset = bundle:LoadAsset(assetPath)
    self.loadedAssets[assetPath] = asset
    return asset
  else
    loge('AssetBundleAssetLoader.load: Fail to load bundle %s', self.bundlePath)
    return nil
  end
end

function m:loadAsync(assetPath, onComplete)
  if not_null(self.loadedAssets[assetPath]) then
    onComplete(self.loadedAssets[assetPath])
    return
  end

  self:addOnce(assetPath, onComplete)
  -- logd("[load] assetPath:%s  self.loading:%s", inspect(assetPath), inspect(self.loading))
  if not self.loading then
    self.loading = true
    unity.loadBundleWithDependenciesAsync(self.bundlePath, function(bundle)
      -- mix using LoadAsset and LoadAssetAsync
      -- ensure there is always only one async loading in progress

      if unity.acquireAsyncLock(self.bundlePath) then
        self:fireAllAsync(bundle)
      else
        self:fireAll(bundle)
      end
    end, self.ttl)
  end
end

function m:fireAll(bundle)
  local signals = self.signals
  local requests = self.requests
  local loadedAssets = self.loadedAssets

  while #requests > 0 do
    local assetPath = table.shift(requests)
    local signal = signals[assetPath]
    local asset = loadedAssets[assetPath]
    if is_null(asset) then
      asset = bundle:LoadAsset(assetPath)
    end
    loadedAssets[assetPath] = asset
    if signal then signal:fire(asset) end
  end
  self.loading = nil
end

function m:fireAllAsync(bundle)
  local signals = self.signals
  local requests = self.requests
  local loadedAssets = self.loadedAssets
  local loadingAssets = self.loadingAssets

  self.handle = coroutineStart(function()
    local assetsToFire = {}
    while #requests > 0 and self.loading do
      local assetPath = table.shift(requests)
      local signal = signals[assetPath]
      if not_null(loadedAssets[assetPath]) then
        -- local asset = loadedAssets[assetPath]
        assetsToFire[#assetsToFire + 1] = assetPath
        -- if signal then signal:fire(asset) end
      elseif not loadingAssets[assetPath] then
        loadingAssets[assetPath] = true
        local req = bundle:LoadAssetAsync(assetPath)
        while not req:get_isDone() and self.loading do
          coroutine.yield()
        end

        if req:get_isDone() then
          local asset = req:get_asset()
          loadedAssets[assetPath] = asset
          assetsToFire[#assetsToFire + 1] = assetPath
        end
        loadingAssets[assetPath] = nil
      end
    end

    unity.releaseAsyncLock(self.bundlePath)

    self.loading = nil
    self.handle = nil

    for i = 1, #assetsToFire do
      local assetPath = assetsToFire[i]
      local signal = signals[assetPath]
      local asset = loadedAssets[assetPath]
      if signal then signal:fire(asset) end
    end

  end, 0, {global = true})

end
