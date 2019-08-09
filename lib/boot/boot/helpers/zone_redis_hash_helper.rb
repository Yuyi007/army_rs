module ZoneRedisHashHelper
  def self.included(base)
    base.class_eval do
      include(RedisHelper)
    end

    base.extend(ClassMethods)
  end

  def redis_hash
    self.class.redis_hash(zone)
  end

  def redis
    self.class.redis(zone)
  end

  def redis_index
    self.class.redis_index(zone)
  end

  def invalidate_cache
  end

  def reload!
    o = redis_hash.hget(id)
    if o
      from_hash!(o.to_hash)
    else
      self
    end
  end

  def save(*args)
    if block_given?
      redis_hash.hset_with_lock(id) do |o|
        yield(*args, o)
        from_hash!(o.to_hash)
      end
    else
      redis_hash.hset(id, self)
    end

    invalidate_cache
  end

  module ClassMethods
    def redis_hash(zone)
      RedisHash.new(redis(zone), key[zone], self)
    end

    def redis_index(zone)
      RedisIndex.new(redis(zone), key[zone])
    end

    def key
      @key ||= Nido.new(self.name)
    end

    def get_zone_by_id(id)
      0
    end

    def read_by_id(id)
      zone = get_zone_by_id(id)
      redis_hash(zone).hget(id) if zone
    end

    def fetch(zone, ids)
      return [] if ids.empty?
      redis_hash(zone).hmget(ids)
    end

    def redis(zone)
      get_redis(zone)
    end

  end
end