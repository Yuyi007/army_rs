class LeaveRoom < Handler
	def self.process(session, msg, model)
		instance = model.instance
		pid = instance.pid
		id = msg['id']
		return ng("invalid_args") if id.nil?

		zone = model.chief.zone
		args = {
			:cmd => 'leave_room',
			:pid => pid,
			:id => id
		}

		cid = CSRouter.get_zone_checker(zone)
		res = RedisRpc.call(CombatRoom, cid, args)
		instance.cur_room_id = nil if res.success
		
		res
	end
end