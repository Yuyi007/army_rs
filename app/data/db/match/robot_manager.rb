class RobotManager
	include RedisHelper
	include Loggable

	@@robot_infos = {}
	@@robot_map = {}
	@@def_avatar = nil

	ROBOT_BEGIN_ID = 8000000

	GET_ROBOT_NEWID = %Q{
		local robot_data_key = KEYS[1]
        local maxid = redis.call('hget', robot_data_key, 'max_robotid')

        if maxid == false then
            maxid = 8000001         
        else
            maxid = maxid + 1
        end

        if maxid > 100000000 then
        	maxid = 1
        end

        redis.call('hset', robot_data_key, 'max_robotid', maxid)
        
        return maxid
	}
	def self.gen_robot_id()
		new_id = redis.evalsmart(GET_ROBOT_NEWID, keys: [robot_data_key], argv: [])
		new_id		
	end

	GET_ROBOT_MAXID = %Q{
		local robot_data_key = KEYS[1]
        local maxid = redis.call('hget', robot_data_key, 'max_robotid')

        if maxid == false then
            maxid = 8000000         
        end
        
        return maxid
	}
	def self.get_robot_maxid()
		max_id = redis.evalsmart(GET_ROBOT_MAXID, keys: [robot_data_key], argv: [])
		max_id		
	end

	def self.redis
		get_redis(:servers)
	end

	def self.robot_data_key
		"{checker}{robot_main_data}"
	end	

	def self.set_defavatar(avt)
		@@def_avatar = avt
	end

	def self.defavatar
		@@def_avatar
	end

	#robot apply switch flag
	def self.apply_flag
		false
	end

	####################################################################################

	def self.load_robots()
		max_id = get_robot_maxid()
		cnt = max_id - ROBOT_BEGIN_ID

		for i in 1..cnt
			id = ROBOT_BEGIN_ID + i

			rbUser = read(id)
			if !rbUser.nil?
				@@robot_infos[id] = rbUser
			end
		end
	end

	def self.get_new_robot()
		id = gen_robot_id()
		rb = RobotBase.new(rid, 1, 1)

		redis.setnx(user_key(id), rb.to_json)

		@@robot_infos[id] = rb
		rb
	end

	def self.read(id)
      raw = redis.get(user_key(id))
      if raw != nil
        RobotBase.new.from_json!(raw)
      else
        nil
      end
    end

    def self.update(rbUser)
		exist = true
		if rbUser.id then
			exist = read(rbUser.id)
		end
		if exist  then
			redis.set(user_key(user.id), rbUser.to_json)
			true
		else
			false
		end
    end

    def self.delete(id)
      rbuser = self.read(id)
      if rbuser
        redis.del(user_key(id))
        @@robot_infos.delete(id)
        rbuser
      end
      nil
    end

    ####################################################################################

	def self.user_key(id)
      "rb:#{id}"
    end

	

	

end