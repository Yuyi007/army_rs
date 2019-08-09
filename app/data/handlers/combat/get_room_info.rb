class GetRoomInfo < Handler
	def self.process(session, msg, model)
		instance = model.instance
		id = msg['id']
		return ng("invalid_args") if id.nil?

		zone = model.chief.zone
		args = {
			:cmd => 'get_room_info',
			:id => id
		}

		cid = CSRouter.get_zone_checker(zone)
		RedisRpc.call(CombatRoom, cid, args)
	end
end