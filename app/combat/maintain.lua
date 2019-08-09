package.path = package.path..";../../?.lua;"
skynet 	= require "skynet"
require "inspect"
require "skynet.manager"
SCHEDULER_PRECISION = 50
require "winnie/winnie"
local json = require "cjson"
statsDB = require "statsd"

local CMD = {}

local SRVS_COUNT_KEY = RedisHelper.gen_key("combat_servers", "count")
local SRVS_STATUS_EKY = RedisHelper.gen_key("combat_servers", "status")
local SRVS_TICK_EKY = RedisHelper.gen_key("combat_servers", "tick")

local SRVS_SENDBYTE_KEY = RedisHelper.gen_key("combat_servers", "sendbytes")
local SRVS_RECVBYTE_KEY = RedisHelper.gen_key("combat_servers", "recvbytes")
local SRVS_CONNCOUNT_KEY = RedisHelper.gen_key("combat_servers", "conncount")
local SRVS_BEGINTICK_KEY = RedisHelper.gen_key("combat_servers", "begintick")
local SRVS_ROOMCOUNT_KEY = RedisHelper.gen_key("combat_servers", "roomcount")

--set tick per seconds
local SRVS_ALIVE_INTERVAL = 100
local SRV_TIMEOUT = 5

--Dosable status is stted by data server when combat server's last tick over 2 seconds
local SRV_STATUS_DISABLE = 0 
local SRV_STATUS_ENABLED = 1 

local server_started = false
local hkeep_alive = nil
local srv_key = nil

local memrecord = 0

local bytestat_tick = 0
local server_begintick = 0
local server_sendBytes = 0
local server_recvBytes = 0
local client_conncount = 0
local room_count = 0

function Server()
	if srv_key then return srv_key end

	local ip = skynet.getenv("server_ip")
  local port = skynet.getenv("server_port")
  if not ip or not port then 
  	print("plz configurate combat server_ip and combat server_port")
  	return 
  end
  srv_key = ip.."_"..port
  return srv_key
end

function CMD.start()
	if server_started then 
		print("server already started!!!")
		return true
	end
	RedisServicePool.init()
	CMD.clearTimeoutServers()
	CMD.registerServer()
	server_started = true

	RedisHelper.hset(SRVS_BEGINTICK_KEY, Server(), server_begintick)
	
	return true
end

function StartKeepAlive()
	StopKeepAlive()
	local function keepAlive()
		local now = math.floor(skynet.time())
		-- print("set alive tick:", now)
		local srv = Server()
		RedisHelper.hset(SRVS_TICK_EKY, srv, now)

		bytestat_tick = bytestat_tick + 1
		if bytestat_tick >= 10 then
			bytestat_tick = 0

			RedisHelper.hset(SRVS_SENDBYTE_KEY, srv, server_sendBytes)
			RedisHelper.hset(SRVS_RECVBYTE_KEY, srv, server_recvBytes)
			
			RedisHelper.hset(SRVS_CONNCOUNT_KEY, srv, client_conncount)
			RedisHelper.hset(SRVS_ROOMCOUNT_KEY, srv, room_count)
		end

		--current memory size
		--[[memrecord = memrecord + 1
		if memrecord > 1000 then
			memrecord = 0
			
			local mem = math.floor(collectgarbage("count"))
			statsDB:gauge("memory", mem, 1)
		end--]]
	end

	hkeep_alive = Scheduler.schedule(SRVS_ALIVE_INTERVAL, keepAlive)
end

function StopKeepAlive()
	if not hkeep_alive then return end

	Scheduler.unschedule(hkeep_alive)
	hkeep_alive = nil
end 

function CMD.registerServer()
  local s = [[
  	local status_key, count_key, tick_key = unpack(KEYS)
  	local srv, status = unpack(ARGV)
  	redis.call('hset', status_key, srv, status)
  	redis.call('hset', count_key, srv, 0)
  	redis.call('hset', tick_key, srv, 0)
  ]]
  local srv = Server()
  RedisHelper.eval(s, {SRVS_STATUS_EKY, SRVS_COUNT_KEY, SRVS_TICK_EKY},
  										{srv, SRV_STATUS_ENABLED})

  print("[maintain] registerServer")
  StartKeepAlive()
  return true
end

function CMD.unregisterServer()
	if not server_started then
		print("server not started") 
		return 
	end

	local srv = Server()
	local s = [[
		local status_key, count_key, tick_key = unpack(KEYS)
		local srv = ARGV[1]
  	redis.call('hdel', status_key, srv)
  	redis.call('hdel', count_key, srv)
  	redis.call('hdel', tick_key, srv)
	]]
	local srv = Server()
	RedisHelper.eval(s, {SRVS_STATUS_EKY, SRVS_COUNT_KEY, SRVS_TICK_EKY}, 
											{srv})
	print("[maintain] unregisterServer")
	StopKeepAlive()
	return true
end

function CMD.releasePayload(roomtoken)
	local srv = Server()
	local s = [[
		local count_key = KEYS[1]
		local srv = ARGV[1]
		local count = redis.call('hget', count_key, srv)
		count = count - 1
		if count < 0 then
			count = 0 
		end
  	redis.call('hset', count_key, srv, count)
	]]
	local srv = Server()
	RedisHelper.eval(s, {SRVS_COUNT_KEY}, {srv})
	print("[maintain] release pay load")

	--RedisHelper.hdel("{matchpool}:room", roomtoken)
end

function CMD.clearTimeoutServers()
	local s = [[
		local status_key, count_key, tick_key = unpack(KEYS)
		local now, timeout = unpack(ARGV)
		
		now = tonumber(now)
    timeout = tonumber(timeout)

		local tmp = redis.call('hgetall', tick_key)
		for i=1,#tmp,2 do 
  		local srv = tmp[i]
  		local tick = tonumber( tmp[i+1] )
  		if (now - tick) >= timeout then
  			redis.call('hdel', status_key, srv)
  			redis.call('hdel', count_key, srv)
  			redis.call('hdel', tick_key, srv)
  		end
  	end
	]]
	local now = math.floor(skynet.time())
	RedisHelper.eval(s, {SRVS_STATUS_EKY, SRVS_COUNT_KEY, SRVS_TICK_EKY}, 
											{now, SRV_TIMEOUT})
	print("[maintain] clear timeout servers")
end

function CMD.quit()
	RedisServicePool.exit()
	skynet.exit()
end

function CMD.incSendData(size)
	server_sendBytes = server_sendBytes + size
end

function CMD.incRecvData(size)
	server_recvBytes = server_recvBytes + size
end

function CMD.incNetBytes(sendSize, recvSize)
	server_sendBytes = server_sendBytes + sendSize
	server_recvBytes = server_recvBytes + recvSize
end

function CMD.incConnection()
	client_conncount = client_conncount + 1
end

function CMD.decConnection()
	client_conncount = client_conncount - 1
end

function CMD.setRoomCount(cnt)
	room_count = cnt
end

skynet.start(function()
	print("Service start keep alive")
	server_begintick = math.floor(skynet.time())

	skynet.dispatch("lua", function(_,_, command, ...)
        local f = CMD[command]
        local res = f(...)
        if res then
          skynet.ret(skynet.pack(res))
        end
      end)

	skynet.register(".maintain")
end)
