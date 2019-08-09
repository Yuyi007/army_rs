class TeamInvit < Handler
	def self.process(session, msg, model)
		instance = model.instance
		from_pid = instance.pid
		to_pid = msg['to_pid']
		id = msg['id']
		to_zone = session.zone
		mtype = msg["mtype"]
		ctype = msg["ctype"]
		# chid = msg['chid']

		return ng("invalid_args") if id.nil? or to_zone.nil? or to_pid.nil?
		player_info = Player.read_by_id(to_pid, to_zone)
		# return ng('str_friend_offline') if !player_info.online

		zone = model.chief.zone
		from_pdata = CombatPlayerData.new
		from_pdata.icon = instance.icon
		from_pdata.icon_frame = instance.icon_frame
		from_pdata.level = instance.level
		from_pdata.name = instance.name
		from_pdata.score = instance.combat_stat.score
		from_pdata.selected_car = instance.avatar_data.selected_car


		args = {
			:cmd => 'team_invit',
			:from_pid => from_pid,
			:to_pid => to_pid,
			:to_zone => to_zone,
			:from_pdata => from_pdata,
			:id => id,
			:mtype => mtype,
			:ctype => ctype,
			# :chid  => chid,
		}
    

    # RegisterChannel.process(session, msg, model)
		cid = CSRouter.get_zone_checker(zone)
		res = RedisRpc.call(TeamManager, cid, args)
		#instance.cur_team_id = nil if res.success
		res.online = player_info.online
		res
	end
end