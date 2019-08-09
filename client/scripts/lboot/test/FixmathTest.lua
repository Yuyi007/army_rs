
local fm = fixmath

local a = fm.fix16_from_dbl(3.1415926)
local b = fm.fix16_from_dbl(0.1415926)

local c = fm.fix16_sub(a, b)
logd("fix16_sub: %f", fm.fix16_to_dbl(c))

local d = fm.fix16_ssub(a, b)
logd("fix16_ssub: %f", fm.fix16_to_dbl(d))

local e = fm.fix16_smul(a, b)
logd("fix16_smul: %f", fm.fix16_to_dbl(e))

local f = fm.fix16_sdiv(a, b)
logd("fix16_sdiv: %f", fm.fix16_to_dbl(f))

local g = fm.PI_DIV_4

local h = fm.fix16_tan(g)
logd("fix16_tan: %f", fm.fix16_to_dbl(h))

local i = fm.fix16_atan(h)
logd("fix16_atan: %f", fm.fix16_to_dbl(i))

local j = fm.fix16_e

local k = fm.fix16_log(j)
logd("fix16_log: %f", fm.fix16_to_dbl(k))

local l = fm.fix16_from_int(360)

local m = fm.fix16_deg_to_rad(l)
logd("fix16_deg_to_rad: %f", fm.fix16_to_dbl(m))

local n = fm.fix16_rad_to_deg(m)
logd("fix16_rad_to_deg: %f", fm.fix16_to_dbl(n))

local o = fm.fix16_to_str(a, 7)
logd("fix16_to_str: %s", o)

local p = fm.fix16_from_str(o)
logd("fix16_from_str: %f", fm.fix16_to_dbl(p))

local q = fm.fix16_one

local r = fm.fix16_sqrt(q)
logd("fix16_sqrt: %f", fm.fix16_to_dbl(r))

local s = fm.fix16_sq(r)
logd("fix16_sq: %f", fm.fix16_to_dbl(s))

local t = fm.fix16_exp(s)
logd("fix16_exp: %f", fm.fix16_to_dbl(t))

logd("raw fix16 API test OK.")

local fix16 = require 'lboot/ext/fix16'

a = fix16(1)
b = fix16(2)
logd("a+b=%s", tostring(a + b))
logd("a-b=%s", tostring(a - b))
logd("a*b=%s", tostring(a * b))
logd("a/b=%s", tostring(a / b))

logd("b+a=%s", tostring(b + a))
logd("b-a=%s", tostring(b - a))
logd("b*a=%s", tostring(b * a))
logd("b/a=%s", tostring(b / a))

b = 2
logd("a+b=%s", tostring(a + b))
logd("a-b=%s", tostring(a - b))
logd("a*b=%s", tostring(a * b))
logd("a/b=%s", tostring(a / b))

logd("b+a=%s", tostring(b + a))
logd("b-a=%s", tostring(b - a))
logd("b*a=%s", tostring(b * a))
logd("b/a=%s", tostring(b / a))

b = fix16(2)
logd("a>b %s", tostring(a > b))
logd("a<b %s", tostring(a < b))
logd("a>=b %s", tostring(a >= b))
logd("a<=b %s", tostring(a <= b))
logd("a>b %s", tostring(a:gt(b)))
logd("a<b %s", tostring(a:lt(b)))
logd("a>=b %s", tostring(a:ge(b)))
logd("a<=b %s", tostring(a:le(b)))
logd("a==b %s", tostring(a:eq(b)))

logd("a<maximum %s", tostring(a < fix16.maximum))
logd("a<minimum %s", tostring(a < fix16.minimum))
logd("is_overflow %s %s", tostring(b * 10000), tostring(b * 100000))

logd("min: %s", tostring(fix16.min(a, b)))
logd("max: %s", tostring(fix16.max(a, b)))

c = fix16(3.14156)
logd("clone: %s", tostring(c:clone()))
logd("to_int: %s", tostring(c:to_int()))
logd("to_dbl: %s", tostring(c:to_dbl()))
logd("to_deg: %s", tostring(c:to_deg()))
logd("to_rad: %s", tostring(c:to_rad()))
logd("floor: %s", tostring(c:floor()))
logd("ceil: %s", tostring(c:ceil()))
logd("unary: %s", tostring(-c))
logd("abs: %s %s", tostring(c:abs()), tostring((-c):abs()))
logd("clamp: %s %s", tostring(c:clamp(1, 3)), tostring(c:clamp(5, 6)))
logd("mod: %s", tostring(c:mod(2)))

d = fix16.pi_div_4
logd("sin: %s", tostring(d:sin()))
logd("cos: %s", tostring(d:cos()))
logd("tan: %s", tostring(d:tan()))
logd("asin: %s", tostring(d:sin():asin()))
logd("acos: %s", tostring(d:cos():acos()))
logd("atan: %s", tostring(d:tan():atan()))
logd("atan2: %s", tostring(fix16.atan2(fix16(1), 2)))

d = fix16(45)
logd("degree sin: %s", tostring(d:deg_sin()))
logd("degree cos: %s", tostring(d:deg_cos()))
logd("degree tan: %s", tostring(d:deg_tan()))

e = fix16(5)
logd("sq: %s", tostring(e:sq()))
logd("sqrt: %s", tostring(e:sqrt()))
logd("exp: %s", tostring(e:exp()))
logd("log: %s", tostring(e:log()))
logd("log2: %s", tostring(e:log2()))

logd("fix16 module test OK.")