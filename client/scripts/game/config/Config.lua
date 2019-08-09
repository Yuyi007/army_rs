
class('Config', function(self, raw, options)
  self.configKeys = {}
  self.options = table.merge({
    optimize = true,
  }, options)
  self.useSqlite = true
  self:init(raw)
end)

local m = Config
local assert, string, tostring = assert, string, tostring
local bor, fv_bor = bit.bor, bit.fv_bor
local marshal = require 'marshal'
local xxhash = xxhash
local XXHASH_SEED = 20150812
local DEFAULT_RANDOM_SEED = 20150812
local TextAsset = UnityEngine.TextAsset
local CURRENCY = {credits   = "ite1000001",
                  coins     = "ite1000002",
                  gragments = "ite1000003"}

local aho = require('lahocorasick')

function m:init(raw)
  if self.useSqlite then
    logd('parsing sqlite config...')
    self:initConfigWithSqlite()
  else
    logd('parsing json config...')
    self:initConfigWithJson(raw)
  end

  self:initAuxiliaryData()

  -- init random seed to make the client more random
  self:randomSeed()
end

function m:initConfigWithJson(raw)
  local decodeJson = function (data)
    local t = cjson.decode(data)
    for k, v in pairs(t) do
      table.insert(self.configKeys, k)
      self[k] = v
    end
  end

  if raw then
    decodeJson(raw)
  else
    raw = FileUtils.GetStringFromFile('config.json')
    decodeJson(raw)
  end
end

-- instead of keep config in memory, keep it in db file, reading it into memory when used
-- NOTE:
-- 1. modification to config variables won't persist, as everytime values will be read from db file
-- 2. using length operator '#' on config won't work, use table.getn() instead
-- 3. using pairs/ipairs on config will be MUCH FASTER than getting each index

local configAttrList = {
  maxLevel = true,

}

local secondary_mt = {}
secondary_mt.__index = function(o, name2)
  if not o.__level2[name2] then return nil end
  local name = o.__configName
  local dbname = name .. '.' .. name2 .. '.db'
  local cacheSize = rawget(_G, 'cfg') and cfg:getCacheSize(name, name2) or 1
  local proxy = SqliteConfigFileProxy.new(dbname, cacheSize)
  rawset(o, name2, proxy)
  return o[name2]
end

secondary_mt.__pairs = function(o)
  local k = nil
  return function()
    local v
    k, v = next(o.__level2, k)
    local v1 = o[k]
    return k, v1
  end
end

function m:initConfigWithSqlite()
  local mt = getmetatable(self) or {}
  
  mt.__index = function (_, name)
    -- logd(">>>>>>>name111:%s",inspect(name))
    -- logd(">>>>>>>name222:%s",inspect(Config[name]))
    if Config[name] then return Config[name] end
    if configAttrList[name] then return rawget(self, name) end
    
    if name == 'level2' or self.level2[name] == nil then
      -- logd('Config: opening db name=%s', name)
      local dbname = name .. '.db'
      local proxy = SqliteConfigFileProxy.new(dbname, self:getCacheSize(name))
      rawset(self, name, proxy)
      return proxy
    else
      local o = {}
      self[name] = o

      o.__level2 = self.level2[name]
      o.__configName = name
      o.dumpAndClose = function(self)
        local t = {}
        for k, v in pairs(self) do
          t[k] = v:dumpAndClose()
        end
        return t
      end

      setmetatable(o, secondary_mt)

      return o

        -- for _i, name2 in ipairs(self.level2[name]) do
        --   -- logd('Config: opening level2 db name=%s name2=%s', name, name2)
        --   local dbname = name .. '.' .. name2 .. '.db'
        --   local proxy = SqliteConfigFileProxy.new(dbname, self:getCacheSize(name, name2))
        --   rawset(self[name], name2, proxy)
        -- end
        -- return self[name]
    end
  end

  setmetatable(self, mt)

  -- cache some config to become normal tables because of either:
  -- 1. other code decorate the config permanantly
  -- 2. some timer iterates the config regularly
  local dumpTables = {
  }
  -- larger tables and needs to be iterated regularly
  local dumpTables2 = {
  }

  for _, name in ipairs(dumpTables) do
    self[name] = self[name]:dumpAndClose()
  end

  if not QualityUtil.isMemoryTight() then
    for _, name in ipairs(dumpTables2) do
      self[name] = self[name]:dumpAndClose()
    end
  end
