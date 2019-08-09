class TeamMatchCancel < Handler
	def self.process(session, msg, model)
		instance = model.instance
		pid = instance.pid
		
		poolid = msg['poolid']
		id = msg['id']

		zone = model.chief.zone
		return ng("invalid_args") if id.nil? or poolid.nil?

		args = {
			:cmd => 'match_cancel',
			:pid => pid,
			:id => id,
			:poolid => poolid
		}

		csid = CSRouter.get_zone_checker(zone)
		RedisRpc.call(TeamManager, csid, args)

		res = {}
		res['success'] = true #instance.cur_team_id 
		res
	end
end