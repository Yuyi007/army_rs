class ConfirmCombatCar < Handler
	def self.process(session, msg, model)
		instance = model.instance
		pid = instance.pid
		tid = msg['tid']
		selected_scheme = msg['scheme_id']
		return ng("invalid_args") if tid.nil?
		# data = instance.avatar_data.equipped[tid] 
		data = instance.avatar_data.get_curr_equipped(tid, selected_scheme)
		icon  = instance.icon
		level = instance.level
		
		return ng("avatar_not_exist") if data.nil?

		player_data = {:avatar => data.to_hash, :icon => icon, :level => level}
		CombatInfoDB.write_player_data(pid, player_data)

		res = {:success => true}
		res
	end
end