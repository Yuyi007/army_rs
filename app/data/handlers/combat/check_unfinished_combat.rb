class CheckUnfinishedCombat < Handler
	def self.process(session, msg, model)
		instance = model.instance
		data = CombatInfoDB.read_combat_info(instance.pid)
		{:success => true, 
			:data => data}
	end
end