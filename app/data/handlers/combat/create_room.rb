class CreateRoom < Handler
	def self.process(session, msg, model)
		instance = model.instance
		uid = model.chief.id
		zone = model.chief.zone
		name = instance.name
		type = msg['type']

		args = {
			:cmd => 'create_room',
			:uid => uid,
			:zone => zone,
			:name => name,
			:type => type
		}

		cid = CSRouter.get_zone_checker(zone)
		res = RedisRpc.call(CombatRoom, cid, args)
		if res.success
			instance.cur_room_id = res["room_info"].id
			res['cur_room_id'] = instance.cur_room_id 
		end
		res
	end
end