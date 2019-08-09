class ClearCurRoomID < Handler
	def self.process(session, msg, model)
		instance = model.instance
		instance.cur_room_id = nil
		suc
	end
end