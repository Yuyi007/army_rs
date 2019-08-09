-- UpdateManagerVerifier.lua

--------------------------------------------
-- UpdateManager Sub Module: Hash Verifier
--------------------------------------------

class('HashVerifier', function (self, hasher, seed)
  self.hasher = hasher
  self.seed = seed
end)

function HashVerifier:verifyFile(path, file, fileInfo)
  if fileInfo.hash then
    return (self:hashFile(path) == fileInfo.hash)
  else
    return false
  end
end

function HashVerifier:verifyDownloadedFile(path, file, fileInfo)
  return self:verifyFile(path, file, fileInfo)
end

function HashVerifier:hashFile(path)
  local hash = nil
  if self.hasher == 'xxhash' then
    local x = xxhash.init(tonumber(self.seed))
    for data, length in engine.getStringFromFileIter(path) do
      x:update(data, length)
    end
    hash = tostring(x:final())
  else
    -- default to md5
    local m = md5.init()
    for data, length in engine.getStringFromFileIter(path) do
      m:update(data, length)
    end
    hash = m:final():tohex()
  end
  return hash
end

---------------------------------------------------
-- UpdateManager Sub Module: Cached Hash Verifier
---------------------------------------------------

class('CachedHashVerifier', function (self, hasher, seed)
  self.hashVerifier = HashVerifier.new(hasher, seed)
  self.hashCache = {}
  self.packageHashCache = {}

  self:init()
end)

function CachedHashVerifier.hashCachePath()
  return UpdateManager.rootpath() .. '/hash_cache.json'
end

function CachedHashVerifier.clearCache()
  os.remove(CachedHashVerifier.hashCachePath())
end

function CachedHashVerifier:flushCacheFile()
  return pcall(function ()
    local f = io.open(self.hashCachePath(), 'w+')
    f:write(cjson.encode({ files=self.hashCache }))
    f:close()
    logd('CachedHashVerifier write hash_cache.json succeeded total=' .. table.nums(self.hashCache))
  end)
end

function CachedHashVerifier:init()
  local status, err = pcall(function ()
    local str = engine.getCStringFromFile(self.hashCachePath())
    if str then self.hashCache = (cjson.decode(str).files or {}) end

    local str2 = engine.getCStringFromFile('meta.json')
    if str2 then self.packageHashCache = (cjson.decode(str2).files or {}) end

    logd('CachedHashVerifier init done')
  end)

  if not status then
    logd('CachedHashVerifier init failed: ' .. tostring(err))
    pcall(function () CachedHashVerifier.clearCache() end)
  end

  return status
end

function CachedHashVerifier:onFileChanged(path, file, hash)
  local cache = self.hashCache
  if cache then
    if hash then
      cache[file] = { hash=hash }
    else
      cache[file] = {}
    end
  end
end

function CachedHashVerifier:onUpdateComplete()
  self:flushCacheFile()
end

function CachedHashVerifier:onUpdateInterrupted()
  self:flushCacheFile()
end

function CachedHashVerifier:verifyFile(path, file, fileInfo)
  if fileInfo.hash then
    local inPackage = (path == file)
    local cache = (inPackage and self.packageHashCache or self.hashCache)
    local cacheValid = (cache and cache[file] and cache[file].hash and cache[file].hash ~= '')
    if cacheValid then
      return (cache[file].hash == fileInfo.hash)
    else
      logd('recomputing hash ' .. path)
      local hash = self.hashVerifier:hashFile(path)
      if cache then cache[file] = { hash=hash } end
      return (hash == fileInfo.hash)
    end
  else
    return false
  end
end

function CachedHashVerifier:verifyDownloadedFile(path, file, fileInfo)
  if fileInfo.hash then
    logd('recomputing hash for downloaded ' .. path)
    local hash = self.hashVerifier:hashFile(path)
    self.hashCache[file] = { hash=hash }
    return (hash == fileInfo.hash)
  else
    return false
  end
end
