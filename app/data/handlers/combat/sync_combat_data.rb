class SyncCombatData < Handler
	def self.process(session, msg, model)
		instance = model.instance

		# jsdata = CombatDataDB.read_combat_data(instance.pid)
		# puts(">>>>>>>>>jsdata  in sync_combat_data :#{jsdata}")
		# return suc if jsdata.nil?  || jsdata == ''

		# cdata = CombatData.new.from_json!(jsdata) 
		# return ng('internal_error') if cdata.nil?

		bsuc, ret = instance.sync_combat_data
		return ng(ret) if !bsuc

		instance.update_player
		return suc(ret)
	end
end