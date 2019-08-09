local unpack = rawget(table, "unpack") or unpack
class("RedisHelper", function(self) end)

local m = RedisHelper

function m.start()
	RedisServicePool.start()
end

function m.gen_key(tag, key)
	return string.format("{%s}:%s", tag, key)
end

function m.eval(str, keys, args)
	return m.exec("eval", str, keys, args)
end

function m.hset(k1, k2, v)
	return m.exec("hset", k1, k2, v)
end

function m.hget(k1, k2)
	return m.exec("hget", k1, k2)
end

function m.hdel(k1, k2)
	return m.exec("hdel", k1, k2)
end

function m.set(k, v)
	return m.exec("set", k, v)
end

function m.get(k)
	return m.exec("get", k)
end

function m.exec(cmd, ...)
	local h = RedisServicePool.getConnection()
	return skynet.call(h, "lua", "exec", cmd, ...)
end

