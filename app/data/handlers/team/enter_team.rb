class EnterTeam < Handler
	def self.process(session, msg, model)
		instance = model.instance
		pid = instance.pid
		id = msg['id']
		chid = msg['chid']
		return ng("invalid_args") if id.nil?
		return ng("invalid_chid") if chid.nil?
   
    
		zone = model.chief.zone
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
			:cmd => 'join_team',
			:pid => pid,
			:id => id,
			:zone => zone,
			:pdata => pdata.to_hash
		}
    
		cid = CSRouter.get_zone_checker(zone)
		res = RedisRpc.call(TeamManager, cid, args)
    RegisterChannel.process(session, msg, model) if res.success 
		res
	end
end