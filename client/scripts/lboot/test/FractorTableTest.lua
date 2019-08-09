local fm = LuaFractor

logd("Fractor table test begin")

logd(">>>>>>>Library globals>>>>>>>>")
logd("ONE :%s", tostring(fm.one))
logd("ZERO :%s", tostring(fm.zero))
logd("TWO :%s", tostring(fm.two))
logd("HALF :%s", tostring(fm.half))
logd("TEN :%s", tostring(fm.ten))
logd("PI :%s", tostring(fm.pi))
logd("HALF_PI :%s", tostring(fm.half_pi))
logd("TWO_PI :%s", tostring(fm.two_pi))
logd("QUAT_PI :%s", tostring(fm.quat_pi))
logd("E :%s", tostring(fm.e))
logd("F180 :%s", tostring(fm.f180))
logd("RDU :%s", tostring(fm.rdu))
logd("DRU :%s", tostring(fm.dru))
logd(">>>>>>>>>>>>>>>")


local a = fm.from_float(3.1415926)
logd(" a:nom:%s, den:%s", tostring(a._nom), tostring(a._den))
logd(" a:to_table():%s", inspect(a:to_table()))
logd(" fm.to_float(a):%f", fm.to_float(a))
logd(" a:to_float():%f", a:to_float())
logd(" a:to_int():%f", a:to_int())
logd(" tostring(a):%f", tostring(a))

local b = fm.from_int(12)
logd(" fm.to_float(b):%f", fm.to_float(b))
logd(" b:to_float():%f", b:to_float())
logd(" b:to_int():%f", b:to_int())
logd(" tostring(b):%f", tostring(b))
logd(" b < a:%s", tostring(b<a))

local c = a + b
logd(" a + b:%f", c:to_float())
c = b - a
logd(" b - a:%f", c:to_float())
c = a - b
logd(" a - b:%f", c:to_float())
c = a * b
logd(" a * b:%f", c:to_float())
c = a / b
logd(" a / b:%f", c:to_float())
c = b / a
logd(" a / b:%f", c:to_float())

a = fixf.half_pi
log("sin pi/2:%f", a:sin())
a = fixf.quat_pi
log("sin pi/4:%f", a:sin())
log("cos pi/4:%f", a:cos())
log("tan pi/4:%f", a:tan())
a = fm.from_int(-13.123)
log("a:abs():%s", a:abs())
a = fm.from_int(4)
log("a:sqrt():%s", a:sqrt())
a = fm.from_float(0.5)
log("a:acos():%s", a:acos())
a = fm.from_float(1)
log("a:asin():%s", a:asin())

local x, y = fm.from_int(1), fm.from_int(1)
log("fm.atan2(1,1):%s", fm.atan2(x, y))

a = fm.from_float(3.14159)
log("a:rad_to_deg():%s", a:rad_to_deg())
a = fm.from_float(90)
log("a:deg_to_rad():%s", a:deg_to_rad())

a = fm.makeFromPool(2, 1)
b = fm.makeFromPool(3, 1)
a:_(a + b)
log("a = a+b:%s", a)

a = fixf.new(0.5)
log("a:%s", a)
a:_(fixf.zero)
log("a = 0:%s", a)

logd("Fractor table test complete!!!")

