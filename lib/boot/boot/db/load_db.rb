# LoadDb.rb
# log load data to redis
#
# Deprecated: use Statsable instead

module Boot

  class LoadDb

    include RedisHelper

    def self.update data
      redis.hset(load_key, AppConfig.server_id, data)
    end

  private

    def self.redis
      get_redis :user
    end

    def self.load_key
      'cocs:load'
    end

  end

end