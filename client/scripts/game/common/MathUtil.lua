class('MathUtil')

local Quaternion = UnityEngine.Quaternion
local Epsilon    = UnityEngine.Mathf.Epsilon
local math = math

function MathUtil.floatEqual(f1, f2)
  if math.abs(f1 - f2) <= 0.000001 then
    return true
  end
  return false
end

function MathUtil.dist(p1, p2)
  -- return math.sqrt((p1.x - p2.x) * (p1.x - p2.x) + (p1.y - p2.y) * (p1.y - p2.y) + (p1.z - p2.z) * (p1.z - p2.z))
  return math.sqrt((p1[1] - p2[1]) * (p1[1] - p2[1]) + (p1[2] - p2[2]) * (p1[2] - p2[2]) + (p1[3] - p2[3]) * (p1[3] - p2[3]))
end

function MathUtil.dist2(p1, p2)
  -- return (p1.x - p2.x) * (p1.x - p2.x) + (p1.y - p2.y) * (p1.y - p2.y) + (p1.z - p2.z) * (p1.z - p2.z)
  return (p1[1] - p2[1]) * (p1[1] - p2[1]) + (p1[2] - p2[2]) * (p1[2] - p2[2]) + (p1[3] - p2[3]) * (p1[3] - p2[3])
end

function MathUtil.dist2XZ(p1, p2)
   return (p1[1] - p2[1]) * (p1[1] - p2[1]) + (p1[3] - p2[3]) * (p1[3] - p2[3])
end

function MathUtil.distance(pos1, pos2, num)
  num = num or 2
  local dist = Vector3.Distance(pos1, pos2)
  return MathUtil.GetPreciseDecimal(dist, num)
end

function MathUtil.GetPreciseDecimal(nNum, n)
  if type(nNum) ~= "number" then
    return nNum;
  end

  n = n or 0
  n = math.floor(n)
  if n < 0 then n = 0 end

  local nDecimal = 10 ^ n
  local nTemp    = math.floor(nNum * nDecimal)
  local nRet     = nTemp / nDecimal

  return nRet
end

function MathUtil.getLineCircleIntersection(p, center, radius)
  return p:projectOnCircle(center, radius)
end

function MathUtil.randDirXY()
  return Random.dir2()
end

function MathUtil.sceneToUI(transFrom, transTo, pos)
end

function MathUtil.mat2Quaterion(m)
  local q = Quaternion.identity
  q.w = math.sqrt(math.max(0, 1 + m.m00 + m.m11 + m.m22)) / 2
  q.x = math.sqrt(math.max(0, 1 + m.m00 - m.m11 - m.m22)) / 2
  q.y = math.sqrt(math.max(0, 1 - m.m00 + m.m11 - m.m22)) / 2
  q.z = math.sqrt(math.max(0, 1 - m.m00 - m.m11 + m.m22)) / 2
  q.x = q.x * math.sign(q.x * (m.m21 - m.m12))
  q.y = q.y * math.sign(q.y * (m.m02 - m.m20))
  q.z = q.z * math.sign(q.z * (m.m10 - m.m01))
  return q
end


function MathUtil.getRotationByVelocity(velocity, isFaceLeft)
  if math.abs(velocity[2]) < Epsilon then
    return 0
  end
  local x = math.abs(velocity[1])
  local y = velocity[2]
  local radVal = math.atan2(y, x)
  local degVal = math.deg(radVal)
  local flip = isFaceLeft and (-1) or 1
  return degVal*flip
end


function MathUtil.randomByWeight(totalWeight, items)
  local r = math.random(totalWeight)
  local w = 0
  for i=1, #items do
    local min = w
    local sw = items[i].weight or 0

    sw = tonumber(sw)
    if not sw then
      sw = tonumber(items[i].weight)
    end

    local max = w + sw
    if r > min and r <= max then
      return i
    end
    w = max
  end
  return 1
end

function MathUtil.dirToDeg(dir)
  local rad = math.atan2(dir.z, dir.x)
  return 180 - math.deg(rad)
end


