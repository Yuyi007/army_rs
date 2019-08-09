class TeamKickMember < Handler
	def self.process(session, msg, model)
		instance = model.instance
		kicked_pid = msg['kicked_pid']
		id = msg['team_id']
		return ng("invalid_args") if id.nil?

		zone = model.chief.zone
		args = {
			:cmd => 'kick_member',
			:kicked_pid => kicked_pid,
			:id => id
		}

		cid = CSRouter.get_zone_checker(zone)
		res = RedisRpc.call(TeamManager, cid, args)
		#instance.cur_team_id = nil if res.success
		
		res
	end
end