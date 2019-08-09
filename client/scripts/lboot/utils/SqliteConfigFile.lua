-- SqliteConfigFile.lua

local tracemem = rawget(_G, 'TRACE_MEM')
local table, string, tostring, tonumber, type, assert = table, string, tostring, tonumber, type, assert
local cjson = cjson
local engine = engine

local sqlite3 = require('sqlite3')
local xt = require('xt')
_G.ipairs = xt.ipairs; _G.pairs = xt.pairs
if not table.getn_old then table.getn_old = table.getn end
table.getn = function(o)
  local clz = o.class
  if clz and clz.classname == 'SqliteConfigFileProxy' then
    return o.config:count()
  else
    return table.getn_old(o)
  end
end

-------------------------------------------------------------------------
-- proxy config invocations

class('SqliteConfigFileProxy', function(self, filename, cacheSize)
  local cache = nil
  cacheSize = cacheSize or 20
  if cacheSize > 0 then
    cache = LRUCache.new(cacheSize)
  end
  -- logd(">>>>>>>filename:%s",tostring(filename))
  self.config = SqliteConfigFile.new(filename, cache, Stats.new())
  self.config:open()

  self.dump = function(self)
    local t = {}
    for k,v in self.config:iter() do
      t[k] = v
    end
    return t
  end

  self.dumpAndClose = function(self)
    local t = self:dump()
    self.config:close()
    return t
  end

  setmetatable(self, {
    __index = function (_, name)
      return self.config:get(name)
    end,
    __ipairs = function (_, n)
      return self.config:iter(true)
    end,
    __pairs = function (_)
      return self.config:iter()
    end
    })
end)

-------------------------------------------------------------------------
-- sqlite config file reader

class('SqliteConfigFile', function(self, filename, cache)
  if tracemem then traceMemory('sqlite %s new', filename) end

  self.tablename = 'config'
  self.filename = filename
  self.cache = cache
  self.filepath = self:ensureFile(self.filename)

  table.insert(SqliteConfigFile.instances, self)
end)

local m = SqliteConfigFile

m.debug = nil

if not m.instances then
  m.instances = {} -- setmetatable({}, {__mode = 'v'})
end

