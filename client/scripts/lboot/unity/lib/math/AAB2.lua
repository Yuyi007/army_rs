-- axis aligned bounding box in 2D

class('AAB2', function(self, vecMin, vecMax)
  self.min = vecMin or Vector2.zero
  self.max = vecMax or Vector2.zero
  self:init()
end)

local m = AAB2
local Rect = UnityEngine.Rect
local Vector2 = UnityEngine.Vector2

function m:init()
  self.center = Vector2.zero
  self.extents = Vector2.zero
  self:calcCenter()
  self:calcExtents()
end

function m.createFromPoint(p)
  local aab = AAB2.new()
  aab.min = p:clone()
  aab.max = p:clone()
  return aab
end

function m.create(points)
  if #points == 0 then return m.createFromPoint(Vector2.zero) end

  local p1 = points[1]
  local aab = m.createFromPoint(p1)
  for i = 2, #points do
    aab:extendTo(points[i])
  end
  return aab
end


function m:calcCenter()
  self.center[1] = 0.5 * (self.max[1] + self.min[1])
  self.center[2] = 0.5 * (self.max[2] + self.min[2])
  return self.center
end

function m:calcExtents()
  self.extents[1] = 0.5 * (self.max[1] - self.min[1])
  self.extents[2] = 0.5 * (self.max[2] - self.min[2])
  return self.extents
end

function m:calcArea()
  return (self.max[2] - self.min[2]) * (self.max[1] - self.min[1])
end

function m:calcVerts()
  self.verts = {}
  self.verts[1] = self.min:clone()
  self.verts[2] = Vector2(self.max[1], self.min[2])
  self.verts[3] = self.max:clone()
  self.verts[4] = Vector2(self.min[1], self.max[2])
  return self.verts
end

function m:contains(p)
  return p[1] >= self.min[1] and
    p[1] <= self.max[1] and
    p[2] >= self.min[2] and
    p[2] <= self.max[2]
end

function m:extendTo(p)
  if p[1] < self.min[1] then
    self.min[1] = p[1]
  elseif p[1] > self.max[1] then
    self.max[1] = p[1]
  end

  if p[2] < self.min[2] then
    self.min[2] = p[2]
  elseif p[2] > self.max[2] then
    self.max[2] = p[2]
  end
end

function m:encapsulate(other)
  self:extendTo(other.min)
  self:extendTo(other.max)
end

function m.fromRect(rect)
  return AAB2.new(Vector2(rect.xMin, rect.yMin), Vector2(rect.xMax, rect.yMax))
end

function m:toRect()
  return Rect.MinMaxRect(self.min[1], self.min[2], self.max[1], self.max[2])
end