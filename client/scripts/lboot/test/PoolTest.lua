-- PoolTest.lua

local create = function () return {} end
local createAsync = function (onComplete) onComplete({}) end
local opts = {initSize = 2, maxSize = 3, objectMt = {}}

-- test pool

logd('testing Pool...')

local pool = Pool.new(create, opts)
assert(pool:size() == 2)
assert(pool.lentSize == 0)

local v1, v2, v3, v4, v5, v6

v1 = pool:borrow()
v1.x = 1
assert(pool:size() == 1)
assert(pool.lentSize == 1)

pool:recycle(v1)
assert(pool:size() == 2)
assert(pool.lentSize == 0)

v1 = pool:borrow()
assert(v1.x == 1)
assert(pool:size() == 1)
assert(pool.lentSize == 1)

local v2 = pool:borrow()
v2.x = 2
assert(pool:size() == 0)
assert(pool.lentSize == 2)

pool:recycle(v1)
pool:recycle(v2)
assert(pool:size() == 2)
assert(pool.lentSize == 0)

v2 = pool:borrow()
assert(v2.x == 2)
assert(pool.lentSize == 1)

v1 = pool:borrow()
assert(v1.x == 1)
assert(pool.lentSize == 2)

v3 = pool:borrow()
v3.x = 3
assert(pool:size() == 0)
assert(pool.lentSize == 3)

v4 = pool:borrow()
v4.x = 4
assert(pool:size() == 0)
assert(pool.lentSize == 4)

v5 = pool:borrow()
v5.x = 5
assert(pool:size() == 0)
assert(pool.lentSize == 5)

pool:recycle(v5)
assert(pool:size() == 1)
assert(pool.lentSize == 4)

pool:recycle(v4)
assert(pool:size() == 2)
assert(pool.lentSize == 3)

pool:recycle(v3)
assert(pool:size() == 3)
assert(pool.lentSize == 2)

pool:recycle(v2)
assert(pool:size() == 3)
assert(pool.lentSize == 1)

pool:recycle(v1)
assert(pool:size() == 3)
assert(pool.lentSize == 0)

Pool.destroy(pool.tag)

logd('testing Pool success!')

-- test async pool

logd('testing AsyncPool...')

pool = AsyncPool.new(createAsync, opts)
assert(pool:size() == 2)
assert(pool.lentSize == 0)

pool:borrow(function (v) v.x = 1; v1 = v end)
assert(pool:size() == 1)
assert(pool.lentSize == 1)

pool:borrow(function (v) v.x = 2; v2 = v end)
assert(pool:size() == 0)
assert(pool.lentSize == 2)

pool:recycle(v1)
pool:recycle(v2)
assert(pool:size() == 2)
assert(pool.lentSize == 0)

Pool.destroy(pool.tag)

logd('testing AsyncPool success!')

-- test frame pool

logd('testing FramePool...')

pool = FramePool.new(create, opts)
assert(pool:size() == 2)
assert(pool.lentSize == 0)

v1 = pool:borrow()
v1.x = 1
assert(pool:size() == 1)
assert(pool.lentSize == 1)

v2 = pool:borrow()
v2.x = 2
assert(pool:size() == 0)
assert(pool.lentSize == 2)

pool:recycleAll()
assert(pool:size() == 2)
assert(pool.lentSize == 0)

local ok, err = pcall(function () return v1.y end)
assert(ok == false)

v2 = pool:borrow()
assert(v2.x == 2)
assert(pool:size() == 1)
assert(pool.lentSize == 1)

v1 = pool:borrow()
assert(v1.x == 1)
assert(pool:size() == 0)
assert(pool.lentSize == 2)

v3 = pool:borrow()
v3.x = 3
assert(pool:size() == 0)
assert(pool.lentSize == 3)

v4 = pool:borrow()
v4.x = 4
assert(pool:size() == 0)
assert(pool.lentSize == 4)

pool:recycleAll()
assert(pool:size() == 3)
assert(pool.lentSize == 0)

ok, err = pcall(function () return v2.y end)
assert(ok == false)

Pool.destroy(pool.tag)

logd('testing FramePool success!')

-- test RefCountPool

logd('testing RefCountPool...')

pool = RefCountPool.new(create, opts)
assert(pool:size() == 2)
assert(pool.lentSize == 0)

v1 = pool:borrow()
v1.x = 1
assert(pool:size() == 1)
assert(pool.lentSize == 1)

pool:release(v1)
assert(pool:size() == 2)
assert(pool.lentSize == 0)

v1 = pool:borrow()
v1.x = 1
v2 = pool:borrow()
v2.x = 2
assert(pool:size() == 0)
assert(pool.lentSize == 2)

pool:retain(v1)
pool:retain(v1)

pool:retain(v2)
pool:release(v2)
pool:release(v2)
assert(pool:size() == 1)
assert(pool.lentSize == 1)

pool:release(v1)
pool:release(v1)
pool:release(v1)
assert(pool:size() == 2)
assert(pool.lentSize == 0)

Pool.destroy(pool.tag)

logd('testing RefCountPool success!')
