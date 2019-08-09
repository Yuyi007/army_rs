local RedisCluster = require "skynet.db.redis.cluster"
local unpack = rawget(table, "unpack") or unpack

class("RedisConnection", function(self) 
	self.con = nil
end)

local m = RedisConnection

function m:exec(cmd, ...)
	if not cmd then 
		skynet.error("Redis connection cannot exec null cmd")
		return nil 
	end
	self:check_get_con()

	local f = self[cmd]
	if not f then 
		f = self.con[cmd]
		if not f then
			skynet.error("Redis connection cannot exec cmd:", cmd)
			return nil 
		else
			local retv = f(self.con, ...)
			if self.con:cmd_error() then
				self.con = nil
			end
			return retv
		end
	else
		return f(self, ...)
	end
end

function m:eval(str, keys, args)
	-- print(">>>>str:", str, " keys;", inspect(keys), " args:", inspect(args))
	self:check_get_con()
	
	local count = #keys
	for _, v in pairs(args) do 
		table.insert(keys, v)
	end

	local retv = self.con:eval(str, count, unpack(keys))
	if self.con:cmd_error() then
		self.con = nil
	end
	return retv
end

function m:start()
	self:check_get_con()
end

function m:stop()
	if self.con then
		self.con:close_all_connection()
	end
	skynet.exit()
end

function m:check_get_con()
	if self.con then 
		return self.con 
	end
	
	local host = skynet.getenv("redis_host")
	local port = skynet.getenv("redis_port")
	local db = skynet.getenv("redis_db")

	local conf = {
		host = host,
		port = tonumber(port),
		db = tonumber(db)
	}
	print("Redis connect pool:", inspect(conf))
	self.con = RedisCluster.new(conf)
	if not self.con then
		skynet.error("redis can not connect!!!")
	else
		skynet.error("redis connect ok!!!")
	end
	return self.con
end
