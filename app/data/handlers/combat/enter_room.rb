class EnterRoom < Handler
	def self.process(session, msg, model)
		instance = model.instance
		uid = model.chief.id
		pname = model.instance.name
		id = msg['id']
		return ng("invalid_args") if id.nil?

		zone = model.chief.zone
		args = {
			:cmd => 'join_room',
			:uid => uid,
			:id => id,
			:name => pname,
		}

		cid = CSRouter.get_zone_checker(zone)
		res = RedisRpc.call(CombatRoom, cid, args)

    instance.cur_room_id = id if res.success
    res['cur_room_id'] = instance.cur_room_id 

		res
	end
end