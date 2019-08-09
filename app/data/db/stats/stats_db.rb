class StatsDB
  include RedisHelper
  include Loggable
  include Cacheable

  @@last_record_time = nil

  INC_NEW_USER = %Q{
    local countKey = unpack(KEYS)
    local date, hour = unpack(ARGV)
    local rc = redis.call('lpop', countKey)
    
    local spawn = not rc
    
    if rc then
      rc = cjson.decode(rc)
      if rc.date ~= date then
        spawn = true
        redis.call('lpush', countKey, cjson.encode(rc))
      end
    end

    if spawn then
      rc = {date = date, counts = {}}
    end

    local counts = rc["counts"]
    local k = "h"..hour
    counts[k] = counts[k] or 0
    counts[k] = counts[k] + 1

    redis.call('lpush', countKey, cjson.encode(rc))
    redis.call('ltrim', countKey, 0, 6)
  }
  def self.inc_new_user(zone)
    kcount = new_count_key(zone)
    now = Time.now
    date = now.to_date.to_time.to_i
    hour = now.hour
    redis.evalsmart( INC_NEW_USER, keys: [kcount], argv: [date, hour])
  end

  def self.get_new_user_report(zone)
    kcount = new_count_key(zone)
    return redis.lrange(kcount, 0, -1)
  end

  INC_ACTIVE = %Q{
    local countKey, usersKey = unpack(KEYS)
    local uid, date, hour = unpack(ARGV)

    local rc = redis.call('lpop', countKey)
    
    local spawn = not rc
    
    if rc then
      rc = cjson.decode(rc)
      if rc.date ~= date then
        spawn = true
        redis.call('lpush', countKey, cjson.encode(rc))
      end
    end

    if spawn then
      rc = {date = date, counts = {}}
    end

    local counts = rc["counts"]
    local k = "h"..hour
    if counts[k] then
      local had = redis.call('hget', usersKey, uid)
      if not had then
        counts[k] = counts[k] + 1
      end
    else
      redis.call('del', usersKey)
      counts[k] = 1 
    end
    
    redis.call('lpush', countKey, cjson.encode(rc))
    redis.call('ltrim', countKey, 0, 6)

    redis.call('hset', usersKey, uid, 1)
  }
  def self.inc_active(zone, uid)
    info ">>>>>stats db increace active count zone:#{zone} uid:#{uid}"
    kcount = active_count_key(zone)
    kusers = actives_users_key(zone)
    uid = uid.to_s
    now = Time.now
    date = now.to_date.to_time.to_i
    hour = now.hour
    redis.evalsmart( INC_ACTIVE, keys: [kcount, kusers], argv: [uid, date, hour])

    on_online_change(zone)
  end

  def self.get_active_report(zone)
    kcount = active_count_key(zone)
    return redis.lrange(kcount, 0, -1)
  end

  RECORD_MAX_ONLINE = %Q{
    local onlineKey = unpack(KEYS)
    local date, onlineCount, timestamp = unpack(ARGV)
    date = tonumber(date)
    onlineCount = tonumber(onlineCount)
    timestamp = tonumber(timestamp)

    local obj = redis.call('lpop', onlineKey)
    local spawn = not obj
    if obj then
      obj = cjson.decode(obj)
      if obj.date ~= date then
        spawn = true
        redis.call('lpush', onlineKey, cjson.encode(obj))
      end
    end

    if spawn then
      obj = {date = date, maxCount = onlineCount, time = timestamp}
    end

    if tonumber(obj.maxCount) < onlineCount then
      obj.maxCount = onlineCount
      obj.time = timestamp
    end

    redis.call('lpush', onlineKey, cjson.encode(obj))
    redis.call('ltrim', onlineKey, 0, 6)
  }
  def self.on_online_change(zone)
    count = SessionManager.num_online(zone)
    info ">>>on_online_change zone:#{zone} online:#{count}"
    konline = max_online_key(zone)
    now = Time.now
    date = now.to_date.to_time.to_i
    timestamp = now.to_i
    redis.evalsmart( RECORD_MAX_ONLINE, keys: [konline], argv: [date, count, timestamp])
  end

  def self.get_max_online_report(zone)
    konline = max_online_key(zone)
    return redis.lrange(konline, 0, -1)
  end

  RECORD_ONLINE_INTERVAL = %Q{
    local onlineKey = unpack(KEYS)
    local date, hour, onlineCount = unpack(ARGV)

    local obj = redis.call('lpop', onlineKey)
    local spawn = not obj
    if obj then
      obj = cjson.decode(obj)
      if obj.date ~= date then
        spawn = true
        redis.call('lpush', onlineKey, cjson.encode(obj))
      end
    end

    if spawn then
      obj = {date = date, hours = {}}
    end

    local k = 'h'..hour
    obj.hours[k] = obj.hours[k] or {}
    table.insert(obj.hours[k], onlineCount)
    redis.call('lpush', onlineKey, cjson.encode(obj))
    redis.call('ltrim', onlineKey, 0, 6)
  }
  def self.record_online_interval(zone)
    count = SessionManager.num_online(zone)
    konline = ave_online_key(zone)
    now = Time.now
    date = now.to_date.to_time.to_i
    hour = now.hour
    redis.evalsmart( RECORD_ONLINE_INTERVAL, keys: [konline], argv: [date, hour, count])
    @@last_record_time = Time.now.to_i
  end

  def self.get_ave_online_report(zone)
    konline = ave_online_key(zone)
    return redis.lrange(konline, 0, -1)
  end

  def self.update(zones)
    now = Time.now.to_i
    if @@last_record_time.nil? || (now - @@last_record_time) >= 300
      zones.each do |zone|
        record_online_interval(zone)
      end
    end
  end

  private

  def self.stats
     @stats ||= Nest.new(redis_key_by_tag('stats'), redis)
  end

  def self.actives_users_key(zone)
    stats[zone]['activeusers']
  end

  def self.new_count_key(zone)
    stats[zone]['newcount']
  end

  def self.active_count_key(zone)
    stats[zone]['activecount']
  end

  def self.max_online_key(zone)
    stats[zone]['maxonline']
  end

  def self.ave_online_key(zone)
    stats[zone]['aveonline']
  end

  def self.redis
    get_redis(:action)
  end
end