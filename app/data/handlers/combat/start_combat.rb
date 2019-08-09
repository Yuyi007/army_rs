class StartCombat < Handler
	def self.process(session, msg, model)
		instance = model.instance
		id = msg['id']
		puts "[combat] id:#{id}"
		return ng("invalid_args") if id.nil? 

		zone = model.chief.zone
		args = {
			:cmd => 'start_combat',
			:id => id
		}

		cid = CSRouter.get_zone_checker(zone)
		puts "[combat] cid:#{cid}"
		RedisRpc.call(CombatRoom, cid, args)
	end
end