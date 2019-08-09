
logd('[lkcp] start test: ')

local tmpBuf = nil
local output = function (buf)
  tmpBuf = buf
end

local conv = math.random(1000000)
local kcp = lkcp.create(conv, output)

assert(kcp ~= nil)
kcp:update(0)
kcp:update(100)
kcp:update(200)

local data = 'abcdef'
assert(kcp:send(data) == 0)
kcp:update(300)
assert(kcp:check(300) >= 300)
kcp:flush()
assert(string.len(tmpBuf) > string.len(data))

assert(kcp:input(tmpBuf) == 0)
local r, recvData = kcp:recv()
assert(r > 0 and recvData == data)

kcp:update(100)
kcp:update(0)
kcp:update(500)
kcp:flush()
assert(kcp:peeksize() == -1)

kcp:setmtu(512)
logd('[lkcp] waitsnd=%d', kcp:waitsnd())
-- assert(kcp:waitsnd() == 0)
kcp:wndsize(100, 200)
assert(kcp:nodelay(0, 40, 0, 0) == 0)
assert(kcp:nodelay(1, 10, 2, 1) == 0)

logd('[lkcp] end test: ')
