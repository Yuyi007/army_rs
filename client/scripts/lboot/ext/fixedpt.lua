local fp = lfixedpt

local function isfixedpt(x)
	return type(x) == 'lightuserdata' and type(v.sin) == 'function'
end

local function new(x)
	return fp.from_float(x)
end

local fixf = {
	new = new,
	isfixedpt = isfixedpt, 
	zero = new(0),
	one = new(1),
	maximum = fp._MAX,
	minimum = fp._MIN,
	pi = fp._PI,
	pi_div_2 = fp._HALF_PI,
	pi_div_4 = fp._HHALF_PI,
	pi_mul_2 = fp._TWO_PI,
	e = fp._E,
	abs = fp.abs, 
  sin = fp.sin, 
  cos = fp.cos, 
  tan = fp.tan,
  asin = fp.asin, 
  acos = fp.cos, 
  atan = fp.atan, 
  atan2 = fp.atan2,
  sqrt = fp.sqrt, 
  exp = fp.exp, 
  log = fp.log, 
  ln = fp.ln,
  to_float = fp.to_float,
  deg_to_rad = fp.deg_to_rad,
  rad_to_deg = fp.rad_to_deg
}
setmetatable(fixf,{__call = function(_, ...) return new(...) end})
declare("fixf", fixf)
declare("ffd", fp.from_float)
declare("ftd", fp.to_float)
