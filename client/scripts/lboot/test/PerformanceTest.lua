-- PerformanceTest.lua

local vector = require 'lboot/ext/vector'
local table = table

local testTime = function (f, n, title)
  local startTime = os.clock()
  for i = 1, n, 1 do
    f(i)
  end
  local msecs = (os.clock() - startTime) * 1000
  logd("test %s: %d ops, %.3f msecs, average %.3f microsecs/ops",
    title, n, msecs, msecs * 1000 / n)
end

local N = 100

local a = {}
for i = 1, 10000 do
  a[i] = i
end

local b = {}
for i = 1, 100 do
  b[i] = {a = i}
end

local c = {b = b}

local cloneArray = table.cloneArray
local deepCopy = deepCopy
local clone = clone

testTime(function(i)
  cloneArray(a)
end, N, "table cloneArray")

testTime(function(i)
  deepCopy(a)
end, N, "table deepCopy")

testTime(function(i)
  clone(a)
end, N, "table clone")

local d = {}
testTime(function(i)
  d[#d + 1] = i
end, 100, "table insert")

testTime(function(i)
  local removed = table.remove(d, 1)
  d[#d + 1] = removed
end, 100, "table remove and insert")

local e = LuaList()
testTime(function(i)
  e:push({})
end, 100, "LuaList push")

testTime(function(i)
  local removed = e:shift()
  e:push({})
end, 100, "LuaList shift and push")

testTime(function(_)
  for i, v in ipairs(b) do
  end
end, N, "loop ipairs")

testTime(function(_)
  for i, v in pairs(b) do
  end
end, N, "loop pairs")

testTime(function(_)
  for i = 1, #b do local v = b[i]
  end
end, N, "loop for")

testTime(function(_)
  for i, v in ipairs(c.b) do
  end
end, N, "loop ipairs 2")

testTime(function(_)
  for i, v in pairs(c.b) do
  end
end, N, "loop pairs 2")

testTime(function(_)
  for i = 1, #c.b do local v = c.b[i]
  end
end, N, "loop for 2")

testTime(function(_)
  local b = c.b
  for i = 1, #b do local v = b[i]
  end
end, N, "loop for 3")

testTime(function(_)
  local b = c.b
  for i = 1, table.getn(b) do local v = b[i]
  end
end, N, "loop for 4")

testTime(function(_)
  table.clear(a)
end, 1, 'table.clear a 1')

for i = 1, 10000 do
  a[i] = i
end

testTime(function(_)
  for k, v in pairs(a) do
    a[k] = nil
  end
end, 1, 'clear a 2')

for i = 1, 10000 do
  a[i] = i
end

testTime(function(_)
  table.trim(a, 100)
end, 1, 'table.trim')

testTime(function (i)
  return i + i
end, N, 'number add')


testTime(function (i)
  return i * i
end, N, 'number mult')

testTime(function (i)
  return i / 3.1415926
end, N, 'number div')

testTime(function (i)
  return math.abs(i)
end, N, 'math.abs')

testTime(function (i)
  return math.rad(i)
end, N, 'math.rad')

testTime(function (i)
  return math.sin(i)
end, N, 'math.sin')

testTime(function (i)
  return math.cos(i)
end, N, 'math.cos')

testTime(function (i)
  return math.tan(i)
end, N, 'math.tan')

testTime(function (i)
  return vector(1, 2)
end, N, 'vector.create')

local a = vector(1, 2)
local b = vector(3, 4)
testTime(function (i)
  return a + b
end, N, 'vector.add')

testTime(function (i)
  return a * 2
end, N, 'vector.mult')

testTime(function (i)
  return a * b
end, N, 'vector.dot')

testTime(function (i)
  return a:cross(b)
end, N, 'vector.cross')

testTime(function (i)
  return a:dist(b)
end, N, 'vector.dist')

testTime(function (i)
  return a:projectOn(b)
end, N, 'vector.projectOn')

testTime(function (i)
  return a:angleTo(b)
end, N, 'vector.angleTo')

local a = 'abc'
local t = { a = a }
rawset(_G, 'a', a)

testTime(function (i)
  return _G.a
end, 50000, 'global table access')

rawset(_G, 'a', nil)

testTime(function (i)
  return t.a
end, 50000, 'upvalue table access')

testTime(function (i)
  return a
end, 50000, 'no table access')

testTime(function (i)
  return {}
end, N, 'create table')

local f = function (a1, a2, a3) end

testTime(function (i)
  return f(1, 2, 3)
end, 50000, 'call function')

testTime(function (i)
  return pcall(f, 1, 2, 3)
end, 50000, 'pcall function')
