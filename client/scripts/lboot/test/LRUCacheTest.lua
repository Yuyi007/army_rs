-- LRUCacheTest.lua

logd('LRUCache testing...')

local c = LRUCache.new(100)
assert(c:get('a') == nil, 'get a = nil')
c:set('b', 0)
c:set('c', 1)
assert(c:get('b') == 0, 'get b = 0')
for i = 1, 1000, 1 do
  c:get('c')
  c:set(i, i)
end
assert(c:size() == 100, 'size = 100')
assert(c:get('b') == nil, 'should evict b')
assert(c:get('c') == 1, 'should not evict c')
logd('hitrate is ' .. c:hitrate() * 100 .. '%%')

local N = 200000
local st = os.time()
for i = 1, N, 1 do
  c:set(i, i)
  c:get(i)
end
local tt = math.max(os.time() - st, 1)
logd('performing ' .. N .. ' set and get in ' .. tt .. ' seconds ' .. N / tt .. ' ops/sec')
logd('hitrate is ' .. c:hitrate() * 100 .. '%%')

logd('LRUCache test finished')
