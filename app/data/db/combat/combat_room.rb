class CombatRoom
	include RedisHelper
	include Loggable

	@@room_ids = []
	@@room_infos = {}
	@@room_map = {}

	def self.create_room(args, res)
		puts "create_room"

		uid  = args.uid
    zone = args.zone
    name = args.name
    type = args.type

    exist_id = @@room_map[uid]
    do_remove_room(exist_id) if !exist_id.nil?

		id = RoomInfo.gen_room_id(uid)
		room_info = RoomInfo.new(type ,id, uid)
    
		room_info.add_member(0, uid, name)
		room_info.set_ready(uid, true)
    room_info.set_house_creator(uid, true)

    if type == "stand" 
    	room_info.add_member(1, "computer", "computer1")
		  room_info.set_ready("computer", true)

		  room_info.add_member(2, "computer", "computer2")
		  room_info.set_ready("computer", true)
		end  

		@@room_ids << id
		@@room_infos[id] = room_info 
		res['room_info'] = room_info.to_hash
		@@room_map[uid] = id
    
	end

	def self.remove_room(args, res)
		id = args.id

		do_remove_room(id)
		
	end

	def self.start_combat(args, res)		
		id = args.id
		room_info = @@room_infos[id]
		res["room_info"] = room_info.to_hash
		puts "[combat] start_combat room_info:#{room_info}"
		if room_info.nil?
			ng(res, "room_not_exist") 
			return
		end

		# if !room_info.combatable?
		# 	ng(res, "side_empty")
		# 	return
		# end

		if !room_info.all_ready?
			ng(res, "not_all_ready") 
			return
		end

		do_remove_room(id)

		arr = CombatServerDB.get_server
		ip = arr[0]
		port = arr[1]
		if ip.nil?
			ng(res, 'server_unavailable')
			return
		end

		srv_room_info =  {
				:ip => ip,
				:port => port,
				:token => id,
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

		# puts ">>>> room_info.member_pids:#{ room_info.member_pids}"
		Channel.publish('pvpcombat', 1, data)

	end

	def self.do_remove_room(id)
		room_info = @@room_infos[id]
		pid = room_info.creator
		@@room_map.delete( pid )
		@@room_ids.delete(id)
		@@room_infos.delete(id)
	end

	#op: removed / modified
	def self.notify_room_change(room_info, op)
		content = {
			:cmd => "sync_room",
			:data => {
				:op => op,
				:room_info => room_info.to_hash
			}
		}
		data = {:pids => room_info.member_pids,
						:content => content }
						
		Channel.publish('pvpcombat', 1, data)
	end

	def self.get_room_list(args, res)
		
		#stop = @@room_ids.length if stop > @@room_ids.length
    uid = args.uid
    name = args.name

    exist_id = @@room_map[uid]
    do_remove_room(exist_id) if !exist_id.nil?

		id = RoomInfo.gen_room_id(uid)
		room_info = RoomInfo.new("PVP" ,id, uid)

    room_info.add_member(0, uid, name)
    @@room_ids << id
		@@room_infos[id] = room_info 
    @@room_map[uid] = id

		start = 0
		stop  = @@room_ids.length

		infos = []
		(start...stop).each do |i|
			id = @@room_ids[i]
			infos << @@room_infos[id].to_hash
		end
    
		res['room_infos'] = infos
	end
 
	def self.get_room_info(args, res)
		id = args.id 
		room_info = @@room_infos[id]
		if room_info.nil?
       
		  ng(res,'')
			return
		end
		res['room_info'] = room_info.to_hash
	end

	def self.join_room(args, res)
		id = args.id
		uid = args.uid
    name = args.name

	 	room_info = @@room_infos[id]
	 	
	 	return ng(res, 'room_not_exist') if room_info.nil?
	 	# room_info.remove_member(uid) if room_info.in_room?(uid)
    full = room_info.full?
    return ng(res, 'full_member') if full
    room_info.remove_member(uid) if room_info.in_room?(uid)
    
    pos = room_info.find_vacant
 		room_info.add_member(pos, uid, name) 
    
	 	res['room_info'] = room_info.to_hash
    
	 	notify_room_change(room_info, 'modified')
	end


	def self.set_ready(args, res)
		id  = args.id
		uid = args.uid
		ready = args.ready

		room_info = @@room_infos[id]
		return ng(res, 'room_not_exist') if room_info.nil?
	 		
	 	room_info.set_ready(uid, ready)
	 	res['room_info'] = room_info.to_hash
 
    notify_room_change(room_info, 'modified')
	end

	def self.leave_room(args, res)
		puts ">>>>>res:#{res}"
		id = args.id
		uid = args.uid
		room_info = @@room_infos[id]

	 	return ng(res, 'room_not_exist') if room_info.nil?

		if room_info.creator?(uid)

			notify_room_change(room_info, 'remove')

			room_info.remove_member(uid)
			do_remove_room(id)
			return
		end

	 	room_info.remove_member(uid)

	 	res['room_info'] = room_info.to_hash

	 	notify_room_change(room_info, 'modified')
	end

	def self.ng(res, reason)
		res['success'] = false
		res['reason'] = reason
	end

	def self.perform(args)
    res = { 'success' => true }
    send(args.cmd, args, res) if args.cmd
    res
  end

end