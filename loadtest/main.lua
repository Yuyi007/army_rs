package.path = package.path..";./?.lua;"
require "inspect"
print(package.path )
print(inspect(package.preload))
skynet 	= require "skynet"

require "winnie/winnie"
local json = require "cjson"




local function initDebugConsole()
  local dbgConsole = skynet.getenv("debug_console")
  if dbgConsole then
    skynet.newservice("debug_console",8005)
  end
end


function writeTestData()
	local	opts={
		host=skynet.getenv("server_ip"),
		port=tonumber(skynet.getenv("server_port")),
		groupcount=tonumber(skynet.getenv("groupcount"))
	}

	for i=1,10*opts.groupcount do
		local uid = 10000140+i
		local ctick = os.time()
		local t1,t2 = math.modf((uid - 10000141) / 10)
		local beginID = math.ceil(10000141 + t1 * 10)

		local token = "RID:15:".. tostring(beginID) .. ":" .. tostring(ctick)
		local srv_room_info =  {
				ip = opts.host,
				port = opts.port,
				token = token,
				seed = os.time(),
				room_info = {
               							creator = beginID,
               							id = token,
               							members = { 	
               										{ 
               											{
               												houseCreator = true,
               												name = "dwjsx1",
               												ready = true,
               												uid = beginID
               											}, 
               											-1, 
               											-1, 
               											-1, 
               											-1 
               										},
               										{ 
               									 		-1, 
               									 		-1, 
               									 		-1, 
               									 		-1, 
               									 		-1 
               										} 
               									},
               							time_stamp = curTick,
               							type = 1
               						}           
			}
		

		local combatInfo = {
			srv_room_info = srv_room_info,
			entered = false
		}

		print("write test data:" .. inspect(combatInfo))
		
		combatInfo = json.encode(combatInfo)

		local s = [[
  	local room_key = unpack(KEYS)
  	local uid,combatinfo = unpack(ARGV)
  	redis.call('hset', room_key, uid, combatinfo)
  ]]
  RedisHelper.eval(s, {"{combat}{player_cur_rooms}"},
  										{uid, combatInfo})
	end
end

skynet.init(function()

	end)

skynet.start(function()
		--initDebugConsole()

		RedisServicePool.init()
		--writeTestData()
--[[		local a = {}
		table.insert(a, {4324,4324,432564})
		table.insert(a, {4324,4324,432564})
		table.insert(a, {4324,4324,432564})
		print("&",#a)
		table.insert(a, {4324,4324,432564})
		table.insert(a, {4324,4324,432564})
		print("&",#a)
		if #a >=6 then
			skynet.exit()
		end

		local b = {}
		b["1"]="fdasfds"
		b["2"]="rewqrewrew"
		b["30"]="vcxzvkjhkjhrewqre"
		b["4"]="vcxzvkjhk00jhrewqre"
		print("b", inspect(b))
		b["2"]=nil
		print("b3", b["3"],inspect(b))
		skynet.exit()--]]

		local testconfig = {}

		testconfig.host = skynet.getenv("combat_host")
		testconfig.port = tonumber(skynet.getenv("combat_port"))
		testconfig.combat_pid = tonumber(skynet.getenv("combat_pid"))
		testconfig.test_type = tonumber(skynet.getenv("test_type"))
		testconfig.conncount = tonumber(skynet.getenv("conncount"))
		testconfig.groupcount = tonumber(skynet.getenv("groupcount"))
		testconfig.beginuid = tonumber(skynet.getenv("beginuid"))
		
		local mt = skynet.newservice("testservice")
	  skynet.call(mt, "lua", "start", testconfig)


	  skynet.exit()
  end)