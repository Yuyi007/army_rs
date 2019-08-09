
local table = table
local math = math
-- fix SqliteConfigFile override pairs
-- local next, pairs, rawset = next, pairs, rawset
local traceback = debug.traceback

function table.keys(t)
  local keyset={}
  local n=0

  for k,v in pairs(t) do
    n=n+1
    keyset[n]=k
  end

  return keyset
end

function table.keyExist(t, key)
  return key ~= nil and t[key] ~= nil
end

-- return the last element of the array
function table.last(t)
  return t[table.getn(t)]
end

function table.empty(t)
  if not t then return true end

  for k, v in pairs(t) do
    return false
  end
  return true
end

function table.shift(t)
  return table.remove(t, 1)
end

function table.unshift(t, a)
  table.insert(t, 1, a)
end

function table.pop(t)
  return table.remove(t)
end

function table.push(t, a)
  return table.insert(t, a)
end

-- t1 & t2 implementation
function table.tand(t1, t2)
  local temp = {}
  local hash = {}
  each(function(x)
    if index(x, t2) and not hash[x] then
      table.push(temp, x)
      hash[x] = true
    end
  end, t1)
  return temp
end

-- t1 | t2 implementation
function table.tor(t1, t2)
  local hash = {}
  each(function(x) hash[x] = true end, t1)
  each(function(x) hash[x] = true end, t2)
  return totable(map(function(k, v) return k end, hash))
end

-- count all elements in an table
function table.nums(t)
    if type(t) ~= "table" then
        if game.debug > 0 then traceback() end
        return nil
    end
    local nums = 0
    for k, v in pairs(t) do
        nums = nums + 1
    end
    return nums
end

function table.nonnulls(t)
  if type(t) ~= "table" then
    if game.debug > 0 then traceback() end
    return nil
  end
  local nums = 0
  for k, v in pairs(t) do
    if v ~= cjson.null then
      nums = nums + 1
    end
  end
  return nums
end

-- find index of an element in a table
function table.find(t, func)
    if type(t) ~= "table" then
        if game.debug > 0 then traceback() end
        return nil
    end
    local res = nil
    for k, v in pairs(t) do
        if func(v) then
            res = k
            break
        end
    end
    return res
end

function table.merge(first, second, merger)
  if type(merger) == 'function' then
    for k, v in pairs(second) do
      first[k] = merger(k, first[k], v)
    end
  elseif type(second) == 'table' then
    for k, v in pairs(second) do
      first[k] = v
    end
  end
  return first
end

