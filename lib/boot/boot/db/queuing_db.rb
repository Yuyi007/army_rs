
module Boot

  # Queuing System
  # Queue up players if current online users are too much (exceeds zone setting max_online)
  class QueuingDb

    include Loggable
    include RedisHelper

    MAX_DEQUEUE_BATCH = 1    # max dequeued player count at one time
    LOGIN_GRACE_TIME = 300   # once logged in, grace time for skipping next queuing
    RENEW_GRACE_TIME = 120   # once offline, grace time for skipping next queuing
    OVERFLOW_RATE = 1.2      # overflow rate that online can exceeds max online

    # Check whether the player should queue up
    # Note that since we do not lock until online count is increased,
    # this check is not strict. i.e. online count may exceeds max online
    #
    # @return [bool] whether should queue up
    def self.should_queue? player_id, zone
      max_online = get_max_online(zone)
      if max_online <= 0
        return false
      end

      # check id whitelist
      if DynamicAppConfig.queuing_settings.in_id_whitelist?(player_id)
        return false
      end

      cur_online = SessionManager.num_online(zone)

      if cur_online < max_online
        return false
      else
        if (cur_online < max_online * OVERFLOW_RATE)
          # check temporary entry key
          # temporary entry key was set with a timeout (5 mins)
          # when temporary entry key exists, player can enter game without queuing
          entry_key = self.entry_key(player_id, zone)
          if redis.exists(entry_key)
            return false
          end
        end

        return true
      end
    end

    def self.exceeds_max_online?(zone, max_online = nil)
      max_online = max_online || get_max_online(zone)

      # check current online num < max_online
      cur_online = SessionManager.num_online(zone)
      # puts "cur_online=#{cur_online} max_online=#{max_online}"

      return cur_online >= max_online
    end

    def self.get_max_online(zone)
      # check max_online infinity setting
      zone_setting = DynamicAppConfig.zone_settings.settings[zone]
      if zone_setting then
        max_online = zone_setting.max_online
      else
        max_online = DynamicAppConfig::ZoneSetting::DEFAULT_MAX_ONLINE
      end

      # d {"get_max_online: zone=#{zone} max_online=#{max_online}"}
      return max_online
    end

    # Return how many players can be dequeued
    #
    def self.dequeue_num zone
      # check max_online infinity setting
      max_online = get_max_online(zone)

      if max_online <= 0
        # several player in a batch
        return MAX_DEQUEUE_BATCH
      end

      # check current online num < max_online
      cur_online = SessionManager.num_online(zone)
      num = max_online - cur_online
      if num > MAX_DEQUEUE_BATCH then
        return MAX_DEQUEUE_BATCH
      elsif num > 0 then
        return num
      else
        return 0
      end
    end

    # Put the player to the end of the queue
    #
    def self.enqueue player_id, zone
      redis = self.redis
      key = self.key(zone)
      return redis.zadd(key, Time.now.to_i, player_id)
    end

    ENQUEUE_JUMP = %Q{
      local key = KEYS[1]
      local player_id, forward, ts = ARGV[1], ARGV[2], ARGV[3]

      local total = redis.call('zcard', key)
      local pos = total - forward
      if pos < 0 then pos = 0 end

      local range = redis.call('zrange', key, pos, pos, 'withscores')
      if #range >= 2 then
        redis.call('zadd', key, range[2] - 0.1, player_id)
      else
        redis.call('zadd', key, ts, player_id)
      end
      return 1
    }
    # Enqueue and jump forward, for vip users
    #
    def self.enqueue_jump player_id, zone, forward
      raise "QueuingDb: enqueue_jump with forward=#{forward}" if forward <= 0

      res = self.redis.evalsmart(ENQUEUE_JUMP,
        :keys => [ self.key(zone) ],
        :argv => [ player_id, forward, Time.now.to_i ])

      if not res
        raise "QueuingDb: enqueue_jump invalid range"
      end

      return !!res
    end

    DEQUEUE = %Q{
      local key, entry_key = KEYS[1], KEYS[2]
      local count, expire = ARGV[1], ARGV[2]

      local player_ids = redis.call('zrange', key, 0, count - 1)
      if not player_ids or #player_ids == 0 then return {} end

      for i = 1, #player_ids do
        local id = player_ids[i]
        redis.call('set', entry_key .. id, '1', 'ex', expire)
      end

      redis.call('zrem', key, unpack(player_ids))
      return player_ids
    }
    # Dequeue players
    # Set a temporary entrance key for the player, allow him to login
    # without queuing within a short period.
    #
    # @param [int] count of players to dequeue
    def self.dequeue count, zone
      raise "QueuingDb: dequeue with count=#{count}!" if count < 1

      player_ids = self.redis.evalsmart(DEQUEUE,
        :keys => [ self.key(zone), self.entry_key('', zone) ],
        :argv => [ count, LOGIN_GRACE_TIME ])
      player_ids.map { |id| id.to_i }
    end

    # Renew entry key
    # When entry key is renewed, the player can login without queuing
    # within a short period
    def self.renew player_id, zone, expire = RENEW_GRACE_TIME
      info "QueuingDb: renew #{player_id}:#{zone} expire=#{expire}"
      redis = self.redis
      redis.set(self.entry_key(player_id, zone), '1', :ex => expire)
    end

    # Rank of the player in the queue
    #
    def self.rank player_id, zone
      redis = self.redis
      key = self.key(zone)
      redis.zrank(key, player_id)
    end

    # Player count in the queue
    #
    def self.queue_len zone
      self.redis.zcard(self.key(zone))
    end

    # Remove the player from queue
    #
    def self.remove player_id, zone
      redis = self.redis
      key = self.key(zone)
      redis.zrem(key, player_id)
    end

    # Clear all database of queuing db
    #
    def self.clear_all zone
      self.redis.del(self.key(zone))
    end

    #####   exposed keys start  #####

    def self.key zone
      redis_key_by_tag("queue:#{zone}")
    end

    def self.entry_key player_id, zone
      redis_key_by_tag("queue:#{zone}", "ent:#{player_id}")
    end

    #####   exposed keys end   #####

  private

    def self.redis
      return @@redis if defined? @@redis and @@redis
      return get_redis :user
    end

    def self.redis= redis
      @@redis = redis
    end

  end

end
