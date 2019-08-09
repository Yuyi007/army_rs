local sharedata = require "skynet.sharedata"
class("RedisServicePool", function(self) end)

local m = RedisServicePool
m.services = nil

function m.init()
	m.services = {}
	local num = skynet.getenv("connect_pool")
	num = tonumber(num)
	for i = 1, num do 
		local h = skynet.newservice("redis_service")
		table.insert(m.services, h)
		skynet.send(h, "lua", "exec", "start")
	end
	sharedata.new("REDIS_CONNECT_POOL", m.services)
end

function m.start()
	m.services = sharedata.query("REDIS_CONNECT_POOL")
end

function m.exit()
	for _, h in pairs(m.services) do 
		skynet.send(h, "lua", "exec", "stop")
	end
	m.services = nil
end

function m.getConnection()
	local len = #(m.services)
	local i = math.random(len)
	return m.services[i]
end