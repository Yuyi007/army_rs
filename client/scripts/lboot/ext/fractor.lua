local fm = lfractor

local function isFractor(x)
	return type(x) == 'lightuserdata' and v["__FRAC__"] == 1
end

local function new(x)
	return fm.from_float(x)
end

local fixf = {
	new = new,
	isFractor = isFractor, 
	zero = fm.ZERO,
	one = fm.ONE,
	ten = fm.TEN,
	half = fm.HALF,
	maximum = fm.MAX,
	minimum = fm.MIN,
	pi = fm.PI,
	pi_div_2 = fm.HALF_PI,
	pi_div_4 = fm.QUAT_PI,
	pi_mul_2 = fm.TWO_PI,
	e = fm.E,
	abs = fm.abs, 
  sin = fm.sin, 
  cos = fm.cos, 
  tan = fm.tan,
  asin = fm.asin, 
  acos = fm.cos, 
  atan = fm.atan, 
  atan2 = fm.atan2,
  sqrt = fm.sqrt, 
  exp = fm.exp, 
  log = fm.log, 
  ln = fm.ln,
  to_float = fm.to_float,
  deg_to_rad = fm.deg_to_rad,
  rad_to_deg = fm.rad_to_deg
}

setmetatable(fixf,{__call = function(_, ...) return new(...) end})
declare("fixf", fixf)
declare("ffd", fm.from_float)
declare("ftd", fm.to_float)