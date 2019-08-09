class('Vector2Decorator')

local m          = Vector2Decorator
local Vector2    = UnityEngine.Vector2
local Epsilon    = UnityEngine.Mathf.Epsilon
local NewVector2 = getmetatable(Vector2).__call
local pool       = FramePool.new(function () return m.create(Vector2, 0, 0) end, {
  initSize = 0, maxSize = 2048, tag = 'Vector2', objectMt = getmetatable(NewVector2(Vector2, 0, 0)),
})

local assert, rawget, rawset, setmetatable = assert, rawget, rawset, setmetatable
local cos, sin   = math.cos, math.sin
local abs, atan2 = math.abs, math.atan2
local deg, rad   = math.deg, math.rad

function m.decorate()
  local typeMt = getmetatable(Vector2)
  local mt = getmetatable(Vector2.zero)

  local funcs = m.funcs(mt)
  for k, v in pairs(funcs) do
    rawset(mt, k, v)
  end

  m.create = function (a, b, c)
    local res = NewVector2(a, b, c)
    for k, v in pairs(funcs) do
      rawset(res, k, v)
    end
    return res
  end

  for k, v in pairs(m.typeFuncs(typeMt, mt)) do
    rawset(typeMt, k, v)
  end

  rawset(Vector2, 'static_zero', Vector2.new(0, 0))
  rawset(Vector2, 'static_one', Vector2.new(1, 1))
end

function m.typeFuncs(typeMt, objMt)
  local mt = {}

  mt.new = function (x, y)
    if x and not y then
      y = x[2]; x = x[1]
    end
    return m.create(Vector2, x or 0, y or 0)
  end

  -- convert a plain lua table to Vector3
  mt.as = function (t)
    if m.debug then
      assert(rawget(t, 1), rawget(t, 2),
        'Vector2.as with nil values')
    end
    return m.create(Vector2, t[1], t[2])
  end

  -- convert a plain lua table to Vector2
  mt.fromTable = function (t)
    local v
    if t[1] then
      v = Vector2(t[1], t[2])
    else
      v = Vector2(t.x or 0, t.y or 0)
    end
    if m.debug then
      assert(rawget(v, 1), rawget(v, 2),
        'Vector2.fromTable with nil values')
    end
    return v
  end

  mt.borrow = function () return pool:borrow() end

  if unity.useStructPooling then
    function mt.__call(t, x, y)
      local v = pool:borrow()
      if not x then
        v[1] = 0; v[2] = 0
      elseif not y then
        v[1] = x[1]; v[2] = x[2]
      else
        v[1] = x; v[2] = y
      end
      if m.debug then
        assert(rawget(v, 1), rawget(v, 2),
          'Vector2.__call with nil values')
      end
      return v
    end
  else
    function mt.__call(t, x, y)
      if not x then
        return NewVector2(t, 0, 0)
      elseif not y then
        return NewVector2(t, x[1], x[2])
      else
        return NewVector2(t, x, y)
      end
    end
  end


  return mt
end

function m.funcs(oldMt)
  local mt = {}

  function mt.toTable(self)
    return {self[1], self[2]}
  end

   -- one-ize
  function mt.onize(self)
    local x, y = abs(self[1]), abs(self[2])
    x = x > 0 and self[1] / x or self[1]
    y = y > 0 and self[2] / y or self[2]
    return Vector2(x, y)
  end

  function mt.rotate(self, angle)
    local rad = rad(angle)
    local c, s = cos(rad), sin(rad)
    return Vector2(c * self[1] - s * self[2], s * self[1] + c * self[2])
  end

  function mt.len(self)
    return Vector2.Magnitude(self)
  end

  function mt.len2(self)
    return Vector2.SqrMagnitude(self)
  end

  function mt.dist(self, other)
    return Vector2.Distance(self, other)
  end

  function mt.dist2(self, other)
    -- return Vector2.SqrMagnitude(self - other)
    local x = self[1] - other[1]
    local y = self[2] - other[2]
    return (x^2 + y^2)
  end

  function mt.resize(self, length)
    return self.normalized * length
  end

  function mt.trim(self, length)
    return Vector2.ClampMagnitude(self, length)
  end

  function mt.perpendicular(self)
    return Vector2(self[2], -self[1])
  end

  function mt.project(self, v)
    local len2 = v:len2()
    if len2 < Epsilon then return Vector2.zero end
    local s = self:dot(v) / len2
    return Vector2(s * v[1], s * v[2])
  end

  function mt.projectOnCircle(self, center, radius)
    return (self - center):resize(radius) + center
  end

  function mt.dot(self, other)
    return Vector2.Dot(self, other)
  end

  function mt.dirTo(self, other)
    return Vector2.Normalized(other - self)
  end

  function mt.radTo(self, other)
    return atan2(self[2], self[1]) - atan2(other[2], other[1])
  end

  function mt.angle(self, other)
    return Vector2.Angle(self, other)
  end

  function mt.degTo(self, other)
    local rad = self:radTo(other)
    return deg(rad)
  end

  function mt.lerp(self, dest, t)
    return Vector2.Lerp(self, dest, t)
  end

  function mt.__mul(self, b)
    return Vector2(self[1] * b, self[2] * b)
  end

  function mt.set(self, x, y)
    if not x then
      self[1] = 0
      self[2] = 0
    elseif not y then
      self[1] = x[1]
      self[2] = x[2]
    else
      self[1] = x
      self[2] = y
    end
    return self
  end

  --------------------------------------------------------------
  -- reduce number of instance methods, to save copy time when new()

  --[[

  -- plane is xz, xy, or yz
  function mt.toVector3(self, plane)
    if plane == 'yz' then
      return self:toVector3YZ()
    elseif plane == 'xy' then
      return self:toVector3XY()
    else
      -- default is xz plane
      return self:toVector3XZ()
    end
  end

  function mt.toVector3XZ(self)
    return Vector3(self[1], 0, self[2])
  end

  function mt.toVector3XY(self)
    return Vector3(self[1], self[2], 0)
  end

  function mt.toVector3YZ(self)
    return Vector3(0, self[1], self[2])
  end

  -- clone self but with the new x
  function mt.X(self, x)
    return Vector2(x, self[2])
  end

  -- clone self but with the new y
  function mt.Y(self, y)
    return Vector2(self[1], y)
  end

  function mt.clone(self)
    return Vector2(self[1], self[2])
  end

  function mt.mirror(self, normal)
    return Vector2.Reflect(self, normal.normalized) * -1
  end

  function mt.reflect(self, normal)
    return Vector2.Reflect(self, normal.normalized)
  end

  function mt.isOpposite(self, other)
    return self:dot(other) < 0
  end

  function mt.acuteRad(self, other)
    local degree = self:angle(other)
    return rad(degree)
  end

  function mt.moveTowards(self, dest, maxDistDelta)
    return Vector2.MoveTowards(self, dest, maxDistDelta)
  end

  ]]

  return mt
end


setmetatable(m, {__call = function(t, ...) m.decorate(...) end })
