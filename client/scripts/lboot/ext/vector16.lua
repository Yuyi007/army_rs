--[[
Fixed point math (16.16) vector
Based on Matthias Richter' vector
]]--

local assert = assert
local fix16 = require 'lboot/ext/fix16'
local sqrt, cos, sin, atan2 = fix16.sqrt, fix16.cos, fix16.sin, fix16.atan2

local vector = {}
vector.__index = vector

local function isfix16(v)
  return type(v) == 'table' and type(v.x) == 'number' and type(v.sin) == 'function'
end

local function isvector(v)
  return type(v) == 'table' and type(v.x) == 'table' and type(v.y) == 'table' and
    type(v.normalized) == 'function'
end

local function new(x,y)
  if vector.debug then
    if x then assert(isfix16(x), "vector: wrong argument types (<fix16> expected)") end
    if y then assert(isfix16(y), "vector: wrong argument types (<fix16> expected)") end
  end
  return setmetatable({x = x or fix16(0), y = y or fix16(0)}, vector)
end
local function create(x, y)
  return new(x and fix16(x) or nil, y and fix16(y) or nil)
end
local zero = new(fix16(0),fix16(0))

function vector:clone()
  return new(self.x, self.y)
end

function vector:unpack()
  return self.x, self.y
end

function vector:__tostring()
  return "("..tostring(self.x)..","..tostring(self.y)..")"
end

function vector.__unm(a)
  return new(-a.x, -a.y)
end

function vector.__add(a,b)
  if vector.debug then
    assert(isvector(a) and isvector(b), "Add: wrong argument types (<vector16> expected)")
  end
  return new(a.x+b.x, a.y+b.y)
end

function vector.__sub(a,b)
  if vector.debug then
    assert(isvector(a) and isvector(b), "Sub: wrong argument types (<vector16> expected)")
  end
  return new(a.x-b.x, a.y-b.y)
end

function vector.__mul(a,b)
  if type(a) == 'number' or isfix16(a) then
    return new(a*b.x, a*b.y)
  elseif type(b) == 'number' or isfix16(b) then
    return new(b*a.x, b*a.y)
  else
    if vector.debug then
      assert(isvector(a) and isvector(b), "Mul: wrong argument types (<vector16> or <fix16> expected)")
    end
    return a.x*b.x + a.y*b.y
  end
end

function vector.__div(a,b)
  if type(b) == 'number' then
    b = fix16(b)
    return new(a.x / b, a.y / b)
  else
    if vector.debug then
      assert(isvector(a) and isfix16(b), "wrong argument types (expected <vector16> / <fix16>)")
    end
    return new(a.x / b, a.y / b)
  end
end

function vector.__eq(a,b)
  return a.x == b.x and a.y == b.y
end

function vector.__lt(a,b)
  return a.x < b.x or (a.x == b.x and a.y < b.y)
end

function vector.__le(a,b)
  return a.x <= b.x and a.y <= b.y
end

function vector.permul(a,b)
  if vector.debug then
    assert(isvector(a) and isvector(b), "permul: wrong argument types (<vector16> expected)")
  end
  return new(a.x*b.x, a.y*b.y)
end

function vector:len2()
  return self.x * self.x + self.y * self.y
end

function vector:len()
  return sqrt(self.x * self.x + self.y * self.y)
end

function vector.dist(a, b)
  if vector.debug then
    assert(isvector(a) and isvector(b), "dist: wrong argument types (<vector16> expected)")
  end
  local dx = a.x - b.x
  local dy = a.y - b.y
  return sqrt(dx * dx + dy * dy)
end

function vector.dist2(a, b)
  if vector.debug then
    assert(isvector(a) and isvector(b), "dist: wrong argument types (<vector16> expected)")
  end
  local dx = a.x - b.x
  local dy = a.y - b.y
  return (dx * dx + dy * dy)
end

function vector:normalize_inplace()
  local l = self:len()
  if l:gt(0) then
    self.x, self.y = self.x / l, self.y / l
  end
  return self
end

function vector:normalized()
  return self:clone():normalize_inplace()
end

function vector:rotate_inplace(phi)
  local c, s = cos(phi), sin(phi)
  self.x, self.y = c * self.x - s * self.y, s * self.x + c * self.y
  return self
end

function vector:rotated(phi)
  local c, s = cos(phi), sin(phi)
  return new(c * self.x - s * self.y, s * self.x + c * self.y)
end

function vector:perpendicular()
  return new(-self.y, self.x)
end

function vector:projectOn(v)
  if vector.debug then
    assert(isvector(v), "invalid argument: cannot project vector16 on " .. type(v))
  end
  -- (self * v) * v / v:len2()
  local s = (self.x * v.x + self.y * v.y) / (v.x * v.x + v.y * v.y)
  return new(s * v.x, s * v.y)
end

function vector:mirrorOn(v)
  if vector.debug then
    assert(isvector(v), "invalid argument: cannot mirror vector16 on " .. type(v))
  end
  -- 2 * self:projectOn(v) - self
  local s = 2 * (self.x * v.x + self.y * v.y) / (v.x * v.x + v.y * v.y)
  return new(s * v.x - self.x, s * v.y - self.y)
end

function vector:cross(v)
  if vector.debug then
    assert(isvector(v), "cross: wrong argument types (<vector16> expected)")
  end
  return self.x * v.y - self.y * v.x
end

-- ref.: http://blog.signalsondisplay.com/?p=336
function vector:trim_inplace(maxLen)
  if type(maxLen) == 'number' then
    maxLen = fix16(maxLen)
  end
  local s = maxLen * maxLen / self:len2()
  s = (s:gt(1) and 1) or sqrt(s)
  self.x, self.y = self.x * s, self.y * s
  return self
end

function vector:angleTo(other)
  if other then
    return atan2(self.y, self.x) - atan2(other.y, other.x)
  end
  return atan2(self.y, self.x)
end

function vector:trimmed(maxLen)
  return self:clone():trim_inplace(maxLen)
end


-- the module
return setmetatable({new = new, isvector = isvector, zero = zero,
  create = create},
{__call = function(_, ...) return new(...) end})