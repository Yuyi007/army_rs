-- In our code, three representation of Vector3:
--
-- 1. Vector3 object: {x, y, z} with a metatable of UnityEngine.Vector3
-- 2. An array: {x, y, z} without the Vector3 metatable
-- 3. A hash table: {x=x, y=y, z=z} without the Vector3 metatable
--
-- Where are the three representations used:
--
-- 1. The hash table representation are used in configs solely. (for historic reasons)
--
-- 2. The array representation are used as pre and post serialization format for Vector3,
--    in action messages more specifically. The elixir and ruby servers also use the array
--    representation for Vector3.
--
-- 3. Any else place in lua code, Vector3 object should be used.
--
-- 4. You can use Vector3.fromTable(), Vector3.as() to convert plain lua tables to Vector3
--    objects.
--

class('Vector3Decorator')

local m          = Vector3Decorator
local Vector3    = UnityEngine.Vector3
local Vector2    = UnityEngine.Vector2
local Quaternion = UnityEngine.Quaternion
local NewVector3 = getmetatable(Vector3).__call
local pool       = FramePool.new(function () return m.create(Vector3, 0, 0, 0) end, {
  initSize = 0, maxSize = 8192, tag = 'Vector3', objectMt = getmetatable(NewVector3(Vector3, 0, 0, 0)),
})

local assert, rawget, rawset, setmetatable = assert, rawget, rawset, setmetatable
local cos, sin   = math.cos, math.sin
local abs, sqrt  = math.abs, math.sqrt
local deg, rad   = math.deg, math.rad

function m.decorate()
  local typeMt = getmetatable(Vector3)
  local mt = getmetatable(Vector3.zero)

  local funcs = m.funcs(mt)
  for k, v in pairs(funcs) do
    rawset(mt, k, v)
  end

  m.create = function (a, b, c, d)
    local res = NewVector3(a, b, c, d)
    for k, v in pairs(funcs) do
      rawset(res, k, v)
    end
    return res
  end

  for k, v in pairs(m.typeFuncs(typeMt, mt)) do
    rawset(typeMt, k, v)
  end

  -- For identifying uninitialized Vector3, use with caution
  rawset(Vector3, 'static_null', Vector3.new(-999999, -999999, -999999))

  rawset(Vector3, 'static_zero', Vector3.new(0, 0, 0))
  rawset(Vector3, 'static_one', Vector3.new(1, 1, 1))
  rawset(Vector3, 'static_up', Vector3.new(Vector3.up))
  rawset(Vector3, 'static_down', Vector3.new(Vector3.down))
  rawset(Vector3, 'static_left', Vector3.new(Vector3.left))
  rawset(Vector3, 'static_right', Vector3.new(Vector3.right))
  rawset(Vector3, 'static_forward', Vector3.new(Vector3.forward))
  rawset(Vector3, 'static_back', Vector3.new(Vector3.back))
end

function m.typeFuncs(typeMt, objMt)
  local mt = {}

  -- you can safely call Vector3.new(nil), Vector3.new(vector3), Vector3.new(x, y, z)
  mt.new = function (x, y, z)
    if x and not y then
      y = x[2]; z = x[3]; x = x[1]
    end
    return m.create(Vector3, x or 0, y or 0, z or 0)
  end

  -- convert a plain lua table to Vector3
  mt.as = function (t)
    if m.debug then
      assert(rawget(t, 1) and rawget(t, 2) and rawget(t, 3),
        'Vector3.as with nil values')
    end
    return m.create(Vector3, t[1], t[2], t[3])
  end

  -- convert a plain lua table to Vector3
  mt.fromTable = function (t)
    local v
    if t[1] then
      v = Vector3(t[1], t[2], t[3])
    else
      v = Vector3(t.x or 0, t.y or 0, t.z or 0)
    end
    if m.debug then
      assert(rawget(v, 1) and rawget(v, 2) and rawget(v, 3),
        'Vector3.fromTable with nil values')
    end
    return v
  end

  mt.borrow = function () return pool:borrow() end

  if unity.useStructPooling then
    function mt.__call(t, x, y, z)
      local v = pool:borrow()
      if not x then
        v[1] = 0; v[2] = 0; v[3] = 0
      elseif not y then
        v[1] = x[1]; v[2] = x[2]; v[3] = x[3]
      else
        -- if not rawget(v, 3) then
        --   error(string.format('v=%s', peek(v)))
        -- end
        v[1] = x; v[2] = y; v[3] = z
      end
      if m.debug then
        assert(rawget(v, 1) and rawget(v, 2) and rawget(v, 3),
          'Vector3.__call with nil values')
      end
      return v
    end
  else
    function mt.__call(t, x, y, z)
      if not x then
        return NewVector3(t, 0, 0, 0)
      elseif not y then
        return NewVector3(t, x[1], x[2], x[3])
      else
        return NewVector3(t, x, y, z)
      end
    end
  end

  return mt
