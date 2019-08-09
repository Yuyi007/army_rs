
class('CachedAssetLoader', function(self, uri, cache, loadFunc, loadAsyncFunc)
  self.uri        = uri
  self.cache      = cache
  self.loading    = false
  self._load      = loadFunc
  self._loadAsync = loadAsyncFunc
  self:init()
end)

local m = CachedAssetLoader

function m:init()
  self.signal = Signal.new()
end

function m:clear()
  self.signal:clear()
  self.loading = nil
end

function m:unload()
  local cache = self.cache
  local uri = self.uri

  local asset = cache[uri]
  if is_null(asset) then return end

  -- logd('loader.unload uri=%s', tostring(uri))
  asset:Unload()

  cache[uri] = nil
end

function m:load()
  local cache = self.cache
  local uri = self.uri
  local asset = cache[uri]
  if not_null(asset) then return asset end

  asset = self._load(uri)
  cache[uri] = asset
  return asset
end

function m:loadAsync(onComplete)
  local cache = self.cache
  local uri = self.uri

  local asset = cache[uri]
  if not_null(asset) then return onComplete(asset) end

  self.signal:addOnce(onComplete)

  if not self.loading then
    self.loading = true
    self._loadAsync(uri, function(asset)
      cache[uri] = asset
      if self.signal then
        self.signal:fire(asset)
      end
      self.loading = nil
    end)
  end
end
