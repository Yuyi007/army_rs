require 'net/https'
require 'uri'
require 'json'
require 'digest'

class AccountMan

	include RedisHelper

	def self.getVerificationCode(phoneno)
		vcode = gen_verificationcode(phoneno)
		redis.set(user_phone_key(phoneno), vcode)
        redis.pexpire(user_phone_key(phoneno), 60 * 1000)
	end

	def self.gen_verificationcode(phoneno)
		'134398'
	end

	def self.register_phone(phoneno, vcode)
		_vcode = redis.get(user_phone_key(phoneno))
		return true if _vcode==vcode

		false
	end

	def self.redis
		get_redis :user
    end

    def self.user_phone_key(phoneno)
    	"u:#{phoneno}:vtoken"
    end

end