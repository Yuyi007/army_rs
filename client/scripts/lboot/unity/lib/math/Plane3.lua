-- 3D plane math representation
class('Plane3', function(self, normal, point)
  self.normal = Vector3.new()
  self.point = Vector3.new()

  self:setNormalPoint(normal, point)
end)

local m = Plane3
local abs = math.abs

function m:setNormalPoint(normal, point)
  self.normal:set(normal)
  self.point:set(point)

  self.constant = normal:dot(point)
end

function m:dist(point)
  return abs(self.normal:dot(point) - self.constant)
end

function m:distXYZ(x, y, z)
  local normal = self.normal
  return abs(normal[1] * x + normal[2] * y + normal[3] * z - self.constant)
end

function m:origin()
  return self.normal * self.constant
end

function m:degTo(other)
  return self.normal:degTo(other.normal)
end

function m:angle(other)
  return self.normal:angle(other.normal)
end

function m:project(point)
  return (point - self.point):projectOnPlane(self.normal) + self.point
end

