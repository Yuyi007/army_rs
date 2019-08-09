class GetRoomList < Handler
	def self.process(session, msg, model)
		instance = model.instance

		zone = model.chief.zone
    uid  = model.chief.id
    name = 

		args = {
			:cmd => 'get_room_list',
			:uid => uid,
			:name => instance.name
		}

		cid = CSRouter.get_zone_checker(zone)
		res = RedisRpc.call(CombatRoom, cid, args)
		puts ">>>>>>>>res:#{res}"
		res
	end
end