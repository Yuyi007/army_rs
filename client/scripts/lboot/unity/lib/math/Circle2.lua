-- A circle representation in 2d

class('Circle2', function(self, center, radius)
  self.center = center:clone()
  self.radius = radius
end)

local m       = Circle2
local Epsilon = UnityEngine.Mathf.Epsilon
local sqrt    = math.sqrt
local sqr     = math.sqr
local cos     = math.cos
local sin     = math.sin
local acos    = math.acos

-- create a circle which just encapsulates the aab
function m.createFromAAB(aab2)
  aab2:calcCenter()
  aab2:calcExtents()
  return Circle2.new(aab2.center, aab2.extents:len())
end

function m:clone()
  return Circle2.new(self.center, self.dir)
end

-- create a circle which just encapsulates all the points
function m.createFromPoints(points)
  local aab2 = AAB2.create(points)
  return m.createFromAAB(aab2)
end

function m:calcArea()
  return math.pi * sqr(self.radius)
end

function m:calcPerimeter()
  return 2 * math.pi * self.radius
end

function m:contains(p)
  return p:dist2(self.center) <= sqr(self.radius)
end

-- the distance from the circle edge to the point
function m:dist(point)
  local dist = point:dist(self.center) - self.radius
  if dist <= 0 then return 0 end
  return dist
end

-- enlarge the circle so that it just encapsulates the original circle and the new circle
function m:include(circle)
  local v = circle.center - self.center
  local len2 = v:len2()
  local rdiff = circle.radius - self.radius
  local rdiff2 = sqr(rdiff)
  if rdiff2 >= len2 then
    if rdiff >= 0 then
      self.center = circle.center:clone()
      self.radius = circle.radius
      return
    end
  end

  local len = sqrt(len2)
  if len > Epsilon then
    local length = (len + rdiff) / (2 * len)
    self.center = self.center + v * length
  end

  self.radius = 0.5 * (len + self.radius + circle.radius)
end

-- get a point centered on circle given the radian and radius
-- param radius is the radius of circle by default
function m:getPoint(rad, radius)
  radius = radius or self.radius
  return Vector2(radius * cos(rad), radius * sin(rad)) + self.center
end

-- get the point projected on the circle edge
function m:projected(point)
  return point:projectOnCircle(self.center, self.radius)
end

-- circle equation
-- (x - h) ^ 2 + (y - k) ^ 2 = radius ^ 2
-- x ^ 2 + y ^ 2 + ax + by + c = 0
function m:equation()
  local h, k = self.center[1], self.center[2]
  local r = self.radius
  local a = h * -2
  local b = k * -2
  local c = sqr(k) + sqr(h) - sqr(r)
  return a, b, c
end