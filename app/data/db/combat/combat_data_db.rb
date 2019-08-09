class CombatDataDB

	include RedisHelper
	include Loggable

	def self.read_combat_data(pid)
		key = combat_data_key(pid)
		return redis.get(key)
	end

	def self.save_combat_data(cdata)
		pid = cdata.pid
		key = combat_data_key(pid)
		jsdata = cdata.to_json
		return redis.set(key, jsdata)
	end

    READ_LAST_COMBAT_RC = %Q{
		local key = unpack(KEYS)
		return redis.call('getset', key, '')
	}

	def self.read_last_combat_rc(pid)
		key = combat_last_rc_key(pid)
    keys = [key]

		ret = redis.evalsmart(READ_LAST_COMBAT_RC, keys: keys)

		# puts(">>>>>>>>>>>>last_combat_rc key  :#{key}")
		# puts(">>>>>>>>>>>>last_combat_rc value  :#{ret}")
		ret
	end

private

	def self.redis
		get_redis(:combat_data)
	end

	def self.combat_last_rc_key(pid)
		"{last_combat_rc}{#{pid}}"
	end

	def self.combat_data_key(pid)
		"{combat_data}{#{pid}}"
	end
end