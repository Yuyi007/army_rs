-- preload.lua: preload game assets after updating

local function preloadGameAssets(onComplete)
  LoadingView.new({
    tree = LoadingHelper.makePreloadTree(),
    nextView = nil,
    bg = 'update',
    assetsPerFrame = 5,
    mute = false,
    yield = true,
    onComplete = function() -- onComplete
      log('preload game assets done!')
      if onComplete then onComplete() end
    end
  }):__goto()
  -- sm:playMusic("bgm_001")
end

return function (view, onProgress, onComplete)
  log('preload...')

  local gp = rawget(_G, 'gp')
  if gp then gp:clearGlobal() end

  -- this will unload all current resources by force
  unity.resetBundles()

  -- clear all bundle paths caches
  BundlePathCacher.clearAll()

  -- preload game assets

  preloadGameAssets(onComplete)
end