function table.arrayConcat(first, second)
  if not second then return first end
  -- if type(first) == 'table' and type(second) == 'table' and #second > 0 then
    for i = 1, #second do
      first[#first + 1] = second[i]
    end
  -- end
  return first
end

function table.deepMerge(first, second)
  local function _merger(key, o1, o2)
    if type(o1) == 'table' and type(o2) == 'table' then
      return table.merge(o1, o2, _merger)
    else
      return o2
    end
  end

  if type(second) == 'table' then
    table.merge(first, second, _merger)
  end

  return first
end

function table.removeValFunc(t, v, equalFunc)
  local index, len = 0, #t
  for i = 1, len do
    if equalFunc(t[i], v) then
      index = i
      break
    end
  end
  if index ~= 0 then
    return table.remove(t, index)
  end
end

function table.removeVal(t, v)
  return table.removeValFunc(t, v, function(lhs, rhs)
    return lhs == rhs
  end)
end

function table.removeAllValFun(t, equalFunc)
  for i = #(t), 1 , -1 do
    if equalFunc(t[i]) then
      table.remove(t, i)
    end
  end
end

function table.random(t, num)
  if not t then return nil end
  local length = table.getn(t)
  if length > 0 then
    if num == nil or num == 1 then
      return t[math.random(length)]
    elseif num >= length then
      return t
    else
      local res = {}
      local t2 = table.cloneArray(t)
      for i = 1, num do
        local seed = math.random(length + 1 - i)
        res[i] = t2[seed + i - 1]
        t2[seed + i - 1] = t2[i]
      end
      return res
    end
  else
    return nil
  end
end

function table.randomWeight(t, weight)
  return table.randomWeight2(t, weight, function(e)
    return e['weight']
  end)
end

function table.randomWeight2(t, weight, weightFunc)
  local length = table.getn(t)
  assert(length > 0)

  if not weight then
    weight = 0
    for i = 1, length do
      local v = t[i]
      weight = weight + weightFunc(v)
    end
  end

  local w = math.random(weight)
  -- logd(">>>>>>>random t"..inspect(t))
  -- logd(">>>>>>>random weight"..inspect(weight))
  -- logd(">>>>>>>random w"..inspect(w))
  local min, max = 0, 0
  for i = 1, length do
    max = min + weightFunc(t[i])
    if w > min and w <= max then
      return t[i]
    end
    min = max
  end
end

function table.shuffle(array)
  local n, random, j = table.getn(array), math.random
  for i = 1, n do
    local j, k = random(n), random(n)
    array[j], array[k] = array[k], array[j]
  end
  return array
end

function table.quicksort(t, start, endi, compare)
  start, endi = start or 1, endi or #t
  compare = compare or function(x, y) return x <= y end

  if(endi - start < 1) then return t end
  local pivot = start
  for i = start + 1, endi do
    if compare(t[i], t[pivot]) then
      local temp = t[pivot + 1]
      t[pivot + 1] = t[pivot]
      if(i == pivot + 1) then
        t[pivot] = temp
      else
        t[pivot] = t[i]
        t[i] = temp
      end
      pivot = pivot + 1
    end
  end
  t = table.quicksort(t, start, pivot - 1, compare)
  return table.quicksort(t, pivot + 1, endi, compare)
end

function table.insertionSort(array, compare)
  compare = compare or function(x, y) return x > y end

  local len = #array
  local j
  for j = 2, len do
      local key = array[j]
      local i = j - 1
      while i > 0 and compare(array[i], key) do
          array[i + 1] = array[i]
          i = i - 1
      end
      array[i + 1] = key
  end
  return array
end

function table.concatArrays(first, second)
    if not second then return first end
  -- if type(first) == 'table' and type(second) == 'table' then
    for i = 1, table.getn(second) do
      first[#first + 1] = second[i]
    end
  -- end
  return first
end

function table.cloneArray(array)
  if not array then return nil end
  local res = {}
  for i = 1, table.getn(array) do
    res[i] = array[i]
  end
  return res
end

function table.index(t, value)
  for i = 1, table.getn(t) do
    local v = t[i]
    if value == v then
      return i
    end
  end
  return nil
end

function table.contains(table, element)
  for _, value in pairs(table) do
    if value == element then
      return true
    end
  end
  return false
end



function table.findIndex(t, func)
  for i = 1, table.getn(t) do
    if func(t[i]) then
      return i
    end
  end
  return nil
end


function table.clear(t)
  if not t then return end
  for k, v in pairs(t) do
    t[k] = nil
  end
end

function table.trim(t, size)
  local length = #t
  for i = size + 1, length do
    t[i] = nil
  end
end

function table.clear2(t)
  if not t then return end
  for k in next, t do rawset(t, k, nil) end
end

function table.reverse(t)
  local size = #t
  local newTable = {}
  for i = 1, #t do
    newTable[size-i+1] = t[i]
  end
  return newTable
end

function table.tostring (v, len)
  len = len or 0

  local pre = string.rep(' ', len)
  local ret = ""
  if type(v) == "table" then
    local isarr = true
    for k, v in pairs(v) do
      if type(k) ~= "number" then
        isarr = false
      end
    end

    local t = ""
    for k, v1 in pairs(v) do
      if isarr then
        t = t .. "\n " .. pre
      else
        t = t .. "\n " .. pre .. "[\""..tostring(k) .. "\"] = "
      end
      t = t .. table.tostring(v1, len + 1)
    end
    if t == "" then
        ret = ret .. pre .. "{}\t"
    else
      if len > 0 then
       ret = ret
      end
      ret = ret .. pre .. "{" .. t .. "\n" .. pre .. "},"
    end
  else
    if type(v) == "string" then
      ret = ret .. "\"".. tostring(v) .. "\","
    else
      ret = ret .. tostring(v) .. ","
    end
  end
  return ret
end

function table.difference(a, b)
  if a == b then return nil end
  if a == nil then return b end
  if b == nil then return a end

  local ai = {}
  local r = {}
  for k, v in pairs(a) do
    r[k] = v
    ai[v] = true
  end
  for k, v in pairs(b) do
    if ai[v] ~= nil then
      r[k] = nil
    end
  end
  return r
end

function table.listToString(v)
  local t = {}
  local length = table.getn(v)
  for i = 1, length do
    t[i] = tostring(v[i])
  end
  return table.concat(t, ',')
end

function Ordered(t)
  local currentIndex = 1
  local metaTable = {}

  function metaTable:__newindex(key,value)
    rawset(self, key, value)
    rawset(self, currentIndex, key)
    currentIndex = currentIndex + 1
  end
  return setmetatable(t or {}, metaTable)
end

function opairs(t)
  local currentIndex = 0
  local function iter(t)
    currentIndex = currentIndex + 1
    local key = t[currentIndex]
    if key then return key, t[key] end
  end
  return iter, t
end

function memoize(f)
  local mem = setmetatable({}, {__mode = 'kv'})
  return function (x) -- new version of ’f’, with memoizing
    local r = mem[x]
    if r == nil then -- no previous result?
      r = f(x) -- calls original function
      mem[x] = r -- store result for reuse
    end
    return r
  end
end

function memoize2(f)
  local mem = setmetatable({}, {__mode = "kv"})
  return function (x, y) -- new version of ’f’, with memoizing
    local r = mem[x]
    local r2
    if r then
      r2 = r[y]
      if r2 then return r2 end
    else
      r = setmetatable({}, {__mode = 'kv'})
      mem[x] = r
    end
    r2 = f(x, y)
    r[y] = r2
    return r2
  end
end

function declare_module(modulename)
  local m = {}
  declare(modulename, m)
  setmetatable(m, {__index = _G})
  setfenv(2, m)
end