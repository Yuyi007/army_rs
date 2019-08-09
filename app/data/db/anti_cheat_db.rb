
class AntiCheatDb

  include Loggable
  include RedisHelper

  def self.add_monitor(id)
    now = Time.now.to_i
    redis.zadd(monitor_key, now, id)
  end

  def self.remove_monitor(id)
    redis.zrem(monitor_key, id)
  end

  def self.monitor_time(id)
    redis.zscore(monitor_key, id)
  end

  def self.recent_monitors(min, max, offset, count, with_scores)
    redis.zrevrangebyscore(monitor_key, max, min, limit: [offset, count], with_scores: with_scores)
  end

  def self.clear_monitors()
    redis.del(monitor_key)
  end

  def self.record_cheater(id, zone, *params)
    add_cheater(id)
    ActionDb.log_action(id, zone, *params)
  end

  def self.add_cheater(id)
    now = Time.now.to_i
    redis.zadd(cheater_key, now, id)
  end

  def self.recent_cheaters(min, max, offset, count, with_scores)
    redis.zrevrangebyscore(cheater_key, max, min, limit: [offset, count], with_scores: with_scores)
  end

  def self.remove_cheater(id)
    redis.zrem(cheater_key, id)
  end

  def self.cheater_time(id)
    redis.zscore(cheater_key, id)
  end

  def self.clear_cheaters()
    redis.del(cheater_key)
  end

  def self.monitor_key
    'anti:cheat_mon'
  end

  def self.cheater_key
    'anti:cheaters'
  end

  def self.redis
    get_redis()
  end

end
