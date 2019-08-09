class CreateTeam < Handler
	def self.process(session, msg, model)
		instance = model.instance
		puts "createteam",msg
		pid = instance.pid
		zone = model.chief.zone
		team_type = msg["team_type"]
    chid  = msg["chid"]
		return ng("invalid_args") if team_type.nil?
		return ng("not_ch_id") if chid.nil?
		# maptype = msg.maptype
    channel_msg =  RegisterChannel.process(session, msg, model)
    chid = channel_msg['chid']

		def_avatar = instance.avatar_data.get_curr_equipped()

		pdata = CombatPlayerData.new
		pdata.avatar = def_avatar.to_hash
		pdata.icon = instance.icon
		pdata.icon_frame = instance.icon_frame
		pdata.level = instance.level
		pdata.name = instance.name
		pdata.score = instance.combat_stat.score
		pdata.selected_car = instance.avatar_data.selected_car

		args = {
			:cmd => 'create_team',
			:pid => pid,
			:zone => zone,
			:team_type => team_type,
			:chid  => chid,
			:pdata => pdata.to_hash

		}
    
		cid = CSRouter.get_zone_checker(zone)
		res = RedisRpc.call(TeamManager, cid, args)

		res
	end
end