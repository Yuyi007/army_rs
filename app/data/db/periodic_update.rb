# periodic_update.rb

class PeriodicUpdate

  include Loggable
  include Statsable
  include RedisHelper

  CHECK_UPDATE_LOCK = %{
    local lock = redis.call('setnx', KEYS[1], '1')
    if lock == 1 then
      redis.call('expire', KEYS[1], 360)
      return true
    end
    return false
  }

  @@last_keepalive_channel_time = 0

  def self.tick(_step, zones)
    # note the lock can be obtained by child process after fork
    # but not released correctly due to event loop re-establish in the child process
    server_id = AppConfig.server_id
    lock_key = update_lock_key(server_id)
    lock = redis.evalsmart(CHECK_UPDATE_LOCK, keys: [lock_key])


    # d { "PeriodicUpdate.tick zones=#{zones}" }
    # redis.del(lock_key)

    if lock
      begin
        #info "checker #{server_id} alive and locked"
        # info "onlines=#{SessionManager.all_online_ids(1)}"
        with_time_redis_stats "checker" do
          update_all(zones)
        end
      rescue => e
        error('PeriodicUpdate tick Error', e)
      ensure
        redis.expire(lock_key, 1)
      end
    end
  end

  def self.update_all(zones)
    update_channels
    
    ScheduleChatDB.update zones
    MatchManager.update()
  end

  def self.update_channels
    now = Time.now.to_i

    if now - @@last_keepalive_channel_time >= Channel::KEEPALIVE_TIME
      @@last_keepalive_channel_time = now
      Channel.publish_keepalives
    end
  end

  private

  def self.redis
    get_redis :user
  end

  def self.update_lock_key server_id
    "periodic:checker_lock:#{server_id}"
  end
end
