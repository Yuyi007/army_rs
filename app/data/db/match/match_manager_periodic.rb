# => pvpcombat channel :   1005
#     context : cmd
#         pair_match\pair_dismiss\pair_confirm\start_combat
#
class MatchManager
	@@hsrgn = 10 
	@@match_interval = 5
	@@tick = 0

  @@get_match_setting_tick = 0
  @@close_match = 0

	@@last_match_ticks = {}


	@@team_details = {} 
	@@matched_pairs = {}
	@@pair_uuid = 0
	@@pair_timeout = 20 #second

  @@player_pair = {}

	def self.add_team_detail(args)
		tid = args[:team_id]
    detail = {}
    args.each do |k,v|
      detail[k] = v
    end
		@@team_details[tid] = detail
	end

	def self.del_team_detail(tid)
		@@team_details.delete(tid)

    @@pools.each do |zone, pls|
      pls.each do |id, pool|
          pool.remove_team(tid)
        end
      end
	end

	def self.get_team_detail(tid)
		@@team_details[tid]
	end

	def self.gen_pair_id
		@@pair_uuid += 1
		@@pair_uuid = 0 if @@pair_uuid > 10000000
		@@pair_uuid
	end


	#in order to smooth cpu spike
	def self.init_pool_last_match_tick()
		@@pools.each do |zone, pls|
      @@last_match_ticks[zone] = {}
      lmts = @@last_match_ticks[zone]
      pls.each do |id, pool|
  			lmts[id] = rand(@@hsrgn)
      end
		end
	end

  def self.get_pair_pids(pair_id)
    pids = []

    pmInfo = @@matched_pairs[pair_id]
    if pmInfo.nil? == false
      pair = pmInfo[:pair]

      tms = []
      tms.concat(pair[:left]).concat(pair[:right])

      tms.each do |item|
        tid = item[:team_id]
        mi = item[:members_info]
        mi.each do |info|
          pids  << info[:pid]
        end
      end
    end

    pids
  end

  def self.dismiss_pair_on_playeroffline(playid, teaminfo)

    # puts "player_pair", @@player_pair
    pair_id = @@player_pair[playid]
    if pair_id.nil? == false
      mp = @@matched_pairs[pair_id]
      return if mp.nil? 
      # puts "player offline pair dismiss", mp

      content = {
        :cmd => 'pair_dismiss', 
        #reason => 'str_team_pair_dismiss',
        :offline_pid => playid,
        :pair_id => mp[:pair_id]
      }
      publish_msg_to_mp(mp, content, playid)

      @@matched_pairs.delete( pair_id )
      del_team_detail_by_mp( mp )

      pair = mp[:pair]
      tms = []
      tms.concat(pair[:left]).concat(pair[:right])
      tms.each do |item|
        tid = item[:team_id]
        mi = item[:members_info]
        mi.each do |info|
          @@player_pair.delete(info[:pid])
        end
      end   
    else
      piInfo = @@player_pool_team[playid]    
      puts "player offline match cancel", playid, @@player_pool_team  

      if !piInfo.nil?
        pool_id = piInfo[:pool_id]
        team_id = piInfo[:team_id]
        zone = piInfo[:zone]

        zps = @@pools[zone]
        pool = zps[pool_id]

        pool.remove_team(team_id)

        #ti = @@team_details[team_id]
        ti = teaminfo#TeamManager.getteaminfo(team_id)

        puts "$$get team info", team_id, ti
        if !ti.nil?
          pids = ti.member_pids
          pids.each do |pid|
            #@@player_pool_team.delete(pid)
          end          

          content = {
            :cmd => "match_dismiss",
           # :reason => 'str_team_pair_dismiss',
            :data => ti,
            :offline_pid => playid,
            :poolid => pool_id
          }

          data = {:pids => pids,
                  :content => content }           
          Channel.publish('pvpcombat', nil, data)
        end
      end   
    end
  end

  def self.update
  	@@tick += 1

    @@get_match_setting_tick = @@get_match_setting_tick + 1
    if @@get_match_setting_tick >= 10 
      @@close_match = redis.call('get', match_close_flag)#redis.get(match_close_flag, id)
    end

  	#check pairs
    # puts "check pairs", @@last_match_ticks
  	@@pools.each do |zone, pls|
      # puts "pools", zone, pls
      lmts = @@last_match_ticks[zone]
      return if lmts.nil?

      pls.each do |id, pool|
        if @@get_match_setting_tick >= 5 
          redis.call('hset', matchpool_tickkey(zone), id, Time.now.to_i)
          redis.call('hset', matchpool_teamcountkey(zone), id, pool.team_count)
        end

  	  	last_tick = lmts[id] || 0
  	  	if (@@tick - last_tick) >= @@match_interval
  	  		lmts[id] = @@tick
  	  		pairs = pool.do_match          

  	  		pairs.each do |pair|
  	  			pair_id = gen_pair_id
  	  			@@matched_pairs[pair_id] = { :pair_id => pair_id, 
                                        :zone => zone,
        	  														:pool_id => id, 
        							  								:start_tick => @@tick, 
        							  								:pair => pair, 
        	  														:notified => false,
        	  														:confirms => {}}

            pidsInPair = get_pair_pids(pair_id)
            pidsInPair.each do |p_id|
              @@player_pair[p_id] = pair_id

              #@@player_pool_team.delete(p_id)
            end
  	  		end
        end
	  	end
	  end

    if @@get_match_setting_tick >= 10 
      @@get_match_setting_tick = 0
    end

    # puts "get matched_pairs", @@matched_pairs

	  #notify clients and check timeout pairs
	  to_dels = []
	  @@matched_pairs.each do |pair_id, mp|
     
	  	pair = mp[:pair]
	  	if !mp[:notified]
	  		mp[:notified] = true
	  		notify_pair_clients(mp)
	  	else
		  	elapse = @@tick - mp[:start_tick]
		  	to_dels << mp if elapse >= @@pair_timeout
		  end
	  end

	  to_dels.each do |x|
	  	@@matched_pairs.delete(x[:pair_id])
	  end
  end

  def self.notify_pair_clients(mp)
    info "notify_pair_clients"
  	now = Time.now.to_i
  	match_info = {
  									:csid => AppConfig.server_id, 
  									:pair_id => mp[:pair_id], 
                    :pair_info => mp,
  									:time_stamp => now
  							 }

  	content = 	{ 
									:cmd => 'pair_match', 
									:data => match_info
  							}

  	publish_msg_to_mp(mp, content)
  end

  def self.publish_msg_to_mp(mp, content, exclude_pid = nil)
		data = 			{ 
  					 				:pids => [], 
  					 				:content => content
  							}

  	pair = mp[:pair]
  	tms = []
  	tms.concat(pair[:left]).concat(pair[:right])

  	tms.each do |item|
  		tid = item[:team_id]
  		#ti = @@team_details[tid]
  		mi = item[:members_info]
  		mi.each do |info|
  			next if exclude_pid == info[:pid]
        
  			data[:pids] 	<< info[:pid]
        # data[:zones] << info[:zone]
  		end
  	end

  	Channel.publish('pvpcombat', nil, data)
  end

  def self.del_team_detail_by_mp(mp)
  	pair = mp[:pair]
  	tms = []
  	tms.concat(pair[:left]).concat(pair[:right])
  	tms.each do |item|
  		tid = item[:team_id]
  		del_team_detail(tid)
  	end
  end

  def self.match_cancel(pool_id,  id)
    @@pools.each do |zone, pls|
      pls.each do |poolid, pool|
          if pool_id == poolid
            pool.remove_team(id)
          end
        end
      end
  end

  def self.notify_pair_dismiss(mp, pid)
  	content = {
  		:cmd => 'pair_dismiss', 
			:pair_id => mp[:pair_id]
  	}
  	publish_msg_to_mp(mp, content)
  end

  def self.notify_pair_confirm(mp, pid)
    sendmp = mp.clone
    sendmp.delete(:pair)
    content = {
      :cmd => 'pair_confirm', 
      :pair_info => sendmp
    }
    publish_msg_to_mp(mp, content)
  end

  def self.comfirm_match_pair(pair_id, pid, ok)
    puts "comfirm_match_pair", pair_id, pid, ok
    
  	mp = @@matched_pairs[pair_id]
		if mp.nil?
			info "Player:#{pid} confirm match pair ok:#{ok} but matched pair:#{pair_id} not exist!"
			return ng('not_exist',nil, 1)
		end

  	if !ok
  		notify_pair_dismiss( mp, pid )
  		@@matched_pairs.delete( pair_id )
  		del_team_detail_by_mp( mp )
  		return success

    else
      mp = @@matched_pairs[pair_id]
      confirms = mp[:confirms]
      confirms[pid] = true    

      notify_pair_confirm(mp, pid)

      check_match_all_confirmed(mp)
  	end
  end

  def self.check_match_all_confirmed(mp)
  	confirms = mp[:confirms]
  	pair = mp[:pair]
  	tms = []
  	tms.concat(pair[:left]).concat(pair[:right])
  	tms.each do |item|
      puts ".....tms", item
  		ti = @@team_details[item.team_id]
  		# mi = ti[:members_info]
      mi = item[:members_info]
      puts mi
      puts item[:members_info]
  		item[:members_info].each do |info|
  			pid = info[:pid]
  			return if not confirms[pid]
  		end
  	end

  	#gen room info and notify clients to start combat
  	pool_id = mp[:pool_id]
  	profile = @@profiles[pool_id]
    ctype = profile.combat_type
    mtype = profile.map_type
  	rid = RoomInfo.gen_room_id(pool_id, mtype, ctype)

  	room_info = RoomInfo.new(ctype, rid, 'match_pool', 0, mtype, 1)

  	pids  = []
  	pair[:left].each do |item|
  		#ti = @@team_details[item.team_id]
      side = 0
  		mi = item[:members_info]
      chid = item[:ch_id]
      room_info.add_side_chid(side, chid)

  		mi.each do |info|
  			pid = info[:pid]
  			zone = info[:zone]
  			pdata = info[:pdata]
  			team = info[:team]
  			
  			seat = room_info.find_vacant(side)
  			room_info.add_member(side, seat, pid, pdata, team)
				room_info.set_ready(side, pid, true)

        @@player_pair.delete(pid)
        @@player_pool_team.delete(pid)

				pids  << pid
  		end  		
  	end

  	pair[:right].each do |item|
  		#ti = @@team_details[tid]
      side = 1
  		mi = item[:members_info]
      chid = item[:ch_id]
      room_info.add_side_chid(side, chid)
      
  		mi.each do |info|
  			pid = info[:pid]
  			zone = info[:zone]
  			pdata = info[:pdata]
  			team = info[:team]
  			
  			seat = room_info.find_vacant(side)
  			room_info.add_member(side, seat, pid, pdata, team)
				room_info.set_ready(side, pid, true)

        @@player_pair.delete(pid)
        @@player_pool_team.delete(pid)

				pids  << pid
  		end  		
  	end
    
  	arr = CombatServerDB.get_server
		ip, port = arr[0], arr[1]
		if ip.nil? || port.nil?
			return ng('server_unavailable')
		end

		srv_room_info =  {
				:ip => ip,
				:port => port,
				:token => rid,
				:room_info => room_info.to_hash
			}

		#record room info for ervery player
		pids = room_info.member_pids
		CombatInfoDB.record_combat_info(pids, srv_room_info)
			
		content = {
			:cmd => "start_combat",
			:data => srv_room_info
		}

		data = {:pids => pids,
						:content => content }

		puts ">>>> room_info:#{ room_info}"
		Channel.publish('pvpcombat', nil, data)

		#remove matched pair and team details
		@@matched_pairs.delete( mp[:pair_id] )
  	del_team_detail_by_mp( mp )

    redis.hset(matchpool_roomkey(pool_id), rid, Jsonable.dump_hash(room_info.to_hash))
  end

  def self.match_close?
    @@close_match == 1
  end

  def self.gen_room_id(pool_id, mt, ct)
  	now = Time.now.to_i
		"RID:#{pool_id}:#{mt}:#{ct}:#{now}" 
  end

  def self.read_by_matching_closeflag()
    redis.get(match_close_flag)
  end

  def self.save_by_matching_closeflag(status)
    redis.set(match_close_flag,status)
  end

  def self.read_by_matchpool_tick(zone)
    redis.hgetall(matchpool_tickkey(zone))
  end

  def self.read_by_matchpool_team(zone)
    redis.hgetall(matchpool_teamcountkey(zone))
  end
end
