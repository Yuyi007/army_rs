class CombatRoomStatusDB

	include RedisHelper
	include Loggable


	def self.read_room_close_flag()
		key = room_close_flag_key()
		return redis.get(key)
	end

	def self.save_room_close_flag(status)
		key = room_close_flag_key()
		return redis.set(key, status)
	end

private

	def self.redis
		get_redis()
	end

	def self.room_close_flag_key()
		"{room_close_flag}"
	end


end