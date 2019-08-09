class MatchManager
	@@inited 	= false
	@@sid = nil
	@@profiles 	= {} #profile instances of PoolProfile
	@@pools 		= {}	

	@@player_pool_team = {}

	include RedisHelper
	include Loggable

	def self.init(sid, zones)
		return if @@inited
		@@sid = sid

		init_pools(zones)

		init_pool_last_match_tick
		@@inited = true
	end

	def self.init_pool_profiles
		cfgs = MatchingPoolsDB.get_all_pools
		@@profiles = {}
		cfgs.each do |x|
			@@profiles[x.id] = x
		end
	end

	def self.get_pool_klass(profile)
		clz = nil
		if profile.combat_type == MatchCombatType::CT_1V1 then
			clz = TeamMatch1V1 
		elsif profile.combat_type == MatchCombatType::CT_2V2 then
			clz = TeamMatch2V2 
		elsif profile.combat_type == MatchCombatType::CT_3V3 then
			clz = TeamMatch3V3 
		elsif profile.combat_type == MatchCombatType::CT_4V4 then
			clz = TeamMatch4V4 
		elsif profile.combat_type == MatchCombatType::CT_5V5 then
			clz = TeamMatch5V5 
		end
		return clz
	end

	def self.init_pools(zones)
		init_pool_profiles

		zones.each do |zone|
			@@pools[zone] = {}
			zps = @@pools[zone]

			@@profiles.each do |id, x|
				info "init pool id:#{id} x:#{x}"
				clz = get_pool_klass(x)

				if !clz.nil?
					pool = clz.new(x.score_min, x.score_max)

					redis.call('hset', matchpool_tickkey(zone), id, Time.now.to_i)
					redis.call('hset', matchpool_teamcountkey(zone), id, 0)

					#redis.hset(matchpool_tickkey, id, Time.now.to_f)
					#redis.hset(matchpool_detailkey, id, Jsonable.dump_hash(x))
					#redis.hset('testss','tt','fdsafd')
					#info "test redis"

					zps[x.id] = pool
				end
			end
		end
	end

	# TeamInfo => {
	# 							:team_id => id,
	# 							:members_info => [
	# 																	{  
	# 																		:pool_id => pool_id,
	# 																		:zone => zone
	# 																		:pdata => CombatPlayerData
	# 																	}
	# 															 ]
	# 							}
	# 
	#
	
	def self.add_team(args, res)
		tid = args[:team_id]
		zone = args[:zone].to_i
		score = args[:team_score]
		pool_id = args[:pool_id]
		mi = args[:members_info]
		ch_id = args[:ch_id]

		zps = @@pools[zone]
		pool = zps[pool_id]
		info "add team[#{tid}] to pool:#{pool_id} #{@@profiles[pool_id]}"
		return ng('pool_not_exist',res,3) if pool.nil?

		add_team_detail(args)
		ret = pool.add_team(tid, score, mi, ch_id)
		if ret == false
			return ng('str_pool_type_mismatch', res, 4)
		end

		mi.each do |mItem|
			pid = mItem[:pid]

			@@player_pool_team[pid] = {:zone => zone, :pool_id => pool_id, :team_id => tid}
		end		
		puts "@@player_pool_team",@@player_pool_team

		return {'success' => true}
	end

	def self.reload_pools(args, res)
		init_pool_profiles

		zones = CSRouter.get_checker_zones(@@sid)

		zones.each do |zone|
			zps = @@pools[zone]
			@@profiles.each do |id, x|
				clz = get_pool_klass(x)

				if !clz.nil? 
					if zps[x.id].nil?
						info "reload add new pool:#{x}"
						pool = clz.new(x.score_min, x.score_max)
						zps[x.id] = pool
					else
						pool = zps[x.id]
						info "reload pool score range:#{x.id} old_range:#{pool.begin_score}~#{pool.end_score} new_range:#{x.score_min}~#{x.score_max}"
						pool.begin_score = x.score_min
						pool.end_score = x.score_max
					end
				end
			end
		end
	end

	def self.ng(reason, res = nil, errno=1)
    res ||= {}
    res.reason = reason
    res.errno=errno
    res.success = false
    res
  end

  def self.success
  	{:success => true}
  end

  def self.perform(args)
    res = { 'success' => true }
    send("#{args.cmd}", args, res) if args.cmd
    res
  end

  private

    def self.redis
      get_redis :team_match
    end

    def self.matchpool_tickkey(zone)
      "{matchpool}:tick:#{zone}"
    end

    def self.matchpool_roomkey(pool_id)
      "{matchpool}:room:#{pool_id}"
    end

    def self.matchpool_teamcountkey(zone)
      "{matchpool}:teamcount:#{zone}"
    end

    def self.match_close_flag()
    	"{match_close_flag}"
    end
end