class YousiPlayerIdManager

  include Loggable
  include RedisHelper

  # let fv id be different from standard user id
  # easier for test in development env
  RESERVED_ID_RANGE = UserHelper::RESERVED_ID_RANGE + 1_000_000 unless defined? RESERVED_ID_RANGE

  def self.get_player_id(user_id)
    player_id = redis.hget(map_key, user_id)
    if player_id.nil? or player_id == ''
      return nil
    else
      return player_id.to_i
    end
  end

  def self.substitute_user_id(orig_user_id, new_user_id)
    player_id = get_player_id(orig_user_id)

    if player_id.nil? or player_id == ''
      return false
    else
      redis.hset(map_key, new_user_id, player_id)
      redis.hdel(map_key, orig_user_id)
      return true
    end
  end

  def self.create_player_id(user_id)
    player_id = redis.hget(map_key, user_id)

    if player_id.nil? or player_id == ''
      player_id = redis.incr(counter_key) + RESERVED_ID_RANGE

      redis.hset(map_key, user_id, player_id)
    end

    return player_id.to_i
  end

  def self.all_user_ids
    redis.hkeys(map_key)
  end

private

  def self.redis
    get_redis :user
  end

  def self.map_key
    "yousi:player_map"
  end

  def self.counter_key
    "counter:yousi:player_id"
  end

end

