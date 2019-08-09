
local floor, max, min, random, pow = math.floor, math.max, math.min, math.random, math.pow

function math.round(num, decimalPlaces)
  if not num then return 0 end

  if not decimalPlaces then
    return floor(num + 0.5)
  else
    return floor(pow(10, decimalPlaces) * num + 0.5)/pow(10, decimalPlaces)
  end
end

function math.comma(num)
    if type(tonumber(num)) ~= "number" then num = 0 end
    local formatted = tostring(num)
    while true do
        formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
        if k == 0 then break end
    end
    return formatted
end

function math.clamp(val, min_val, max_val)
  return max(min(val, max_val), min_val)
end

function math.randf(low, high)
  return random()*(high-low)+low
end

function math.lerpf(low, high, t)
  return (high-low)*t + low
end

function math.smooth_stepf(low, high, t)
  t = 3*t^2 - 2*t^3
  return math.lerpf(low, high, t)
end

function math.sqr(value)
  return value * value
end

function math.sign(value)
  return (value < 0 and -1) or 1
end

function math.ratio(low, high, cur)
  return (cur - low) / (high - low)
end

-- simple but not efficient
function math.nextPowerOfTwo(value)
  local res = 1
  while res < value do
    res = res * 2
  end
  return res
end








