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
  for k,v in pairs(t) do
    if k == key then
      return true
    end
  end
  return false
end

-- return the last element of the array
function table.last(t)
  return t[#t]
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
  if type(first) == 'table' and type(second) == 'table' and #second > 0 then
    for k, v in ipairs(second) do
      table.insert(first, v)
    end
  end
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

function table.random(t)
  if not t then return nil end
  if #t > 0 then
    return t[math.random(#t)]
  else
    return nil
  end
end

function table.randomWeight(t, weight)
  assert(#t > 0)
  local w = math.random(weight)
  -- logd(">>>>>>>random t"..inspect(t))
  -- logd(">>>>>>>random weight"..inspect(weight))
  -- logd(">>>>>>>random w"..inspect(w))
  local min, max = 0, 0
  for i = 1, #t do
    max = min + t[i]['weight']
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

function table.insertionSort (array, compare)
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
  if type(first) == 'table' and type(second) == 'table' then
    for i, v in ipairs(second) do
      table.insert(first, v)
    end
  end
  return first
end

function table.contains(table, element)
  for _, value in pairs(table) do
    if value == element then
      return true
    end
  end
  return false
end

local next = next
function table.clear(t)
  for k in next, t do rawset(t, k, nil) end
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

function table.listToString(v)
  local t = {}
  for i = 1, #v do
    t[#t + 1] = tostring(v[i])
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
  local mem = {} -- memoizing table
  setmetatable(mem, {__mode = "kv"}) -- make it weak
  return function (x) -- new version of ’f’, with memoizing
    local r = mem[x]
    if r == nil then -- no previous result?
      r = f(x) -- calls original function
      mem[x] = r -- store result for reuse
    end
    return r
  end
end