--Fixed point math (16.16) class


local assert = assert
local fm = fixmath
local from_int, to_int = fm.fix16_from_int, fm.fix16_to_int
local from_dbl, to_dbl = fm.fix16_from_dbl, fm.fix16_to_dbl
local from_str, to_str = fm.fix16_from_str, fm.fix16_to_str
local abs, floor, ceil = fm.fix16_abs, fm.fix16_floor, fm.fix16_ceil
local min, max, clamp = fm.fix16_min, fm.fix16_max, fm.fix16_clamp
local add, sub, mul, div = fm.fix16_add, fm.fix16_sub, fm.fix16_mul, fm.fix16_div
local sadd, ssub, smul, sdiv = fm.fix16_sadd, fm.fix16_ssub, fm.fix16_smul, fm.fix16_sdiv
local mod = fm.fix16_mod
local lerp8, lerp16, lerp32 = fm.fix16_lerp8, fm.fix16_lerp16, fm.fix16_lerp32
local sin, cos, tan = fm.fix16_sin, fm.fix16_cos, fm.fix16_tan
local asin, acos, atan = fm.fix16_asin, fm.fix16_acos, fm.fix16_atan
local atan2 = fm.fix16_atan2
local rad_to_deg, deg_to_rad = fm.fix16_rad_to_deg, fm.fix16_deg_to_rad
local sqrt, sq = fm.fix16_sqrt, fm.fix16_sq
local exp, log = fm.fix16_exp, fm.fix16_log
local log2, slog2 = fm.fix16_log2, fm.fix16_slog2
local fix16_maximum, fix16_minimum = fm.fix16_maximum, fm.fix16_minimum
local fix16_overflow = fm.fix16_overflow

local fix16 = {}
fix16.__index = fix16

local function new_raw(x)
  return setmetatable({x = x or 0}, fix16)
end
local function new(x)
  return new_raw(from_dbl(x or 0))
end
local zero = new(0)
local one = new(1)
local maximum = new_raw(fix16_maximum)
local minimum = new_raw(fix16_minimum)
local pi = new_raw(fm.fix16_pi)
local pi_div_2 = new_raw(fm.fix16_pi / 2)
local pi_div_4 = new_raw(fm.PI_DIV_4)

local function isfix16(v)
  return type(v) == 'table' and type(v.x) == 'number' and type(v.sin) == 'function'
end

function fix16:__tostring()
  if self:is_overflow() then
    return "<overflow>"
  end
  local x = self:to_dbl()
  return tostring(x)
end

function fix16.__unm(a)
  return new_raw(-a.x)
end

function fix16.__add(a,b)
  if type(a) == "number" then
    return new_raw(sadd(from_dbl(a), b.x))
  elseif type(b) == "number" then
    return new_raw(sadd(a.x, from_dbl(b)))
  else
    if fix16.debug then
      assert(isfix16(a) and isfix16(b), "Add: wrong argument types (<fix16> expected)")
    end
    return new_raw(sadd(a.x, b.x))
  end
end

function fix16.__sub(a,b)
  if type(a) == "number" then
    return new_raw(ssub(from_dbl(a), b.x))
  elseif type(b) == "number" then
    return new_raw(ssub(a.x, from_dbl(b)))
  else
    if fix16.debug then
      assert(isfix16(a) and isfix16(b), "Sub: wrong argument types (<fix16> expected)")
    end
    return new_raw(ssub(a.x, b.x))
  end
end

function fix16.__mul(a,b)
  if type(a) == "number" then
    return new_raw(smul(from_dbl(a), b.x))
  elseif type(b) == "number" then
    return new_raw(smul(a.x, from_dbl(b)))
  else
    if fix16.debug then
      assert(isfix16(a) and isfix16(b), "Mul: wrong argument types (<fix16> or <number> expected)")
    end
    return new_raw(smul(a.x, b.x))
  end
end

function fix16.__div(a,b)
  if type(a) == "number" then
    return new_raw(sdiv(from_dbl(a), b.x))
  elseif type(b) == "number" then
    return new_raw(sdiv(a.x, from_dbl(b)))
  else
    if fix16.debug then
      assert(isfix16(a) and isfix16(b), "Div: wrong argument types (<fix16> or <number> expected)")
    end
    return new_raw(sdiv(a.x, b.x))
  end
end

function fix16.__eq(a,b)
  if fix16.debug then
    assert(isfix16(a) and isfix16(b), "Eq: wrong argument types (<fix16> or <number> expected)")
  end
  return a.x == b.x
end

function fix16.__lt(a,b)
  if fix16.debug then
    assert(isfix16(a) and isfix16(b), "Lt: wrong argument types (<fix16> or <number> expected)")
  end
  return a.x < b.x
end

function fix16.__le(a,b)
  if fix16.debug then
    assert(isfix16(a) and isfix16(b), "Le: wrong argument types (<fix16> or <number> expected)")
  end
  return a.x <= b.x
end

function fix16.eq(a, b)
  if type(a) == "number" then
    a = new(a)
  end
  if type(b) == "number" then
    b = new(b)
  end

  if fix16.debug then
    assert(isfix16(a) and isfix16(b), "Eq: wrong argument types (<fix16> or <number> expected)")
  end
  return a.x == b.x
end

