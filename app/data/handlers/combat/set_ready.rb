class SetReady < Handler
	def self.process(session, msg, model)
		instance = model.instance
		pid = instance.pid
		id = msg['id']
		side = msg['side']
		ready = msg['ready']
		return ng("invalid_args") if id.nil? || ready.nil? || side.nil?
    puts "id:#{id}"
    puts "side:#{side}"
    puts "ready:#{ready}"
    
		zone = model.chief.zone
		args = {
			:cmd => 'set_ready',
			:pid => pid,
			:id => id,
			:side => side, 
			:ready => ready
		}

		cid = CSRouter.get_zone_checker(zone)
		RedisRpc.call(CombatRoom, cid, args)
	end
end