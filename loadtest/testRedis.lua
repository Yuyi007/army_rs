package.path = package.path..";../../?.lua;"
skynet 	= require "skynet"
require "inspect"
require "winnie/winnie"
local json = require "cjson"

function writeTestData()
	local	opts={
		host=skynet.getenv("server_ip"),
		port=tonumber(skynet.getenv("server_port"))
	}

	for i=1,100 do
		local uid = 10000140+i
		local ctick = os.time()
		local t1,t2 = math.modf((uid - 10000141) / 10)
		local beginID = math.ceil(10000141 + t1 * 10)

		local token = "RID:10:".. tostring(beginID) .. ":" .. tostring(ctick)
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
		--RedisHelper.hset("{combat}{player_cur_rooms}", uid, combatInfo)
		--redis.call('hset', COMBAT_ROOMS_KEY, uid, combatInfo)

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
		RedisServicePool.init()
		writeTestData()
		--local mt = skynet.newservice("testservice")
	  --skynet.call(mt, "lua", "start", testconfig)


	  skynet.exit()
  end)