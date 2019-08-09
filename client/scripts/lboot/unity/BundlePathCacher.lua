
class('BundlePathCacher', function (self)
  self.bundleCaches = setmetatable({}, {__mode='k'})
  self.transCaches = {}
end)

local m = BundlePathCacher
local instance = BundlePathCacher.new()
local unity = unity

m.debug = nil

-----------------------------------------------

function m.get(bundleFile, go)
  return m.getWithCache(bundleFile, go)
end

-- add this method because
-- bundle path cache are usually calculated only once nowadays
-- and getRaw is faster than getWithCache on the first run
function m.getRaw(bundleFile, go)
  local bindableNodes = {}
  local paths = {}
  local nameCache = {}
  local comps = go:get_gameObject():GetComponentsInChildren(UnityEngine.Transform, true)
  local rootId = go:GetInstanceID()
  for i = 1, #comps do
    local comp = comps[i]
    local name = comp:get_name()
    local varname, k = string.gsub(name, '^b_', '')
    if k == 1 and comp:GetInstanceID() ~= rootId then
      local parent = comp:get_parent()
      while parent do
        local prefix = nameCache[parent]
        if prefix then
          varname = string.format('%s_%s', prefix, varname)
          break
        end
        parent = parent:get_parent()
      end
      nameCache[comp] = varname
      if m.debug then
        logd('BundlePathCacher.getRaw: go=%s name=%s varname=%s', tostring(go), name, varname)
      end
      bindableNodes[#bindableNodes + 1] = comp:get_gameObject()
      paths[#paths + 1] = varname
    end
  end
  return bindableNodes, paths
end

function m.getWithCache(bundleFile, go)
  -- NOTE bundleFile types are various
  local t = type(bundleFile)
  if t == 'string' then
    bundleFile = bundleFile:lower()
    -- nothing to do at the moment
  elseif t == 'table' then
    -- tables change every time, not good as a caching key
    if bundleFile.gameObject then
      bundleFile = bundleFile.gameObject
    end
  elseif t == 'userdata' then
    -- nothing to do at the moment
  end

  return instance:getBundlePaths(bundleFile, go)
end

function m.clearTransCache(go)
  local instId = go:get_transform():GetInstanceID()
  instance.transCaches[instId] = nil
end

function m.clearAll()
  table.clear(instance.bundleCaches)
  table.clear(instance.transCaches)
end

-----------------------------------------------

function m:getBundlePaths(bundleFile, go)
  unity.beginSample('BundlePathCacher.getBundlePaths %s', bundleFile)

  local rootTransform = go:get_transform()
  local instId = rootTransform:GetInstanceID()
  local cache = nil

  if bundleFile == nil then
    loge('getBundlePaths: bundleFile is nil trace=%s', debug.traceback())
    cache = self:initBundleCache(bundleFile, rootTransform)
  else
    cache = self.bundleCaches[bundleFile]
    if not cache then
      cache = self:initBundleCache(bundleFile, rootTransform)
      self.bundleCaches[bundleFile] = cache
    end
  end

  local codes, paths, transCaches = cache.codes, cache.paths, self.transCaches

  -- Some UI control, like ToggleBtnGroup, can change transform orders when using.
  -- So transCache comes to rescue, stores gameobject's initial codes -> children mapping
  -- and save cpu cycles of findTransformFromCode()
  local transLookup = transCaches[instId]
  if not transLookup then
    transLookup = {}
    transCaches[instId] = transLookup
  end

  local gameObjects = {}
  for i = 1, #codes do
    local code = codes[i]
    local go = transLookup[code]
    if not go then
      if m.debug then
        logd('getBundlePaths: findTransformFromCode trans=%s code=%s', tostring(rootTransform), code)
      end
      go = self:findTransformFromCode(rootTransform, code):get_gameObject()
      transLookup[code] = go
    end
    gameObjects[i] = go
  end

  unity.endSample()
  return gameObjects, paths
end

function m:initBundleCache(bundleFile, root)
  unity.beginSample('BundlePathCacher.initBundleCache %s', bundleFile)

  if m.debug then
    logd('initBundleCache bundleFile=%s root=%s trace=%s',
      tostring(bundleFile), tostring(root), debug.traceback())
  end
  local cache = {
    codes = {},
    paths = {},
  }
  self:populateBundleCache(bundleFile, root, 1, m:newCode(), '', cache.codes, cache.paths)

  unity.endSample()
  return cache
end

function m:populateBundleCache(bundleFile, root, level, code, prefix, codes, paths)
  local nextLevel = level + 1
  local childCount = root:get_childCount()

  for i = 0, childCount - 1 do
    if m.debug then
      logd('populateBundleCache: level=%d i=%d childCount=%d',
        level, i, childCount)
    end

    -- you still can have more children after code overflow,
    -- but they will be ignored when binding
    if self:checkCodeOverflow(level, i) then
      loge(string.format(
        'populateBundleCache: overflow part ignored bundle=%s root=%s i=%d level=%d',
        tostring(bundleFile), tostring(root), i, level))
      break
    end

    local child = root:GetChild(i)
    local childCode = self:getChildCode(code, level, i)
    local childName = child:get_name()
    local childIsBindable = childName:match('^b_')
    local childPath = prefix

    if childIsBindable then
      local childSegment = string.sub(childName, 3)
      if prefix == '' then
        childPath = childSegment
      else
        childPath = string.format('%s_%s', prefix, childSegment)
      end

      codes[#codes + 1] = childCode
      paths[#paths + 1] = childPath
    end

    if m.debug then
      logd('populateBundleCache: child=%s code=%s path=%s nextLevel=%d',
        tostring(child), self:codeToString(childCode), childPath, nextLevel)
    end

    self:populateBundleCache(bundleFile, child, nextLevel, childCode, childPath, codes, paths)
  end
end

---------------------- Code Operations ---------------------
--
-- encode children using 4 number of length 4 bytes(on 32-bits) or 8 bytes(on 64-bits)
-- each child index occupies 8 bits, means:
-- 1. each level can have at most 255 children (zero reserved for termination)
-- 2. at most 16 levels of children.
--
------------------------------------------------------------

local bit = require 'bit' -- we only support bitops module originated from luajit
local band, bor, lshift, rshift = bit.band, bit.bor, bit.lshift, bit.rshift

local levelShifts = {}
for i = 1, 8 do levelShifts[i] = (i - 1) * 8 end

function m:newCode()
  return {0, 0, 0, 0}
end

function m:checkCodeOverflow(level, childIndex)
  return (level > 16 or childIndex > 255)
end

function m:getChildCode(code, level, childIndex)
  local childCode = self:newCode()
  if level <= 4 then
    childCode[1] = bor(code[1], lshift(childIndex + 1, levelShifts[level]))
  elseif level <= 8 then
    childCode[1] = code[1]
    childCode[2] = bor(code[2], lshift(childIndex + 1, levelShifts[level - 4]))
  elseif level <= 12 then
    childCode[1] = code[1]
    childCode[2] = code[2]
    childCode[3] = bor(code[3], lshift(childIndex + 1, levelShifts[level - 8]))
  else
    childCode[1] = code[1]
    childCode[2] = code[2]
    childCode[3] = code[3]
    childCode[4] = bor(code[4], lshift(childIndex + 1, levelShifts[level - 12]))
  end
  return childCode
end

function m:findTransformFromCode(root, code)
  local trans = root
  for level = 1, 16 do
    local childIndex = nil
    if level <= 4 then
      childIndex = band(rshift(code[1], levelShifts[level]), 255) - 1
    elseif level <= 8 then
      childIndex = band(rshift(code[2], levelShifts[level - 4]), 255) - 1
    elseif level <= 12 then
      childIndex = band(rshift(code[3], levelShifts[level - 8]), 255) - 1
    else
      childIndex = band(rshift(code[4], levelShifts[level - 12]), 255) - 1
    end
    if childIndex == -1 then
      break
    end
    if m.debug then
      logd('findTransformFromCode: trans=%s code=%s level=%d childIndex=%d',
        tostring(trans), self:codeToString(code), level, childIndex)
    end
    trans = trans:GetChild(childIndex)
  end
  return trans
end

function m:codeToIndices(code)
  local t = {}
  for level = 1, 16 do
    local childIndex = nil
    if level <= 4 then
      childIndex = band(rshift(code[1], levelShifts[level]), 255) - 1
    elseif level <= 8 then
      childIndex = band(rshift(code[2], levelShifts[level - 4]), 255) - 1
    elseif level <= 12 then
      childIndex = band(rshift(code[3], levelShifts[level - 8]), 255) - 1
    else
      childIndex = band(rshift(code[4], levelShifts[level - 12]), 255) - 1
    end
    t[#t + 1] = childIndex
  end
  return t
end

function m:codeToString(code)
  local t = self:codeToIndices(code)
  return table.concat(t, ', ')
end

function m:codeToHex(code)
  return string.format('0x%s 0x%s 0x%s 0x%s', bit.tohex(code[1]), bit.tohex(code[2]),
    bit.tohex(code[3]), bit.tohex(code[4]))
end
