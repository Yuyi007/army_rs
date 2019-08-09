class TeamMemberReady < Handler
	def self.process(session, msg, model)
		instance = model.instance
		pid = instance.pid
		zone = model.chief.zone
		
		id = msg['id']
		ready = msg['ready']

		args = {
			:cmd => 'team_member_ready',
			:pid => pid,
			:id => id,
			:ready => ready
		}

		csid = CSRouter.get_zone_checker(zone)
		RedisRpc.call(TeamManager, csid, args)

		res = {}
		res['success'] = true  #instance.cur_team_id 
		res
	end
end