end

function m.funcs(oldMt)
  local mt = {}

  -- convert a vector3 to a plain lua table
  function mt.toTable(self)
    return {self[1], self[2], self[3]}
  end

  function mt.toXYZTable(self)
    return {x = self[1], y = self[2], z = self[3]}
  end

  -- one-ize
  function mt.onize(self)
    local x, y, z = abs(self[1]), abs(self[2]), abs(self[3])
    x = x > 0 and self[1] / x or self[1]
    y = y > 0 and self[2] / y or self[2]
    z = z > 0 and self[3] / z or self[3]
    return Vector3(x, y, z)
  end

  -- rotate around y with deg
  -- left-handed rule
  function mt.rotateAroundY(self, deg)
    local rad = rad(deg)
    local x, y, z = self[1], self[2], self[3]
    local cosv = cos(rad)
    local sinv = sin(rad)
    local nx = sinv * z + cosv * x
    local nz = cosv * z - sinv * x
    return Vector3(nx, y, nz)
  end

  -- rotate round x with deg
  -- left-handed rule
  function mt.rotateAroundX(self, deg)
    local rad = rad(deg)
    local x, y, z = self[1], self[2], self[3]
    local cosv = cos(rad)
    local sinv = sin(rad)
    local ny = cosv * y - sinv * z
    local nz = sinv * y + cosv * z
    return Vector3(x, ny, nz)
  end

  -- rotate around z with deg
  -- left-handed rule
  function mt.rotateAroundZ(self, deg)
    local rad = rad(deg)
    local x, y, z = self[1], self[2], self[3]
    local cosv = cos(rad)
    local sinv = sin(rad)
    local nx = cosv * x - sinv * y
    local ny = sinv * x + cosv * y
    return Vector3(nx, ny, z)
  end

  -- the length (magnitude)
  function mt.len(self)
    return Vector3.Magnitude(self)
  end

  -- the length ^ 2
  function mt.len2(self)
    return Vector3.SqrMagnitude(self)
  end

  -- distance between self to other
  function mt.dist(self, other)
    return Vector3.Distance(self, other)
  end

  -- distance ^ 2 between self to other
  function mt.dist2(self, other)
    -- return (self - other).sqrMagnitude
    local x = self[1] - other[1]
    local y = self[2] - other[2]
    local z = self[3] - other[3]
    return (x^2 + y^2 + z^2)
  end

  -- clone self and make sure the magnitude doesnt exceed length
  function mt.trim(self, length)
    return Vector3.ClampMagnitude(self, length)
  end

  -- acute angle in degree
  function mt.angle(self, other)
    return Vector3.Angle(self, other)
  end

  -- dot product
  function mt.dot(self, other)
    return Vector3.Dot(self, other)
  end

  -- cross product, getting the normal vector defining the plane formed by self and the other
  function mt.cross(self, other)
    return Vector3.Cross(self, other)
  end

  -- project self (a directed vector) on the direction v
  function mt.project(self, v)
    return Vector3.Project(self, v)
  end

  -- project self (a directed vector) on the plane defined by normal
  function mt.projectOnPlane(self, normal)
    return Vector3.ProjectOnPlane(self, normal)
  end

  function mt.lerp(self, dest, t)
    return Vector3.Lerp(self, dest, t)
  end

  function mt.dirTo(self, other)
    -- return (other - self).normalized
    local x = other[1] - self[1]
    local y = other[2] - self[2]
    local z = other[3] - self[3]
    local m = sqrt(x^2 + y^2 + z^2)
    return Vector3(x/m, y/m, z/m)
  end

  -- fix vector3 multiplication gc alloc
  -- (mostly used in physics behaviours)
  function mt.__mul(self, b)
    return Vector3(self[1] * b, self[2] * b, self[3] * b)
  end

  -- you can safely use vector3:set(nil), vector3:set(vector), vector3:set(x, y, z)
  function mt.set(self, x, y, z)
    if not x then
      self[1] = 0
      self[2] = 0
      self[3] = 0
    elseif not y then
      self[1] = x[1]
      self[2] = x[2]
      self[3] = x[3]
    else
      self[1] = x
      self[2] = y
      self[3] = z
    end
    if m.debug then
      assert(rawget(self, 1) and rawget(self, 2) and rawget(self, 3),
        'Vector3.set with nil values')
    end
    return self
  end

  ---------------------------------------------------------------
  -- Optimization: expand operations to reduce Vector3() calls

  -- a * n + b
  function mt.mulNAdd(a, n, b)
    return Vector3(a[1] * n + b[1], a[2] * n + b[2], a[3] * n + b[3])
  end

  -- a - b * n
  function mt.minMulN(a, b, n)
    return Vector3(a[1] - b[1] * n, a[2] - b[2] * n, a[3] - b[3] * n)
  end

  -- a - b * Dot(a, b)
  function mt.minMulDot(a, b)
    local ax, ay, az = a[1], a[2], a[3]
    local bx, by, bz = b[1], b[2], b[3]
    local n = ax * bx + ay * by + az * bz
    return Vector3(ax - bx * n, ay - by * n, az - bz * n)
  end

  -- a + b - c * Dot(b, c)
  function mt.addMinMulDot(a, b, c)
    local bx, by, bz = b[1], b[2], b[3]
    local cx, cy, cz = c[1], c[2], c[3]
    local n = bx * cx + by * cy + bz * cz
    return Vector3(a[1] + bx - cx * n, a[2] + by - cy * n, a[3] + bz - cz * n)
  end

  -- a - Scale(b, c)
  function mt.minScale(a, b, c)
    return Vector3(a[1] - b[1] * c[1], a[2] - b[2] * c[2], a[3] - b[3] * c[3])
  end

  -- a * Dot(a, b - c)
  function mt.mulDotMin(a, b, c)
    local ax, ay, az = a[1], a[2], a[3]
    local dot = ax * (b[1] - c[1]) + ay * (b[2] - c[2]) + az * (b[3] - c[3])
    return Vector3(ax * dot, ay * dot, az * dot)
  end

  -- Optimization: expand operations to reduce Vector3() calls
  --------------------------------------------------------------

  --------------------------------------------------------------
  -- reduce number of instance methods, to save copy time when new()

  --[[

  -- convert to vector2 representation
  -- given a plane which is xz, xy, or yz
  function mt.toVector2(self, plane)
    if plane == 'yz' then
      return self:toVector2YZ()
    elseif plane == 'xy' then
      return self:toVector2XY()
    else
      -- default is xz plane
      return self:toVector2XZ()
    end
  end

  -- convert to vector2 representation on plane xz
  function mt.toVector2XZ(self)
    return Vector2(self[1], self[3])
  end

  -- convert to vector2 representation on plane xy
  function mt.toVector2XY(self)
    return Vector2(self[1], self[2])
  end

  -- convert to vector2 representation on plane yz
  function mt.toVector2YZ(self)
    return Vector2(self[2], self[3])
  end

  -- clone self but with the new x
  function mt.X(self, x)
    return Vector3(x, self[2], self[3])
  end

  -- clone self but with the new y
  function mt.Y(self, y)
    return Vector3(self[1], y, self[3])
  end

  -- clone self but with the new z
  function mt.Z(self, z)
    return Vector3(self[1], self[2], z)
  end

  -- decide if self and the other is in opposite direction
  function mt.isOpposite(self, other)
    return Vector3.Dot(self, other) < 0
  end

  -- rotate with respect to the given axis by angle degrees
  function mt.rotate(self, deg, axis)
    axis = axis or 'y'
    if axis == 'y' then
      return self:rotateAroundY(deg)
    elseif axis == 'x' then
      return self:rotateAroundX(deg)
    elseif axis == 'z' then
      return self:rotateAroundZ(deg)
    end
  end

  -- colone self and resize to the new magnitude length
  function mt.resize(self, length)
    return Vector3.Normalize(self) * length
  end

  -- reflect self (a directed vector)  with repsect to the plane defined by normal
  function mt.reflect(self, normal)
    return Vector3.Reflect(self, normal)
  end

  -- project self (a point) on the sphere defined by center and radius
  function mt.projectOnSphere(self, center, radius)
    return (self - center):resize(radius) + center
  end

  function mt.clone(self)
    return Vector3(self[1], self[2], self[3])
  end

  function mt.moveTowards(self, dest, maxDistDelta)
    return Vector3.MoveTowards(self, dest, maxDistDelta)
  end

  function mt.planeDirTo(self, other)
    local v1 = Vector3(self[1], 0, self[3])
    local v2 = Vector3(other[1], 0, other[3])
    return v1:dirTo(v2)
  end

  function mt.ignoreYAxis(self)
    return Vector2(self[1], self[3])
  end

  ]]


  return mt
end


setmetatable(m, {__call = function(t, ...) m.decorate(...) end })