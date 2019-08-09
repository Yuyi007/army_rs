
class AntiManipulationDb

  include Loggable
  include RedisHelper

  MAX_BLOCK_COUNT = 19

  def self.block_chat?(pid, text, to_pid, level)
    # d {"check block now111 222: #{pid}"}
    player_id = pid.to_s.split("_")[1]
    if self.is_block_user?(pid) || PermissionDb.deny_talk?(player_id)
      # d {"check block now 222"}
      return text, true
    end
   
    return text, false
  end


  def self.is_block_user?(pid)
    pids = pid.to_s.split("_")
    if pids.length == 3
      pid = pids[1]
    else
      pid = pids[0]
    end
    redis.hget(self.mblock_key, pid)
  end

  def self.add_block_list(pid, text, to_pid)
    pids = pid.to_s.split("_")
    if pids.length == 3
      pid = pids[1]
    else
      pid = pids[0]
    end
    detail = redis.hget(self.mblock_time_key, pid)

    if detail
      end_time, count = *detail.split(',')
    else
      end_time = 0
      count = 0
    end
    # d {"check block time: #{end_time}, #{count}, #{pid}"}
    now_time = Time.now.to_i
    if now_time > end_time.to_i
      count = 1
      end_time = now_time + 86400 # 24 * 60 * 60
      redis.del(self.mblock_detail_key(pid))
    else
      count = count.to_i + 1
      if count > MAX_BLOCK_COUNT then
        # add block user
        redis.hset(self.mblock_key, pid, true)
      end
    end
    redis.rpush(self.mblock_detail_key(pid), "#{text},#{to_pid}")
    redis.hset(self.mblock_time_key, pid, "#{end_time},#{count}")
    # block_details = redis.lrange(self.mblock_detail_key(pid), 0, -1)
    # d {"check block details: #{block_details}"}
  end

  def self.get_block_detail(pid)
    pids = pid.split("_")
    if pids.length == 3
      pid = pids[1]
    else
      pid = pids[0]
    end
    redis.lrange(self.mblock_detail_key(pid), 0, -1)
  end

  def self.remove_block_user(pid)
    pids = pid.split("_")
    if pids.length == 3
      pid = pids[1]
    else
      pid = pids[0]
    end

    redis.hdel(self.mblock_key, pid)
    redis.hdel(self.mblock_time_key, pid)
    redis.del(self.mblock_detail_key(pid))
  end

  def self.mchat_key
    'anti:mchat'
  end

  def self.mblock_key
    'anti:mblock'
  end

  def self.mblock_time_key
    "anti:mblock_time"
  end

  def self.mblock_detail_key(pid)
    "anti:mblock_detail_#{pid}"
  end

  def self.redis
    get_redis()
  end

end