end

local CACHESIZE = {
  uivarnames     = 500,
  strings        = 200,
  uimapper       = 200,
  animClips      = 200,
  animLoops      = 200,
  animators2     = 50,
  sprites        = 200,
  sensitiveWords = 0,
}


function m:getCacheSize(name, name2)
  local size
  if string.match(name, '^bundles_') then
    size = 100
  else
    size = CACHESIZE[name] or 20
  end

  if not QualityUtil.isMemoryTight() then
    size = size * 2
  end

  return size
end

-- helper to return cached config table when using sqlite
function m:cached(name)
  if self.useSqlite then
    return self[name]:dump()
  else
    return self[name]
  end
end

function m:randomSeed()
  math.randomseed(stime())
end

function m:initAuxiliaryData()
  self.multifast = aho.new()

  for _, w in ipairs(self.sensitiveWords) do
    self.multifast:add(string.lower(w))
  end

  self.multifast:finalize()
end

function m:assert(o, errorMsg)
  if not o then
    loge(errorMsg)
    loge(debug.traceback())
  end
  return o
end


function m:checksum(bin)
  bin = bin or self:serialize()
  local x = xxhash.init(XXHASH_SEED)
  x:update(bin, string.len(bin))
  return x:final(), bin
end

function m:serialize(content, constants)
  content = content or self
  constants = constants or {}
  return marshal.encode(content, constants, {
    ['function']=false,['userdata']=false,['sortkeys']=true})
end

function m:efxAsset(tid)
  return self:assert(self.assets.efx[tid], string.format('efx asset %s doesnt exist', tostring(tid)))
end

function m:animConfig(controllerId, anim)
  local config = self.assets.anims[controllerId]
  if config then return config[anim] end
  return nil
end

function m:randomName(gender)
  return table.random(cfg.names.list1)..table.random(cfg.names[gender])
end

function m:gsubSensitiveWords(text)
  if AudioRecordUtil.isAudioText(text) then
    return text
  end

  local matchWords = {}

  self.multifast:search(string.lower(text), function(s, e)
    table.insert(matchWords, { w = string.sub(text, s, e), r = string.rep('*', e - s + 1)} )
  end)

  self.multifast:reset()

  for i = 1, #matchWords do local v = matchWords[i]
    text = string.gsub(text, v.w, v.r)
  end

  text = text:gsub('***', '**')

  return text
end

function m:sensitive(text)
  local sensitive = false

  self.multifast:search(string.lower(text), function(s, e)
    sensitive = true
  end)

  self.multifast:reset()

  return sensitive
end

function m:mapData(mapId)
  return self.map[mapId]
end

function m:bundles()
  local platform = game.platform
  if platform == 'editor' then
    return self.bundles_osx
  elseif platform == 'ios' then
    return self.bundles_ios
  elseif platform == 'android' then
    return self.bundles_android
  end
end

function m:hasPrefab(prefab)
  prefab = string.format('assets/%s.prefab', prefab)
  local bundles = self:bundles()
  return bundles.prefabs[prefab] ~= nil
end

function m:prefabBundlePath(prefab)
  prefab = string.format('assets/%s.prefab', prefab)
  local bundles = self:bundles()
  if bundles then
    return bundles.prefabs[prefab]
  else
    return prefab
  end
end

function m:soundBundlePath(uri)
  uri = string.format('assets/%s.mp3', uri)
  local bundles = self:bundles()
  return bundles.sounds[uri]
end

function m:spriteAssetBundlePath(uri)
  uri = string.format('assets/%s.png', uri)
  local bundles = self:bundles()
  return bundles.images[uri]
end

function m:spriteMatBundlePath(uri)
  uri = string.format('assets/%s.mat', uri)
  local bundles = self:bundles()
  return bundles.materials[uri]
end

function m:sceneBundlePath(uri)
  uri = string.format('assets/%s.unity', uri)
  local bundles = self:bundles()
  return bundles.scenes[uri]
end

function m:texture2DBundlePath(uri)
  uri = string.format('assets/%s.tga', uri)
  local bundles = self:bundles()
  return bundles.texture2Ds[uri]
end

function m:getCameraCfg(part, level)
  return self.camera[part][level]
end