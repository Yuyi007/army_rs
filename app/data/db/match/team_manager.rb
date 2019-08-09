# => team_message channel : 	1013
# 		sync_team	:
# 				modified\remove\remove_offline\match_request\member_ready\invit\kick_member
#
class TeamManager
	include RedisHelper
	include Loggable

	@@team_ids = []
	@@player_teamid = {}
	@@team_infos = {}
	@@team_map = {} #team_creator : team_id

	GET_TEAM_NEWID = %Q{
		local team_data_key = KEYS[1]
        local maxid = redis.call('hget', team_data_key, 'max_teamid')

        if maxid == false then
            maxid = 1
        else
            maxid = maxid + 1
        end

        if maxid > 100000000 then
        	maxid = 1
        end

        redis.call('hset', team_data_key, 'max_teamid', maxid)

        return maxid
	}
	def self.gen_team_id()
		new_id = redis.evalsmart(GET_TEAM_NEWID, keys: [team_data_key], argv: [])
		new_id
	end

	def self.redis
		get_redis(:servers)
	end

	def self.team_data_key
		"{combat}{team_main_data}"
	end

	####################

	def self.create_team(args, res)
		puts "create_team",args
		pid = args.pid
		zone = args.zone
		pdata = args.pdata
		chid  = args.chid
		team_type = args.team_type

		old_teamid = @@player_teamid[pid]
	 	ti = @@team_infos[old_teamid]
	 	puts "create_team", pid, ti
		if ti and !ti.creator?(pid)
			ng(res, 'team_already_in', 3)
			return

			#ti.remove_member(pid)
	 		#@@player_teamid.delete(pid)
	 		#notify_team_change(team_info, 'modified')
		end

		RobotManager.set_defavatar(pdata.avatar)
    	exist_id = @@team_map[pid]
    	do_remove_team(exist_id) if !exist_id.nil?

		id = gen_team_id()
		team_info = TeamInfo.new(id, pid, chid, team_type)
		# puts ">>> teaminfo:#{team_info}"

		team_info.add_member(pid, zone, pdata)
		@@team_ids << id
		@@player_teamid[pid] = id
		@@team_infos[id] = team_info
		res['team_info'] = team_info.to_hash
		@@team_map[pid] = id

		puts "cur team infos", @@team_infos
	end

	def self.new_rb_team(team_type, chid, team_score)
		tid = gen_team_id()
		rb = RobotManager.get_new_robot()
		team_info = TeamInfo.new(tid, rb.pid, chid, team_type)
		team_info.add_member(rb.pid, rb.zone, rb.pdata)
		team_info.set_ready(rb.pid, true)

		for i in 1..team_type
			rbmem = RobotManager.get_new_robot()
			team_info.add_member(rbmem.pid, rbmem.zone, rbmem.pdata)
			team_info.set_ready(rbmem.pid, true)
		end

		@@team_infos[team_info.team_id] = team_info
		team_info
	end

	def self.getteaminfo(team_id)
		team_info = @@team_infos[team_id]
		team_info
	end

	def self.remove_team(args, res)
		id = args.id

		do_remove_team(id)
	end

	def self.do_remove_team(id, reason = nil)
		team_info = @@team_infos[id]
		pid = team_info.creator
		@@team_map.delete( pid )
		@@team_ids.delete(id)
		@@team_infos.delete(id)
		
		pids = team_info.member_pids
	 	pids.each{|userid|
	 		@@player_teamid.delete(userid)
	 	}

		#delete in pool  team
		MatchManager.del_team_detail(id)

		if !reason.nil?
			notify_team_change(team_info, 'remove_offline', nil)
		else
			notify_team_change(team_info, 'remove', nil)
		end

		puts "team remove ", id, "cur team infos", @@team_infos
	end

	def self.notify_team_change(team_info, op, poolid = nil, reason = nil, kicked_pid = nil, change_name = nil)
		content = {
			:cmd => "sync_team",
			:data => {
				:op => op,
				:team_info => team_info.to_hash
			}
		}

		if kicked_pid.nil? == false
			content[:data][:kicked_pid] = kicked_pid
		end

		if change_name
      content[:data][:change_name] = change_name
		end

		if reason.nil? == false
			content[:data][:reason] = reason
		end

		if poolid.nil? == false
			content[:data][:poolid] = poolid
			# content[:poolid] = poolid
		end

		pids, zones = team_info.get_pidsandzones
		data = {:pids => pids,
						:zones => zones,
						:content => content }
		Channel.publish('team_message', zones, data)

		if !kicked_pid.nil?
			pids = []
			pids << kicked_pid
			data = {:pids => pids,
						:content => content }
			Channel.publish('team_message', zones, data)
		end
	end

	def self.get_team_list(args, res)
		page = args.page
		page_count = args.page_count

		start = (page - 1) * page_count
		stop = start + page_count

		infos = []
		(start...stop).each do |i|
			id = @@team_ids[i]
			infos << @@team_infos[id].to_hash
		end

		res['team_infos'] = infos
		res['length'] = @@team_ids.length

		puts res
	end

	def self.get_team_info(args, res)
		id = args.id
		team_info = @@team_infos[id]
		if team_info.nil?
	   		puts 'get_team_info error:', args, @@team_infos

			ng(res,'team_not_exist', 1)
			return
		end
		res['team_info'] = team_info.to_hash
	end

	def self.set_team_status(team_id, status)
		team_info = @@team_infos[team_id]
		if team_info
			team_info.set_status(status)
		end
	end

	def self.join_team(args, res)
		id = args.id
		pid = args.pid
		zone = args.zone
		pdata = args.pdata

		old_teamid = @@player_teamid[pid]
		if !old_teamid.nil?
			ng(res, 'team_already_in', 3)
			return
		end

		owner_teamid = @@team_map[pid]
		if !owner_teamid.nil?
			ng(res, 'team_already_in', 3)
			return
		end

	 	team_info = @@team_infos[id]
	 	if team_info.nil?
		 	ng(res, 'team_not_exist', 1)
		 	return
	 	end

	 	if team_info.status != 0
	 		ng(res, 'team_not_in_idle', 2)
	 		return
	 	end

		if team_info.membercount >= team_info.team_type + 1
			ng(res, 'team_on_max', 3)
			return
		end


    suc = team_info.add_member(pid, zone, pdata)

    if suc == -1
    	ng(res, 'not_join_team')
    	return
    end

	 	res['team_info'] = team_info.to_hash

	 	@@player_teamid[pid] = id

	 	notify_team_change(team_info, 'modified')
	end

	def self.leave_team(args, res)
		id = args.id
		pid = args.pid

		team_info = @@team_infos[id]
	 	if team_info.nil?
		 	ng(res, 'team_not_exist', 1)
		 	return
		end

		@@player_teamid.delete(pid)

		if team_info.creator?(pid)
			team_info.remove_member(pid)
			do_remove_team(id)

			return
		end

	 	team_info.remove_member(pid)

	 	res['team_info'] = team_info.to_hash

	 	notify_team_change(team_info, 'leave_team')
	end

	def self.kick_member(args, res)
		id = args.id
		kicked_pid = args.kicked_pid

		team_info = @@team_infos[id]
	 	if team_info.nil?
		 	ng(res, 'team_not_exist', 1)
		 	return
		end

		if team_info.creator?(kicked_pid)
			ng(res, 'cant_kick_team_creator', 2)
		 	return
			#team_info.remove_member(kicked_pid)
			#do_remove_team(id)

			#notify_team_change(team_info, 'kick_off_member')
		end

    name = ''
    team_info.members_info.each_with_index do |player, i|
      name = player[:pdata].name if player[:pid] == kicked_pid
    end

		team_info.remove_member(kicked_pid)

		res['team_info'] = team_info.to_hash
		notify_team_change(team_info, 'kick_off_member', nil, nil, kicked_pid, name)

	 	@@player_teamid.delete(kicked_pid)
	end

	def self.match_request(args, res)
		id = args.id
		team_info = @@team_infos[id]
		if team_info.nil?
			 ng(res, 'team_not_exist', 1)
			return
		end

		if team_info.check_addready? == false
			ng(res, 'team_not_all_ready', 2)
			return
		end

		if MatchManager.match_close?
			ng(res, 'match_pool_closed', 3)
			return
		end

    team_info.form_team

		score = team_info.team_score
		members = team_info.members_info
		chid    = team_info.ch_id

		pool_id = MatchPoolRouter.getSingleMatchPoolId(args.mtype, args.ctype, score)

		req = {:team_id => args.id,
					:zone => args.zone,
					:team_score => score,
					:pool_id => pool_id,
					:members_info => members,
					:ch_id => chid
				  }

		MatchManager.add_team(req, res)
		if res["success"]
			team_info.set_status(1)
			notify_team_change(team_info, 'match_request', pool_id)
		end

		puts "match_request", res
	end

	def self.team_invit(args, res)
		from_pid = args.from_pid
		to_pid = args.to_pid
		id = args.id
		to_zone = args.to_zone
		from_pdata = args.from_pdata
		mtype = args.mtype
		ctype = args.ctype
		# chid = args.chid

		team_info = @@team_infos[id]
	 	if team_info.nil?
			ng(res, 'team_not_exist', 1)
			return
		end

		if team_info.in_team?(to_pid)
			ng(res, 'team_already_in', 2)
			return
		end

		if team_info.membercount >= team_info.team_type + 1
			ng(res, 'team_on_max', 3)
			return
		end

		if team_info.status > 0
			ng(res, 'team_not_in_idle', 4)
			return
		end

    @@player_teamid.each do |id, team_id|
      return ng(res, 'frd_already_in_team', 3) if id == to_pid
    end

		content = {
			:cmd => "sync_team",
			:data => {
				:op => "invit",
				:team_info => team_info.to_hash,
				:from_pid => from_pid,
				:from_pdata => from_pdata,
				:tead_id => id,
				:mtype => mtype,
				:ctype => ctype,
				# :chid  => chid,
			}
		}
		pids = []
		pids << to_pid
		zones = []
		zones << to_zone
		data = {:pids => pids,
						:zones => zones,
						:content => content }

		Channel.publish('team_message', zones, data)
	end

	def self.team_member_ready(args, res)
		pid = args.pid
		id = args.id
		ready = args.ready

		team_info = @@team_infos[id]
	 	if team_info.nil?
		 	ng(res, 'team_not_exist', 1)
		 	return
		end

		team_info.set_ready(pid, ready)

		notify_team_change(team_info, 'member_ready')
	end

	def self.match_cancel(args, res)
		pid = args.pid
		poolid = args.poolid
		id = args.id

		team_info = @@team_infos[id]
	 	if team_info.nil?
		 	ng(res, 'team_not_exist', 1)
		 	return
		end

		team_info.set_status(0)

		MatchManager.match_cancel(poolid, id)

		#notify_team_change(team_info, 'match_cancel')

		content = {
			:cmd => "match_cancel",
			:pid => pid,
			:data => team_info.to_hash
		}
		if poolid.nil? == false
			#content[:data][:team_info][:poolid] = poolid
			content[:poolid] = poolid
		end
		pids, zones = team_info.get_pidsandzones
		data = {:pids => pids,
						:zones => zones,
						:content => content }
		Channel.publish('pvpcombat', zones, data)
	end

	def self.match_confirm(args, res)
		pid = args.pid
		pair_id = args.pair_id
		ok = args.ok

		MatchManager.comfirm_match_pair(pair_id, pid, ok)
	end

	def self.remove_player(args, res)#player_id, zone, session_id)
		player_id = args.player_id
		zone = args.zone
		session_id = args.session_id

		puts "remove_player", player_id, @@player_teamid,@@team_infos

		id = @@player_teamid[player_id]
		if id.nil? == false
			team_info = @@team_infos[id]
			team_info.set_status(0)

			MatchManager.dismiss_pair_on_playeroffline(player_id,team_info)
			if team_info.nil? == false
				if team_info.creator?(player_id)
					do_remove_team(id, "team_dismiss")
				else
					team_info.remove_member(player_id)
					@@player_teamid.delete(player_id)
					notify_team_change(team_info, 'member_offline')
				end
			end
		end
	end

	def self.ng(res, reason, errno)
		res['success'] = false
		res['errno'] = errno
		res['reason'] = reason
	end

	def self.perform(args)
    res = { 'success' => true }
    send(args.cmd, args, res) if args.cmd
    res
  end

end