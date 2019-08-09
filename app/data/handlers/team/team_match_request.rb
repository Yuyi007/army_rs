class TeamMatchRequest < Handler
	def self.process(session, msg, model)
		instance = model.instance
		pid = instance.pid
		id = msg['id']
		mtype = msg['mtype']
		ctype = msg['ctype']

		return ng("invalid_args") if id.nil?

		zone = model.chief.zone

		def_avatar = instance.avatar_data.get_curr_equipped()
		pdata = CombatPlayerData.new
		pdata.avatar = def_avatar.to_hash
		pdata.icon = instance.icon
		pdata.icon_frame = instance.icon_frame
		pdata.level = instance.level
		pdata.name = instance.name
		pdata.score = instance.combat_stat.score

		#score = 1000
		#pool_id = MatchPoolRouter.getSingleMatchPoolId(mtype, ctype, score)

		args = {
			:cmd => 'match_request',
			:pid => pid,
			:id => id,
			:zone => zone,
			#:poolid => pool_id,
			:mtype => mtype,
			:ctype => ctype,
			:pdata => pdata.to_hash
		}

		cid = CSRouter.get_zone_checker(zone)
		res = RedisRpc.call(TeamManager, cid, args)

		#res = {}
		#res['poolid'] = pool_id
		#res['id'] = id
		#res['success'] = true #instance.cur_team_id 

		res
	end
end