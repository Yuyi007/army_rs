# redis_hash.rb
# Redis Hash helpers

module Boot

  #
  # Class that handles redis hash with serialization (through a jsonable class)
  # and locked get-and-set operation
  #
  class RedisHash

    attr_accessor :redis, :key, :jsonable, :options
    include Loggable

    def initialize redis, key, jsonable = nil, options = nil
      self.redis = redis
      self.key = key
      self.jsonable = jsonable
      self.options = options || {}
    end

    def hexists(hkey)
      redis.hexists(key, hkey)
    end

    def hget(hkey)
      raw = redis.hget(key, hkey)
      return nil unless raw

      if jsonable
        obj = jsonable.new
        obj.load!(raw)
        obj
      else
        load_raw(raw)
      end
    end

    def hget_or_new(hkey)
      obj = hget(hkey)
      if obj.nil?
        if jsonable
          jsonable.new()
        else
          nil
        end
      else
        obj
      end
    end

    def hkeys
      redis.hkeys(key)
    end


    def hmget(hkeys)

      if hkeys.empty?
        return []
      end

      raws = redis.hmget(key, hkeys)
      return [] unless raws

      raws.map do |raw|
        if raw == nil
          nil
        elsif jsonable
          obj = jsonable.new
          obj.load!(raw)
          obj
        else
          load_raw(raw)
        end
      end
    end

    def hset(hkey, obj)
      raw = nil

      if obj
        if jsonable
          raw = obj.dump
        else
          raw = dump_raw(obj)
        end
      end

      if raw
        redis.hset(key, hkey, raw)
      end
    end

    def hmset(hkeys, values)
      return if hkeys.size != values.size
      raws = values.map do |obj|
        if jsonable
          obj.dump
        else
          dump_raw(obj)
        end
      end

      redis.hmset(key, hkeys.zip(raws).flatten)
    end

    def hdel(hkey)
      redis.hdel(key, hkey)
    end

HSET = %Q{
  local key = KEYS[1]
  local hkey, val, version = unpack(ARGV)
  local version_key = hkey..'_redis_hash_version'
  local old_version = tonumber(redis.call('hget', key, version_key)) or 0
  if tonumber(version) > old_version then
    return redis.call('hmset', key, hkey, val, version_key, version)
  else
    return false
  end
}
    # hset with lock
    def hset_with_lock(hkey)
      lock(hkey) do |_, lock|
        raw, version = redis.hmget(key, hkey, "#{hkey}_redis_hash_version")
        obj_data = nil

        if jsonable
          obj = jsonable.new
          obj.load!(raw) if raw
          obj = yield obj
          obj_data = obj.dump if obj
        else
          obj = load_raw(raw) if raw
          obj = yield obj
          obj_data = dump_raw(obj) if obj
        end

        if obj_data
          new_version = if version.nil? then 1 else version.to_i + 1 end
          raise "hset_with_lock #{hkey} after lock timeout!" if lock.timeout?
          res = redis.evalsmart(HSET, :keys => [ key ],
            :argv => [ hkey, obj_data, new_version ])
          raise "hset_with_lock #{hkey} version-check failed!" unless res
          res
        end
      end
    end

HMSET = %Q{
  local key = KEYS[1]
  local list = ARGV
  local total_size = #list
  local version_size = total_size / 2

  local hkeys = {}
  local version_keys = {}
  for i = 1, version_size, 2 do
    version_key = list[i]
    version = tonumber(list[i + 1])
    old_version = tonumber(redis.call('hget', key, version_key)) or 0
    if version <= old_version then
      return false
    end
  end

  return redis.call('hmset', key, unpack(list))
}

    def hmset_with_lock(hkeys)
      res = false
      lock("hmset_#{key}") do |_, lock|
        version_keys = hkeys.map {|x| "#{x}_redis_hash_version"}
        list = redis.hmget(key, hkeys + version_keys)
        values = list[0..hkeys.size - 1]
        versions = list[hkeys.size..list.size - 1]
        values.compact!

        if values.size != hkeys.size
          next false
        end

        if jsonable
          obj_values = values.map {|x| jsonable.new.load!(x)}
        else
          obj_values = values.map {|x| load_raw(x)}
        end

        yield(obj_values)

        if obj_values.size != hkeys.size
          next false
        end

        if jsonable
          raw_values = obj_values.map {|x| x.dump}
        else
          raw_values = obj_values.map {|x| dump_raw(x)}
        end

        hkeys.each_with_index do |hkey, index|
          version = versions[index]
          new_version = if version.nil? then 1 else version.to_i + 1 end
          versions[index] = new_version
        end

        array = version_keys.zip(versions).flatten + hkeys.zip(raw_values).flatten

        res = redis.evalsmart(HMSET, :keys => [ key],
          :argv => array)
        d { "hmset_with_lock #{hkeys} version-check failed!" } unless res
        res
      end
      res
    end

HDEL = %Q{
  local key = KEYS[1]
  local hkey, version = unpack(ARGV)
  local version_key = hkey..'_redis_hash_version'
  local old_version = tonumber(redis.call('hget', key, version_key)) or 0
  if tonumber(version) > old_version then
    redis.call('hset', key, version_key, version)
    return redis.call('hdel', key, hkey)
  else
    return false
  end
}
    def hdel_with_lock(hkey)
      lock(hkey) do |_, lock|
        version = redis.hget(key, "#{hkey}_redis_hash_version")
        new_version = if version.nil? then 1 else version.to_i + 1 end
        raise "hdel #{hkey} after lock timeout!" if lock.timeout?
        res = redis.evalsmart(HDEL, :keys => [ key ],
          :argv => [ hkey, new_version ])
        raise "hdel #{hkey} version-check failed!" unless res
        res
      end
    end

    def delete_all
      redis.del(key)
    end

    def hlen
      redis.hlen(key)
    end

    def size
      hlen
    end

    def ids
      redis.hkeys(key)
    end

  private

    def lock hkey
      RedisLock.new(redis, "#{key}:#{hkey}", self.options[:lock]).lock do |key, lock|
        yield(key, lock)
      end
    end

    # default serialization method
    def dump_raw(val)
      MessagePack.pack(val)
    end

    # default deserialization method
    def load_raw(raw)
      MessagePack.unpack(raw)
    end

  end

end