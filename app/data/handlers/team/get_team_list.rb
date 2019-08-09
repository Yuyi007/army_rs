class GetTeamList < Handler
	def self.process(session, msg, model)
		instance = model.instance
		page = msg['page']
		page_count = msg['page_count']
		return ng("invalid_args") if page.nil? || page_count.nil?

		page = page.to_i
		page_count = page_count.to_i

		zone = model.chief.zone
		args = {
			:cmd => 'get_team_list',
			:page => page,
			:page_count => page_count
		}

		cid = CSRouter.get_zone_checker(zone)
		res = RedisRpc.call(TeamManager, cid, args)
		res
	end
end