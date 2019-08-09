local fm = lfractor

logd("Fractor test begin")

logd(">>>>>>>Library globals>>>>>>>>")
logd("NAME :%s", tostring(fm.NAME))
logd("VERSION :%s", tostring(fm.VERSION))
logd("MAX :%s", tostring(fm.MAX))
logd("MIN :%s", tostring(fm.MIN))
logd("ONE :%s", tostring(fm.ONE))
logd("ZERO :%s", tostring(fm.ZERO))
logd("TWO :%s", tostring(fm.TWO))
logd("HALF :%s", tostring(fm.HALF))
logd("TEN :%s", tostring(fm.TEN))
logd("PI :%s", tostring(fm.PI))
logd("HALF_PI :%s", tostring(fm.HALF_PI))
logd("TWO_PI :%s", tostring(fm.TWO_PI))
logd("QUAT_PI :%s", tostring(fm.QUAT_PI))
logd("E :%s", tostring(fm.E))
logd(">>>>>>>>>>>>>>>")

local a = fm.from_float(3.1415926)
logd(" a['__FRAC__']:%f", tostring(a["__FRAC__"]))
logd(" fm.to_float(a):%f", fm.to_float(a))
logd(" a:to_float():%f", a:to_float())
logd(" a:to_int():%f", a:to_int())
logd(" tostring(a):%f", tostring(a))

local b = fm.from_int(12)
logd(" fm.to_float(b):%f", fm.to_float(b))
logd(" b:to_float():%f", b:to_float())
logd(" b:to_int():%f", b:to_int())
logd(" tostring(b):%f", tostring(b))
logd{" b < a:%s", tostring(b<a)}

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

a = fm.HALF_PI
log("sin pi/2:%f", a:sin())
a = fm.QUAT_PI
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

logd("Fractor test complete!!!")