function fix16.lt(a, b)
  if type(a) == "number" then
    a = new(a)
  end
  if type(b) == "number" then
    b = new(b)
  end

  if fix16.debug then
    assert(isfix16(a) and isfix16(b), "Lt: wrong argument types (<fix16> or <number> expected)")
  end
  return a.x < b.x
end


function fix16.le(a, b)
  if type(a) == "number" then
    a = new(a)
  end
  if type(b) == "number" then
    b = new(b)
  end

  if fix16.debug then
    assert(isfix16(a) and isfix16(b), "Le: wrong argument types (<fix16> or <number> expected)")
  end
  return a.x <= b.x
end

function fix16.gt(a, b)
  return not fix16.le(a, b)
end

function fix16.ge(a, b)
  return not fix16.lt(a, b)
end

function fix16.min(a, b)
  if type(a) == "number" then
    return new_raw(min(from_dbl(a), b.x))
  elseif type(b) == "number" then
    return new_raw(min(a.x, from_dbl(b)))
  else
    if fix16.debug then
      assert(isfix16(a) and isfix16(b), "Min: wrong argument types (<fix16> or <number> expected)")
    end
    return new_raw(min(a.x, b.x))
  end
end

function fix16.max(a, b)
  if type(a) == "number" then
    return new_raw(max(from_dbl(a), b.x))
  elseif type(b) == "number" then
    return new_raw(max(a.x, from_dbl(b)))
  else
    if fix16.debug then
      assert(isfix16(a) and isfix16(b), "Max: wrong argument types (<fix16> or <number> expected)")
    end
    return new_raw(max(a.x, b.x))
  end
end

function fix16.atan2(a, b)
  if type(a) == "number" then
    return new_raw(atan2(from_dbl(a), b.x))
  elseif type(b) == "number" then
    return new_raw(atan2(a.x, from_dbl(b)))
  else
    if fix16.debug then
      assert(isfix16(a) and isfix16(b), "Atan2: wrong argument types (<fix16> or <number> expected)")
    end
    return new_raw(atan2(a.x, b.x))
  end
end

function fix16:clone()
  return new_raw(self.x)
end

function fix16:to_int()
  return to_int(self.x)
end

function fix16:to_dbl()
  return to_dbl(self.x)
end

function fix16:to_deg()
  return new_raw(rad_to_deg(self.x))
end

function fix16:to_rad()
  return new_raw(deg_to_rad(self.x))
end

function fix16:to_str(decimals)
  return to_str(self.x, decimals)
end

function fix16:abs()
  return new_raw(abs(self.x))
end

function fix16:floor()
  return new_raw(floor(self.x))
end

function fix16:ceil()
  return new_raw(ceil(self.x))
end

function fix16:clamp(a, b)
  if type(a) == "number" then
    a = new(a)
  end
  if type(b) == "number" then
    b = new(b)
  end

  if fix16.debug then
    assert(isfix16(a) and isfix16(b), "Clamp: wrong argument types (<fix16> or <number> expected)")
  end
  return new_raw(clamp(self.x, a.x, b.x))
end

function fix16:mod(a)
  if type(a) == "number" then
    return new_raw(mod(self.x, from_dbl(a)))
  else
    if fix16.debug then
      assert(isfix16(a), "Mod: wrong argument types (<fix16> or <number> expected)")
    end
    return new_raw(mod(self.x, a.x))
  end
end

-- self as rad
function fix16:sin()
  return new_raw(sin(self.x))
end

-- self as rad
function fix16:cos()
  return new_raw(cos(self.x))
end

-- self as rad
function fix16:tan()
  return new_raw(tan(self.x))
end

-- self as degree
function fix16:deg_sin()
  return new_raw(sin(self:to_rad().x))
end

-- self as degree
function fix16:deg_cos()
  return new_raw(cos(self:to_rad().x))
end

-- self as degree
function fix16:deg_tan()
  return new_raw(tan(self:to_rad().x))
end

function fix16:asin()
  return new_raw(asin(self.x))
end

function fix16:acos()
  return new_raw(acos(self.x))
end

function fix16:atan()
  return new_raw(atan(self.x))
end

function fix16:sqrt()
  return new_raw(sqrt(self.x))
end

function fix16:sq()
  return new_raw(sq(self.x))
end

function fix16:exp()
  return new_raw(exp(self.x))
end

function fix16:log()
  return new_raw(log(self.x))
end

function fix16:log2()
  return new_raw(slog2(self.x))
end

function fix16:is_overflow()
  return self.x == fix16_overflow
end

-- the module
local fixf = {new = new, new_raw = new_raw, isfix16 = isfix16, zero = zero, one=one,
  maximum = maximum, minimum = minimum,
  pi = pi, pi_div_2 = pi_div_2, pi_div_4 = pi_div_4,
  -- below are compatible functions with math.*
  min = fix16.min, max = fix16.max,
  abs = fix16.abs, floor = fix16.floor, ceil = fix16.ceil,
  sin = fix16.sin, cos = fix16.cos, tan = fix16.tan,
  asin = fix16.asin, acos = fix16.cos, atan = fix16.atan, atan2 = fix16.atan2,
  sqrt = fix16.sqrt, sq = fix16.sq,
  exp = fix16.exp, log = fix16.log, log2 = fix16.log2}

setmetatable(fixf,{__call = function(_, ...) return new(...) end})
declare("fixf", fixf)
declare("ffd", fm.fix16_from_dbl)
declare("ftd", fm.fix16_to_dbl)