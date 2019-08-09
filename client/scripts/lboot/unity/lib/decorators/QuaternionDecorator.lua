class('QuaternionDecorator')

local m          = QuaternionDecorator
local Quaternion = UnityEngine.Quaternion
local Inst = _G['UnityEngine.Quaternion.OldInstance']
local NewQuaternion = getmetatable(Quaternion).__call
local pool       = FramePool.new(function () return m.create(Quaternion, 0, 0, 0, 1) end, {
  initSize = 0, maxSize = 256, tag = 'Quaternion', objectMt = getmetatable(NewQuaternion(Quaternion, 0, 0, 0, 1))
})

function m.decorate()
  local typeMt = getmetatable(Quaternion)
  local mt = getmetatable(Quaternion.identity)

  local funcs = m.funcs(mt)
  for k, v in pairs(funcs) do
    rawset(mt, k, v)
  end

  m.create = function (a, b, c, d, e)
    local res = NewQuaternion(a, b, c, d, e)
    for k, v in pairs(funcs) do
      rawset(res, k, v)
    end
    return res
  end

  for k, v in pairs(m.typeFuncs(typeMt, mt)) do
    rawset(typeMt, k, v)
  end

  rawset(Quaternion, 'static_identity', Quaternion.new(Quaternion.identity))
end

function m.typeFuncs(typeMt, objMt)
  local mt = {}

  mt.new = function (x, y, z, w)
    if x and not y then
      y = x[2]; z = x[3]; w = x[4]; x = x[1]
    end
    return m.create(Quaternion, x or 0, y or 0, z or 0, w or 1)
  end

  mt.borrow = function () return pool:borrow() end

  if unity.useStructPooling then
    function mt.__call(t, x, y, z, w)
      local v = pool:borrow()
      if not x then
        v[1] = 0; v[2] = 0; v[3] = 0; v[4] = 1
      elseif not y then
        v[1] = x[1]; v[2] = x[2]; v[3] = x[3]; v[4] = x[4]
      else
        v[1] = x; v[2] = y; v[3] = z; v[4] = w
      end
      return v
    end
  else
    function mt.__call(t, x, y, z, w)
      if not x then
        return NewQuaternion(t, 0, 0, 0, 1)
      elseif not y then
        return NewQuaternion(t, x[1], x[2], x[3], x[4])
      else
        return NewQuaternion(t, x, y, z, w)
      end
    end
  end


  return mt
end

function m.funcs(oldMt)
  local mt = {}

  function mt.lerp(self, to, t)
    return Quaternion.Lerp(self, to, t)
  end

  function mt.get_eulerAngles(self)
    return Inst.eulerAngles[1](self)
  end

  function mt.set_eulerAngles(self, v)
    Inst.eulerAngles[2](self,v)
  end

  function mt.set(self, x, y, z, w)
    if not x then
      self[1] = 0
      self[2] = 0
      self[3] = 0
      self[4] = 1
    elseif not y then
      self[1] = x[1]
      self[2] = x[2]
      self[3] = x[3]
      self[4] = x[4]
    else
      self[1] = x
      self[2] = y
      self[3] = z
      self[4] = w
    end
    return self
  end

  --[[

  function mt.slerp(self, to, t)
    return Quaternion.Slerp(self, to, t)
  end

  function mt.inverse(self)
    return Quaternion.Inverse(self)
  end

  function mt.rotateTowards(self, to, maxDegreesDelta)
    return Quaternion.RotateTowards(self, to, maxDegreesDelta)
  end

  ]]

  return mt
end


setmetatable(m, {__call = function(t, ...) m.decorate(...) end })