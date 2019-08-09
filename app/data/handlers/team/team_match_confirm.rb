class TeamMatchConfirm < Handler
	def self.process(session, msg, model)
		instance = model.instance
		pid = instance.pid
		
		csid = msg['csid']
		pairid = msg['pairid']
		ok = msg['ok']

		return ng("invalid_args") if csid.nil? or pid.nil? or ok.nil?

		args = {
			:cmd => 'match_confirm',
			:pid => pid,
			:pair_id => pairid,
			:ok => ok
		}

		RedisRpc.call(TeamManager, csid, args)

		res = {}
		res['success'] = true #instance.cur_team_id 
		res
	end
end