local fm = lfractor

class('LuaFractor', function(self, arg1, arg2)
	
	--args is fractor internal parts
	if type(arg1) == 'number' and type(arg2) == "number" then
		self._nom = arg1 
		self._den = arg2 
	--arg1 is double
	elseif type(arg1) == 'number' and not arg2 then
		self._nom, self._den = fm.lf_from_float(arg1)
	--arg1 is another LuaFractor
	elseif type(arg1) == 'table' and arg1.classname and arg1.classname == "LuaFractor" then
		self._nom = arg1._nom
		self._den = arg1._den
	--no args
	else
		self._nom = 0 
		self._den = 1
	end
end)

local m = LuaFractor

m.pool = FixedFramePool.new(function() return LuaFractor.new() end,
	{ initSize = 0, maxSize = 8192, tag='Fractor', objectMt = LuaFractor})

m.exit = function()
end

m.makeFromPool = function(nom, den)
	local obj = m.pool:borrow()
	obj._nom = nom
	obj._den = den
	return obj
end

m.makeFromTable = function(t)
	if not t._nom or not t._den then
		loge("Invalid table intends to convert to Fractor!!!")
	end
	return m.makeFromPool(t._nom, t._den)
end

m.to_table = function(fr)
	fr._data_tb_ = fr._data_tb_ or {}
	table.clear(fr._data_tb_)

	fr._data_tb_["_nom"] = fr._nom
	fr._data_tb_["_den"] = fr._den
	return fr._data_tb_
end

m._ = function(fra, frb)
	-- logd("fra:%s frb:%s", fra, frb)
	fra._nom = frb._nom
	fra._den = frb._den
end

m.__tostring = function(fr)
	return fm.lf_tostring(fr._nom, fr._den)
end

m.__add = function(fr1, fr2)
	return m.makeFromPool(fm.lf_add(fr1._nom, fr1._den, fr2._nom, fr2._den))
end

 m.__sub = function(fr1, fr2)
 return m.makeFromPool(fm.lf_sub(fr1._nom, fr1._den, fr2._nom, fr2._den))
end

m.__mul = function(fr1, fr2)
 return m.makeFromPool(fm.lf_mul(fr1._nom, fr1._den, fr2._nom, fr2._den))
end

m.__div = function(fr1, fr2)
 return m.makeFromPool(fm.lf_div(fr1._nom, fr1._den, fr2._nom, fr2._den))
end

m.__eq = function(fr1, fr2)
	return fm.lf_eq(fr1._nom, fr1._den, fr2._nom, fr2._den)
end

m.__lt = function(fr1, fr2)
	return fm.lf_lt(fr1._nom, fr1._den, fr2._nom, fr2._den)
end

m.__le = function(fr1, fr2)
	return fm.lf_le(fr1._nom, fr1._den, fr2._nom, fr2._den)
end

m.__unm = function(fr)
	return m.makeFromPool(fm.lf_unm(fr._nom, fr._den))
end

m.from_float = function(f)
	return m.makeFromPool(fm.lf_from_float(f))
end

m.from_int = function(n)
	return m.makeFromPool(fm.lf_from_int(n))
end

m.to_int = function(fr)
	--return fm.lf_to_int(fr._nom, fr._den)
	return math.floor(fr._nom/fr._den)
end

m.to_float = function(fr)
	return fr._nom / fr._den
	--return fm.lf_to_float(fr._nom, fr._den)
end

m.abs = function(fr)
	return m.makeFromPool(fm.lf_abs(fr._nom, fr._den))
end

m.sqrt = function(fr)
	return m.makeFromPool(fm.lf_sqrt(fr._nom, fr._den))
end

m.sin = function(fr)
	return m.makeFromPool(fm.lf_sin(fr._nom, fr._den))
end

m.cos = function(fr)
	return m.makeFromPool(fm.lf_cos(fr._nom, fr._den))
end

m.tan = function(fr)
	return m.makeFromPool(fm.lf_tan(fr._nom, fr._den))
end

m.exp = function(fr)
	return m.makeFromPool(fm.lf_exp(fr._nom, fr._den))
end

m.ln = function(fr)
	return m.makeFromPool(fm.lf_ln(fr._nom, fr._den))
end

m.log = function(fr)
	return m.makeFromPool(fm.lf_log(fr._nom, fr._den))
end

m.asin = function(fr)
	return m.makeFromPool(fm.lf_asin(fr._nom, fr._den))
end

m.acos = function(fr)
	return m.makeFromPool(fm.lf_acos(fr._nom, fr._den))
end

m.deg_to_rad = function(fr)
	return m.makeFromPool(fm.lf_deg_to_rad(fr._nom, fr._den))
end

m.rad_to_deg = function(fr)
	return m.makeFromPool(fm.lf_rad_to_deg(fr._nom, fr._den))
end

m.atan2 = function(fr)
	return m.makeFromPool(fm.lf_atan2(fr._nom, fr._den))
end


declare('fixf', {})
setmetatable(fixf,{__call = function(_, f, f1)
	if not f1 then
		return LuaFractor.from_float(f)
	else
		return LuaFractor.makeFromPool(f, f1)
	end
end})

fixf.new = function(n,d) return LuaFractor.new(n, d) end
fixf.one = fixf.new(1, 1);
fixf.zero = fixf.new(0, 1);
fixf.half = fixf.new(1, 2);
fixf.two = fixf.new(2, 1);
fixf.ten = fixf.new(10, 1);

fixf.f3 = fixf.new(3, 1);
fixf.f4 = fixf.new(4, 1);
fixf.f6 = fixf.new(6, 1);

fixf.pi = fixf.new(31416, 10000);
fixf.half_pi = fixf.new(15708, 10000);
fixf.quat_pi = fixf.new(7854, 10000);
fixf.two_pi = fixf.new(62832, 10000);

fixf.f180 = fixf.new(180, 1);
fixf.f360 = fixf.new(360, 1);

fixf.f30 = fixf.new(30, 1);
fixf.f60 = fixf.new(60, 1);
fixf.f90 = fixf.new(90, 1);
fixf.f120 = fixf.new(120, 1);

fixf.rdu = fixf.new(1309, 75000);
fixf.dru = fixf.new(75000, 1309);
	
fixf.e = fixf.new(fm.lf_from_float(2.71828));

fixf.axisX = {x = fixf.one, y = fixf.zero, z = fixf.one}
fixf.axisY = {x = fixf.zero, y = fixf.one, z = fixf.zero}
fixf.axisZ = {x = fixf.zero, y = fixf.zero, z = fixf.one}

declare("ffd", LuaFractor.from_float)
declare("ftd", LuaFractor.to_float)

declare("convf", function(nom, den) return LuaFractor.makeFromPool(nom, den) end)

