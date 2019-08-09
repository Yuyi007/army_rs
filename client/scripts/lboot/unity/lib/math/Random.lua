class('Random')

local m       = Random
local random  = math.random
local randomf = math.randf
local sqrt    = math.sqrt
local sqr     = math.sqr
local cos     = math.cos
local sin     = math.sin
local acos    = math.acos

-- get a random point(vector2) inside the
-- circle centered at (0, 0) defined by radius
function m.inCircle(radius)
  local len = radius * sqrt(random())
  local rad = m.radian()
  local x   = len * cos(rad)
  local y   = len * sin(rad)
  return Vector2(x, y)
end

-- get a random point(vector2) on the
-- circle centered at (0, 0) defined by radius
function m.onCircle(radius)
  local rad = m.radian()
  local x   = radius * cos(rad)
  local y   = radius * sin(rad)
  return Vector2(x, y)
end

-- get a random point(vector2) on the
-- ring centered at (0, 0) defined by radiusMin and radiusMax
function m.inRing(radiusMin, radiusMax)
  if m.debug then
    assert(radiusMax > radiusMin, 'radiusMax must be larger than radiusMin')
  end

  local num = 2 / (sqr(radiusMax) - sqr(radiusMin))
  local len = sqrt(2 * random() / num + sqr(radiusMin))
  local rad = m.radian()
  local x   = len * cos(rad)
  local y   = len * sin(rad)
  return Vector2(x, y)
end

-- get a random point(vector3) inside the
-- sphere centered at (0, 0, 0) defined by radius
function m.inSphere(radius)
  local diameter = radius * 2
  local function calc() return random() * diameter - radius end
  local x, y, z = calc(), calc(), calc()
  while sqr(x) + sqr(y) + sqr(z) > sqr(radius) do
    x, y, z = calc(), calc(), calc()
  end

  return Vector3(x, y, z)
end

-- get a random point(vector3) on the
-- sphere centered at (0, 0, 0) defined by radius
function m.onSphere(radius)
  local s = m.radian()
  local t = acos(random() * 2 - 1)
  local x = radius * cos(s) * sin(t)
  local y = radius * sin(s) * sin(t)
  local z = radius * cos(t)
  return Vector3(x, y, z)
end

-- get a random point(vector2) inside the
-- square centered at (0, 0) defined by sideLength
function m.inSquare(sideLength)
  local max = sideLength * 0.5
  local min = -max
  local x   = randomf(min, max)
  local y   = randomf(min, max)
  return Vector2(x, y)
end

-- get a random point(vector2) on the
-- square centered at (0, 0) defined by sideLength
function m.onSquare(sideLength)
  local max = sideLength * 0.5
  local min = -max
  local b   = random(1, 4)
  local r   = randomf(min, max)
  if b == 1 then
    return Vector2(r, max)
  elseif b == 2 then
    return Vector2(r, min)
  elseif b == 3 then
    return Vector2(max, r)
  else
    return Vector2(min, r)
  end
end

-- get a random point(vector3) inside the
-- cube centered at (0, 0, 0) defined by sideLength
function m.inCube(sideLength)
  local max = sideLength * 0.5
  local min = -max;
  local x   = randomf(min, max)
  local y   = randomf(min, max)
  local z   = randomf(min, max)
  return Vector3(x, y, z)
end

-- get a random point(vector3) on the
-- cube centered at (0, 0, 0) defined by sideLength
function m.onCube(sideLength)
  local max = sideLength * 0.5
  local min = -max
  local b   = random(1, 6)
  local r1  = randomf(min, max)
  local r2  = randomf(min, max)
  if b == 1 then
    return Vector3(r1, r2, max)
  elseif b == 2 then
    return Vector3(r1, r2, min)
  elseif b == 3 then
    return Vector3(r1, max, r2)
  elseif b == 4 then
    return Vector3(r1, min, r2)
  elseif b == 5 then
    return Vector3(max, r1, r2)
  else
    return Vector3(min, r1, r2)
  end
end

-- get a random color
function m.color()
  return Color(random(), random(), random(), 1)
end

-- get a random radian
function m.radian()
  return random() * 6.283185
end

-- get a random degree
function m.degree()
  return random() * 360
end

-- get a random dir in 2d (vector2)
function m.dir2()
  return m.onCircle(1)
end

-- get a random dir in 3d (vector3)
function m.dir3()
  return m.onSphere(1)
end