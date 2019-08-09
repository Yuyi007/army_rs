-- A line representation in 2d

class('Line2', function(center, dir)
  self.center = center:clone()
  self.dir = Vector3.Normalize(dir)
end)

local m       = Line2
local Epsilon = UnityEngine.Mathf.Epsilon
local sqrt    = math.sqrt
local sqr     = math.sqr
local cos     = math.cos
local sin     = math.sin
local acos    = math.acos

function m.createWith2Points(p1, p2)
  return Line2.new(p1, p2 - p1)
end

function m:clone()
  return Line2.new(self.center, self.dir)
end

-- get the perpendicular line
function m:perpendicular(point)
  return Line2.new(point, self.dir:perpendicular())
end

function m:isParallel(line)
  local dot = self.dir:dot(line.dir)
  return dot == 1 or dot == -1
end

function m:getParallelLine(param)
  if type(param) == 'number' then
    local dist = param
    return self:parallelWithDistance(dist)
  else
    local point = param
    return Line2.new(point, self.dir)
  end
end

function m:getParallelLineWithDistance(dist)
  local line = Line2.new(self.center, self.dir)
  line.center = self.center + self.dir:perpendicular() * dist
  return line
end

-- the radian between self to the line
function m:radTo(line)
  return self.dir:radTo(line.dir)
end

-- distance between self to the point
function m:dist(point)
  local p = self:projected(point)
  return p:dist(point)
end

-- get a point along the line with length starting from center
function m:getPoint(length)
  return self.center + self.dir * length
end

-- get the projection of the point on the line
function m:projected(point)
  return (point - self.center):project(self.dir) + self.center
end

-- the line can be described as
-- ax + by = c
-- we need the a, b and c
function m:equation()
  local p1, p2 = self.center, self:getPoint(2)
  local a = p2[2] - p1[2]
  local b = p1[1] - p2[1]
  local c = a * p1[1] + b * p1[2]
  return a, b, c
end

-- get the intersected point of self to the line
function m:intersection(line)
  if self:isParallel(line) then return nil end
  local a1, b1, c1 = self:equation()
  local a2, b2, c2 = line:equation()

  local delta = a1 * b2 - a2 * b1
  if delta == 0 then return nil end
  local x = (b2 * c1 - b1 * c2) / delta
  local y = (a1 * c2 - a2 * c1) / delta
  return Vector2(x, y)
end

-- get the intersected point(s) between self to the circle (Circle2)
function m:intersectionOnCircle(circle)
  local dist = self:dist(circle.center)
  if dist > circle.radius then return {} end

  local v = self.center - circle.center
  local a = v:len2() - sqr(radius)
  local b = self.dir:dot(v)
  local c = b * b - a
  if c > Epsilon then
    c = sqrt(c)
    local t0 = -b - c
    local t1 = -b + c
    local p1 = self:getPoint(t0)
    local p2 = self:getPoint(t1)
    return {p1, p2}
  else
    local t0 = -b
    local p = self:getPoint(t0)
    return {p}
  end
end


