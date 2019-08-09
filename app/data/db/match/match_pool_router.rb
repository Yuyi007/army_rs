class MatchPoolRouter
	#单人匹配,简单根据玩家分数和玩法类型找到对应池子
	#@mtype 地图类型
	#@ctyp 	战斗类型
	#@score	分数 
	#return pool id
	def self.getSingleMatchPoolId(mtype, ctype, score)
		puts "getSingleMatchPoolId", mtype, ctype, score

		profiles = MatchingPoolsDB.get_all_pools
		puts "pools", profiles

		profiles.each do |pool|
			if (pool.map_type == mtype && pool.combat_type == ctype &&
					score >= pool.score_min && score <= pool.score_max) 
				return pool.id
			end
		end
	end

end