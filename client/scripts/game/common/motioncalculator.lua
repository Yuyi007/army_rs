local matrix = require "game/common/matrix"
local calc = {}
--[[
    desc:   calculate 3d position that along an acceleration trajectory
    params:
            p   initial position eg:{{0,0,0}}
            t   time past
            vv  initial velocity eg: {{50, 50, 0}}
            vg  accelerated velocity, like gravity eg: {{0, -9.8}, 0}
]]
function calc.calcMotion(p, t, vv, vg)
    local s1 = matrix.mulnum(vv, t)
    local s2 = matrix.mulnum(vg, 0.5*t*t)
    local p = matrix.add(p, s1)
    p = matrix.add(p, s2)
    matrix.print(p)
    return p
end

--[[
    desc: calcuate distance between p and p1
]]
function calc.calcDistance(p, p1)
    local v = matrix.sub(p1, p)
    local d = math.sqrt(v[1][1]*v[1][1] + v[1][2]*v[1][2] + v[1][3]*v[1][3])
    return d
end

--[[
    desc:   check if a 3d point nearby another
    params: p   3d point
            p1  3d point to be checked
            d   radius
]]
function calc.checkNear(p, p1, d)
    local r = calc.calcDistance(p, p1)
    return r <= d
end

return calc