function m.closeAll()
  local instances = m.instances
  logd('SqliteConfigFile: closing %d dbs...', #instances)
  for i = 1, #instances do
    local inst = instances[i]
    if inst and inst:isOpened() then
      logd('SqliteConfigFile: closing file %s', tostring(inst.filename))
      inst:close()
    end
    instances[i] = nil
  end
end

function m:ensureFile(file)
  if game.resourceFolder then
    -- android debug mode always use file from resourceFolder
    return game.resourceFolder .. '/' .. file
  end

  local pkgpath = engine.fullPathForFilename(file)
  local rootpath = UpdateManager.rootpath()
  local filepath = rootpath .. '/' .. file
  -- logd(">>>>>file:%s",tostring(file))
  -- logd(">>>>>filepath:%s",tostring(filepath))
  -- When set to true, search db file from update directory first
  local useUpdates = m.useUpdates
  local hasExternal = (lfs.attributes(filepath, 'mode') == 'file' and lfs.attributes(filepath, 'size') > 0)

  if useUpdates and hasExternal then
    return filepath
  elseif pkgpath then
    if lfs.attributes(pkgpath, 'mode') == 'file' then
      return pkgpath
    elseif hasExternal then
      return filepath
    else
      -- for android we can't access files in zip package using posix api
      -- FIXME copied file integrity check
      mkpath(rootpath)
      logd('SqliteConfigFile: copying %s -> %s', tostring(pkgpath), tostring(filepath))
      local res,err = pcall(function ()
        if not engine.copyFile(file, filepath) then
          logd('SqliteConfigFile: copying failed, deleting...')
          engine.deleteFile(filepath)
        end
      end)
      logd('SqliteConfigFile: copying done, result is %s err is %s', tostring(res), tostring(err))
      return filepath
    end
  else
    error(string.format('SqliteConfigFile: cannot find file %s', file))
  end
end

function m:open()
  assert(self.db == nil)
  logd("SqliteConfigFile: open %s", self.filepath)
  self.db = sqlite3.open(self.filepath)
  assert(self.db ~= nil)

  self.queryGetName = self.db:prepare('SELECT value, encoding FROM ' .. self.tablename .. ' WHERE name = ?')
  self.queryGetIdx = self.db:prepare('SELECT value, encoding FROM ' .. self.tablename .. ' WHERE idx = ?')
  self.queryCount = self.db:prepare('SELECT count(value) FROM ' .. self.tablename)
end

function m:isOpened()
  return self.db ~= nil
end

function m:close()
  assert(self.db ~= nil)
  local closed = (self.db:close() == sqlite3.OK)
  self.db = nil
  self.queryGetName = nil
  self.queryGetIdx = nil
  self.queryCount = nil
  return closed
end

local cmsgpackpack = cmsgpack.pack
local cmsgpackunpack = cmsgpack.unpack

function m:decode(nameOrIdx, raw, encoding)
  engine.beginSample('SqliteConfigFile.decode')
  local res = self:doDecode(nameOrIdx, raw, encoding)
  engine.endSample()
  return res
end

function m:doDecode(nameOrIdx, raw, encoding)
  if m.debug then
    logd('SqliteConfigFile: %s decode %s encoding=%s', self.filename, nameOrIdx, encoding)
  end

  if encoding == 0 then
    return nil
  elseif encoding == 1 then
    return (raw == 'true')
  elseif encoding == 2 then
    return tonumber(raw)
  elseif encoding == 3 then
    return raw
  elseif encoding == 4 then
    local text = ClientEncoding.decryptRc4(raw)
    -- return cjson.decode(text)
    return cmsgpackunpack(text)
  elseif encoding == 5 then
    local text = ClientEncoding.decryptRc4(raw)
    text = zlib.inflate()(text, 'finish')
    return cmsgpackunpack(text)
    -- return cjson.decode(text)
  else
    error(string.format('SqliteConfigFile: %s invalid encoding %s for value',
      self.filename, tostring(encoding), tostring(raw)))
  end
end

function m:get(nameOrIdx)
  engine.beginSample('SqliteConfigFile.get')
  local res = self:doGet(nameOrIdx)
  engine.endSample()
  return res
end

function  m:doGet(nameOrIdx)
  local cache = self.cache
  if cache then
    -- if m.debug then
    --   logd('SqliteConfigFile: %s get %s cache size=%s max=%s',
    --     self.filename, nameOrIdx, cache:size(), cache.maxSize)
    -- end

    local cached, hit = cache:get(nameOrIdx)
    if hit then return cached end
  end

  if self.stat then self.stat:increment('get') end

  if m.debug then
    logd('SqliteConfigFile: %s get name=%s trace=%s', self.filename, tostring(nameOrIdx), debug.traceback())
  end

  local queryType = type(nameOrIdx)
  local query
  if queryType == 'string' then
    query = self.queryGetName
    if query then
      query:bind_values(nameOrIdx)
    end
  elseif queryType == 'number' then
    query = self.queryGetIdx
    if query then
      query:bind_values(nameOrIdx - 1)
    end
  elseif nameOrIdx == cjson.null then
    if cache then cache:set(nameOrIdx, nil) end
    return nil
  elseif nameOrIdx == nil then
    return nil
  else
    error(string.format('SqliteConfigFile: %s get with incorrect type: %s %s',
      self.filename, queryType, tostring(nameOrIdx)))
  end

  if m.debug and self.db then
    assert(query, self.db:errmsg())
  end

  -- step() takes most of cpu when query (about 1ms/op when profiling on Nexus 6P)
  if query and query:step() == sqlite3.ROW then
    local raw, encoding = query:get_uvalues()
    local reset = query:reset()
    if m.debug then
      assert(reset == sqlite3.OK)
    end

    if raw then
      if tracemem then
        local len = string.len(raw)
        if len > 2048 then
          loge('traceMemory: sqlite file=%s name=%s len=%s too large!',
            self.filename, tostring(nameOrIdx), len)
        end
      end
      local value = self:decode(nameOrIdx, raw, encoding)
      if cache then cache:set(nameOrIdx, value) end
      if m.debug then
        logd('SqliteConfigFile: %s value=', self.filename, tostring(value))
      end
      return value
    else
      if cache then cache:set(nameOrIdx, nil) end
      return nil
    end
  else
    if query then
      local reset = query:reset()
      if m.debug then
        assert(reset == sqlite3.OK)
      end
    end
    if cache then cache:set(nameOrIdx, nil) end
    return nil
  end
end

function m:iter(numeric)
  if self.stat then self.stat:increment('iter') end

  if m.debug then
    logd('SqliteConfigFile: %s iter START', self.filename)
  end

  local query = self.db:prepare('SELECT name, idx, value, encoding FROM ' .. self.tablename)
  if m.debug then
    assert(query, self.db:errmsg())
  end

  local r = query:step()
  return function ()
    engine.beginSample('SqliteConfigFile.iter')
    local res1, res2 = nil, nil
    if r == sqlite3.ROW then
      local name, idx, raw, encoding = query:get_uvalues()
      r = query:step()
      if r == sqlite3.DONE then
        if m.debug then
          logd('SqliteConfigFile: %s iter BREAK', self.filename)
        end
        local final = query:finalize()
        if m.debug then
          assert(final == sqlite3.OK)
        end
      end
      local value = self:decode(name or idx, raw, encoding)
      if m.debug then
        logd('SqliteConfigFile: %s iter: name=%s idx=%s value=%s encoding=%s', self.filename,
          tostring(name), tostring(idx), tostring(value), tostring(encoding))
      end
      if numeric then
        res1, res2 = idx + 1, value
      else
        if name then
          res1, res2 = name, value
        else
          res1, res2 = idx + 1, value
        end
      end
    else
      if m.debug then
        logd('SqliteConfigFile: %s iter END', self.filename)
      end
      if query:isopen() then
        local final = query:finalize()
        if m.debug then
          assert(final == sqlite3.OK)
        end
      end
    end
    engine.endSample()
    return res1, res2
  end
end

function m:count()
  engine.beginSample('SqliteConfigFile.count')
  local res = self:doCount()
  engine.endSample()
  return res
end

function m:doCount()
  local cache = self.cache
  if cache then
    local cached, hit = cache:get('__count')
    if hit then return cached end
  end

  if self.stat then self.stat:increment('count') end

  if m.debug then
    logd('SqliteConfigFile: %s doing count', self.filename)
  end
  local query = self.queryCount
  if query and query:step() == sqlite3.ROW then
    local value = query:get_uvalues()
    if m.debug then
      logd('SqliteConfigFile: %s count value is %s', self.filename, tostring(value))
    end
    local count = tonumber(value)
    local reset = query:reset()
    if m.debug then
      assert(reset == sqlite3.OK)
    end
    if count then
      if cache then cache:set('__count', count) end
      return count
    else
      return 0
    end
  else
    return 0
  end
end
