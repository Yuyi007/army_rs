class CombatInfoDB
	include RedisHelper
	include Loggable

	RECORD_COMBAT_INFO = %Q{
		local playerKey, combatKey = unpack(KEYS)
		local playerData, token, roomInfo = ARGV[1], ARGV[2], ARGV[3]

		for i=4, #ARGV do 
			local pidKey = ARGV[i]
			redis.call('hset', playerKey, pidKey, playerData)
		end

		redis.call('hset', combatKey, token, roomInfo)
	}
	def self.record_combat_info(pids, srv_room_info)
		token = srv_room_info[:token]
		player_data = {:entered => false, :token => token}
		player_data = Helper.to_json(player_data)

		keys = [player_cur_room_key, combat_info_key]
		args = [player_data, token,  Helper.to_json(srv_room_info)]
		args.concat(pids)
	
		redis.evalsmart(RECORD_COMBAT_INFO, keys: keys, argv: args)
	end

	READ_COMBAT_INFO = %Q{
		local playerKey, combatKey = unpack(KEYS)
		local pid = unpack(ARGV)
		local jsonData = redis.call('hget', playerKey, pid)
		if not jsonData then
			return nil
		end

		local data = cjson.decode(jsonData)
		local token = data.token
		if not token then 
			return nil 
		end

		local info = redis.call('hget', combatKey, token)
		return info
	}
	def self.read_combat_info(pid)
		info = redis.evalsmart(READ_COMBAT_INFO, keys: [player_cur_room_key, combat_info_key], 
																						 argv: [pid])
		# puts ">>>player_cur_room_key:#{player_cur_room_key} combat_info_key:#{combat_info_key} pid:#{pid} info:#{info}"
		info = Helper.to_hash(info) if !info.nil?
		info
	end

	WRITE_PLAYER_DATA = %Q{
		local playerKey, combatKey = unpack(KEYS)
		local pid, data = unpack(ARGV)
		
		data = cjson.decode(data)

		local jsonData = redis.call('hget',  playerKey, pid)
		if not jsonData then return end

		local curRoom  = cjson.decode(jsonData)
		local token 	 = curRoom.token
		if not token then return end

		local jsonInfo = redis.call('hget', combatKey, token)	
		if not jsonInfo then return end
		
		local info = cjson.decode(jsonInfo)
		local roomInfo = info.room_info
		if not roomInfo then return end

		roomInfo.player_data[pid] = data
		local jsonInfo = cjson.encode(info)

		redis.call('hset', combatKey, token, jsonInfo)	
	}
	def self.write_player_data(pid, data)
		jsonData = Helper.to_json(data)
		redis.evalsmart(WRITE_PLAYER_DATA, keys: [player_cur_room_key, combat_info_key], 
																			argv: [pid, jsonData])
	end

	private

	def self.redis
		get_redis(:rooms)
	end

	def self.combat_info_key
		"{combat}{combat_srv_room_infos}"
	end

	def self.player_cur_room_key
		"{combat}{player_cur_rooms}"
	end

end