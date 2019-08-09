-- PerformanceTest.lua

local Time = UnityEngine.Time
local Vector3 = UnityEngine.Vector3
local Quaternion = UnityEngine.Quaternion
local Matrix4x4 = UnityEngine.Matrix4x4

local testTime = function (f, n, title)
  local startTime = engine.realtime()
  for i = 1, n, 1 do
    f(i)
  end
  local msecs = (engine.realtime() - startTime) * 1000
  logd("test %s: %d ops, %.3f msecs, average %.3f microsecs/ops",
    title, n, msecs, msecs * 1000 / n)
end

local N = 2000

--- Vector3 tests

testTime(function (i)
  local v = Vector3(i, i, i)
end, N, 'Vector3 Create')

Pool.getPool('Vector3'):recycleAll()

testTime(function (i)
  local v = Vector3(i, i, i)
end, N, 'Vector3 Create again after recycleAll()')

testTime(function (i)
  local v = Vector3.__call(Vector3, i, i, i)
end, N, 'Vector3.__call')

Pool.getPool('Vector3'):recycleAll()

testTime(function (i)
  local v = Vector3.__call(Vector3, i, i, i)
end, N, 'Vector3.__call again after recycleAll()')

testTime(function (i)
  local v = Vector3.new(i, i, i)
end, N, 'Vector3.new')

local v = Vector3(1, 1, 1)
testTime(function (i)
  local temp = v.x
end, N, 'Vector3.x')

testTime(function (i)
  local temp = v[1]
end, N, 'Vector3[1]')

testTime(function (i)
  v = v + v
end, N, 'Vector3 Add (operator)')

testTime(function (i)
  Vector3.Add(v, v)
end, N, 'Vector3 Add')

testTime(function (i)
  v[1] = v[1] + v[1]
  v[2] = v[2] + v[2]
  v[3] = v[3] + v[3]
end, N, 'Vector3 add (expanded)')

v = Vector3(1, 2, 3)
testTime(function (i)
  v = v * 3
end, N, 'Vector3 Mult (operator)')

testTime(function (i)
  v[1] = v[1] * 3
  v[2] = v[2] * 3
  v[3] = v[3] * 3
end, N, 'Vector3 mult (expanded)')

--- Vector3 tests

v = Vector3(1, 2, 3)
local v1 = Vector3(2, 3, 4)

testTime(function (i)
  return Vector3.Dot(v, v1)
end, N, 'Vector3.Dot')

testTime(function (i)
  return v:dot(v1)
end, N, 'Vector3 dot')

testTime(function (i)
  return Vector3.Distance(v, v1)
end, N, 'Vector3.Distance')

testTime(function (i)
  return v:dist(v1)
end, N, 'Vector3 dist')

testTime(function (i)
  return v:dist2(v1)
end, N, 'Vector3 dist2')

testTime(function (i)
  return Vector3.Angle(v, v1)
end, N, 'Vector3.Angle')

testTime(function (i)
  return v:angle(v1)
end, N, 'Vector3 angle')

testTime(function (i)
  return Vector3.ProjectOnPlane(v, v1)
end, N, 'Vector3.ProjectOnPlane')

testTime(function (i)
  return v:projectOnPlane(v1)
end, N, 'Vector3 projectOnPlane')

testTime(function (i)
  return v:set(v1)
end, N, 'Vector3 set')

testTime(function (i)
  v[1] = v1[1]
  v[2] = v1[2]
  v[3] = v1[3]
end, N, 'Vector3 set (expanded)')

--- Quaternion tests

local q = Quaternion(1, 2, 3, 4)
testTime(function (i)
  local temp = q * v
end, N, 'Quaternion Mult Vector3')

testTime(function (i)
  local temp = q * q
end, N, 'Quaternion Mult Quaternion')

testTime(function (i)
  local temp = q.eulerAngles
end, N, 'Quaternion eulerAngles')

testTime(function (i)
  local temp = q:get_eulerAngles()
end, N, 'Quaternion get_eulerAngles()')

testTime(function (i)
  local temp = Quaternion.Euler(1, 2, 3)
end, N, 'Quaternion Euler')

--- GameObject tests

local go = GameObject()
local transform = go.transform

testTime(function (i)
  return go.transform
end, N, 'GameObject.transform')

testTime(function (i)
  return go:get_transform()
end, N, 'GameObject:get_transform()')

testTime(function (i)
  return transform.position
end, N, 'transform.position')

testTime(function (i)
  return transform:get_position()
end, N, 'transform:get_position()')

testTime(function (i)
  return transform:positionXYZ()
end, N, 'transform:positionXYZ()')

testTime(function (i)
  transform.position = Vector3(i, i, i)
end, N, 'transform.position=')

testTime(function (i)
  transform:set_position(Vector3(i, i, i))
end, N, 'transform:set_position()')

testTime(function (i)
  return transform.forward
end, N, 'transform.forward')

testTime(function (i)
  return transform:get_forward()
end, N, 'transform:get_forward()')

testTime(function (i)
  return go:getName()
end, N, 'go:getName()')

testTime(function (i)
  return go:get_name()
end, N, 'go:get_name()')

testTime(function (i)
  return go:setName('go' .. i)
end, N, 'go:setName()')

testTime(function (i)
  return go:set_name('go' .. i)
end, N, 'go:set_name()')

testTime(function (i)
  return go:addComponent(BoxCollider)
end, N, 'go:addComponent()')

testTime(function (i)
  return go:AddComponent(BoxCollider)
end, N, 'go:AddComponent()')

testTime(function (i)
  return go:getComponent(BoxCollider)
end, N, 'go:getComponent()')

testTime(function (i)
  return go:GetComponent(BoxCollider)
end, N, 'go:GetComponent()')

testTime(function (i)
  return go:getComponentsInChildren(BoxCollider)
end, N, 'go:getComponentsInChildren()')

testTime(function (i)
  return go:GetComponentsInChildren(BoxCollider)
end, N, 'go:GetComponentsInChildren()')

testTime(function (i)
  return go:setLayer(0)
end, N, 'go:setLayer()')

testTime(function (i)
  return uoc:getCustomAttrCache(go).luaTable
end, N, 'uoc:getCustomAttrCache()')

testTime(function (i)
  return uoc:getAttr(go, 'tag', true)
end, N, 'uoc:getAttr("tag")')

--- C# Comparison Tests

local goName = 'test_go'
go:set_name(goName)
local comp = go:AddComponent(UI.Text)
local testStr = 'test_go_text'
local testCount = 1000

testTime(function (i)
  for i = 1, testCount do
    local go = GameObject.Find(goName)
    local comp = go:GetComponent(UI.Text)
    comp:set_text(testStr)
  end
end, 1, 'find go and set text on it')

local Find = GameObject.Find
local Text = UI.Text
local GetComponent = go.GetComponent
local set_text = comp.set_text

testTime(function (i)
  for i = 1, testCount do
    local go = Find(goName)
    local comp = GetComponent(go, Text)
    set_text(comp, testStr)
  end
end, 1, 'find go and set text on it (opt)')

testTime(function (i)
  LBoot.LuaUtils.PerfTest1(goName, testStr, testCount)
end, 1, 'find go and set text on it (C#)')

GameObject.Destroy(go)
