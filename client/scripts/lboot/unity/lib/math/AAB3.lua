-- axis aligned bounding box in 3D

class('AAB3', function(self, vecMin, vecMax)
  self.min = vecMin or Vector3.zero
  self.max = vecMax or Vector3.zero
  self:init()
end)

local m = AAB3
local Bounds = UnityEngine.Bounds
local Vector3 = UnityEngine.Vector3

function m:init()
  self.center = Vector3.zero
  self.extents = Vector3.zero
  self:calcCenter()
  self:calcExtents()
end

function m.createFromPoint(p)
  local aab = AAB3.new()
  aab.min = p:clone()
  aab.max = p:clone()
  return aab
end

function m.create(points)
  if #points == 0 then return m.createFromPoint(Vector3.zero) end

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
  self.center[3] = 0.5 * (self.max[3] + self.min[3])
  return self.center
end

function m:calcExtents()
  self.extents[1] = 0.5 * (self.max[1] - self.min[1])
  self.extents[2] = 0.5 * (self.max[2] - self.min[2])
  self.extents[3] = 0.5 * (self.max[3] - self.min[3])
  return self.extents
end

function m:calcVolume()
  return (self.max[2] - self.min[2]) * (self.max[1] - self.min[1]) * (self.max[3] - self.min[3])
end

function m:calcVerts()
  self.verts = {}
  self.verts[1] = self.min:clone()
  self.verts[2] = Vector3(self.max[1], self.min[2], self.min[3])
  self.verts[3] = Vector3(self.max[1], self.max[2], self.min[3])
  self.verts[4] = Vector3(self.min[1], self.max[2], self.min[3])
  self.verts[5] = Vector3(self.min[1], self.min[2], self.max[3])
  self.verts[6] = Vector3(self.max[1], self.min[2], self.max[3])
  self.verts[7] = self.max:clone()
  self.verts[8] = Vector3(self.min[1], self.max[2], self.max[3])
  return self.verts
end

function m:contains(p)
  return p[1] >= self.min[1] and
    p[1] <= self.max[1] and
    p[2] >= self.min[2] and
    p[2] <= self.max[2] and
    p[3] >= self.min[3] and
    p[3] <= self.max[3]
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

  if p[3] < self.min[3] then
    self.min[3] = p[3]
  elseif p[3] > self.max[3] then
    self.max[3] = p[3]
  end
end

function m:encapsulate(other)
  self:extendTo(other.min)
  self:extendTo(other.max)
end

function m.fromBounds(bound)
  return AAB3.new(bound.min, bound.max)
end

function m:toBounds()
  self:calcCenter()
  self:calcExtents()
  local bound = Bounds(self.center, Vector3.zero)
  bound.extents = self.extents
  return bound
end