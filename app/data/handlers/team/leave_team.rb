class LeaveTeam < Handler
	def self.process(session, msg, model)
		instance = model.instance
		pid = instance.pid
		id = msg['id']
		return ng("invalid_args") if id.nil?

		zone = model.chief.zone
		args = {
			:cmd => 'leave_team',
			:pid => pid,
			:id => id
		}

		cid = CSRouter.get_zone_checker(zone)
		res = RedisRpc.call(TeamManager, cid, args)
		#instance.cur_team_id = nil if res.success
		
		res
	end
end