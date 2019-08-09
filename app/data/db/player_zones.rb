# encoding: utf-8
# player_zones.rb
#

class PlayerZones
 
  include Jsonable
  include Loggable
  include RedisHelper

  attr_accessor :last_zones

  json_hash :last_zones, :PlayerZoneInfo

  gen_from_hash
  gen_to_hash

  def initialize
    @last_zones = {}
  end

  def self.get(player_id)
    redis_hash.hget_or_new(player_id)
  end

  def self.set(player_id, player_zones)
    redis_hash.hset(player_id, player_zones)
  end

  def self.del(player_id)
    redis_hash.hdel(player_id)
  end

private

  def self.redis_hash
    @@redis_hash ||= RedisHash.new(self.redis, self.key, PlayerZones)
  end

  def self.redis
    get_redis :user
  end

  def self.key
    'player_zones'
  end

end

class PlayerZoneInfo

  include Jsonable
  include Loggable

  attr_accessor :zone, :last_login, :num_instances

  gen_from_hash
  gen_to_hash

  def initialize zone = nil, last_login = nil, num_instances = nil
    @zone = zone
    @last_login = last_login
    @num_instances = num_instances
  end

end