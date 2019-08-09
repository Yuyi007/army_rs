
local mt = mtwist.new()
local seeds = {0, 1, 10, 73, -1, -1}

logd('[mtwist] start test: instanceNum=%d', mtwist.instanceNum())

local function testMax(mt, max)
  local values = {mt:rand(max), mt:rand(max), mt:rand(max), mt:rand(max), mt:rand(max)}
  for i = 1, #values do local v = values[i]
    if v > max then error(string.format('testMax failed! val=%f', v)) end
  end
  logd('[mtwist] seed=%.0f: max=%d int=%d, %d, %d, %d, %d', mt.seed, max, unpack(values))
end

local function testMinMax(mt, min, max)
  local values = {mt:rand(min, max), mt:rand(min, max), mt:rand(min, max), mt:rand(min, max), mt:rand(min, max)}
  for i = 1, #values do local v = values[i]
    if v < min or v > max then error(string.format('testMinMax failed! val=%f', v)) end
  end
  logd('[mtwist] seed=%.0f: min=%d max=%d int=%d, %d, %d, %d, %d', mt.seed, min, max, unpack(values))
end

for i = 1, #seeds do local seed = seeds[i]
  if seed < 0 then seed = mt:seedFromSystem() end

  mt:init(seed)
  if mt.seed ~= seed then error('test init failed!') end

  logd('[mtwist] i=%d seed=%.0f: int=%.0f, %.0f, %.0f, %.0f, %.0f', i, seed,
    mt:u32rand(), mt:u32rand(), mt:u32rand(), mt:u32rand(), mt:u32rand())
  logd('[mtwist] i=%d seed=%.0f: double=%f, %f, %f, %f, %f', i, seed,
    mt:drand(), mt:drand(), mt:drand(), mt:drand(), mt:drand())

  if pcall(function () mt:rand(0) end) == true then
    error('test rand(0) failed!')
  end

  if pcall(function () mt:rand(2, 1) end) == true then
    error('test rand(2, 1) failed!')
  end

  testMax(mt, 1)
  testMax(mt, 2)
  testMax(mt, 100)

  testMinMax(mt, 0, 0)
  testMinMax(mt, 0, 1)
  testMinMax(mt, 1, 1)
  testMinMax(mt, 1, 2)
  testMinMax(mt, 1, 100)

  if mt.genCount ~= 5 * 10 then
    error(string.format('test genCount failed! val=%d', mt.genCount))
  end

  if mt.lastValue <= 0 then
    error(string.format('test lastValue failed! val=%s', tostring(mt.lastValue)))
  end
end

mt = mtwist.new()
mt = mtwist.new()

logd('[mtwist] end test: instanceNum=%d', mtwist.instanceNum())

collectgarbage("collect")

logd('[mtwist] after full gc: instanceNum=%d', mtwist.instanceNum())
logd('[mtwist] test done')
