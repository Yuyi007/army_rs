
module Boot

  class GameData

    include Loggable
    include Statsable
    include RedisHelper

  CREATE_BLOB = %Q{
    local key = KEYS[1]
    if redis.call('exists', key) == 0 then
      redis.call('hmset', key, unpack(ARGV))
      return true
    else
      return false
    end
  }
    def self.create(id, zone, model)
      redis = redis(zone)
      return nil unless redis

      raise "invalid id zone #{id} #{zone}" unless
        validate_id_zone(id, zone)

      m = new_game_data_model(id, zone).init_hash_storable! model.to_hash do |field_name, cur_value|
        cur_value
      end
      res = redis.evalsmart(CREATE_BLOB, :keys => [ blob_key(id, zone) ], :argv => m.breakdown_dump)
      (res ? m : nil)
    end

  UPDATE_BLOB = %Q{
    local key = KEYS[1]
    local version = table.remove(ARGV)
    local t = redis.call('type', key)['ok']
    if t == 'hash' then
      local old_version = tonumber(redis.call('hget', key, 'version')) or 0
      if tonumber(version) > old_version then
        redis.call('hmset', key, unpack(ARGV))
        return true
      else
        return false
      end
    else
      return false
    end
  }
    def self.update(id, zone, model)
      redis = redis(zone)
      return nil unless redis

      # info "== write #{id} #{zone}"

      raise "invalid id zone #{id} #{zone}" unless
        validate_id_zone(id, zone)

      # validate model
      if not model.validate_model(id, zone)
        return nil
      end

      # before update game data, do a fail-safe check for locks
      # NOTE that we don't support nested GameData.lock
      redis_lock = Fiber.current[:game_data_lock]
      if redis_lock and redis_lock.timeout?
        stats_increment_local 'lock.timeout'
        raise "update after lock timeout: #{id} #{zone} #{redis_lock.time_locked}"
      end

      # call before_update callback
      model.before_update if model.respond_to? :before_update

      key = blob_key(id, zone)

      if model.is_a? HashStorable
        model.version = model.version + 1
        breakdowns = model.breakdown_dump
        breakdowns.each_slice(2) do |a|
          stats_gauge_global("model.#{a[0]}.size", a[1].length) if a[1].respond_to? :length
        end
        # NOTE that argv will be expanded to a flat array
        res = redis.evalsmart(UPDATE_BLOB, :keys => [ key ],
          :argv => [ breakdowns, model.version ])
        raise "UPDATE_BLOB failed: #{id} #{zone}" if not res
        res
      else
        raise "model type is #{model.class.name}, HashStorable needed"
      end
    end

    def self.new_game_data_model id, zone
      $boot_config.dispatch_delegate.create_model
    end

  READ_FIELD = %Q{
    local key = KEYS[1]
    local field = ARGV[1]
    local t = redis.call('type', key)['ok']
    if t == 'hash' then
      return redis.call('hget', key, field)
    else
      return nil
    end
  }
  READ_BLOB = %Q{
    local key = KEYS[1]
    local fields = ARGV
    local t = redis.call('type', key)['ok']
    if t == 'hash' then
      return redis.call('hmget', key, unpack(fields))
    elseif t == 'string' then
      return redis.call('get', key)
    else
      return nil
    end
  }
    def self._read(id, zone, options)
      transfer = options[:transfer]
      redis = redis(zone)
      return nil unless redis

      # info "== read #{id} #{zone}"

      raise "invalid id zone #{id} #{zone}" unless
        validate_id_zone(id, zone)

      key = blob_key(id, zone)
      fields = HashStorableMeta.preload_fields
      res = redis.evalsmart(READ_BLOB, :keys => [ key ], :argv => fields)

      if res != nil
        if TransferData.restorable?(res)
          if transfer
            TransferData.from_db(id, zone)
            res = redis.evalsmart(READ_BLOB, :keys => [ key ], :argv => fields)
          else
            return nil
          end
        end
        model = new_game_data_model(id, zone)
        model.init_hash_storable! res do |field_name, _|
          redis.evalsmart(READ_FIELD, :keys => [ key ], :argv => [ field_name ])
        end
        return model
      else
        nil
      end
    end

    def self.read(id, zone)
      self._read(id, zone, :transfer => true)
    end

    # don't query mysql
    def self.read_hot(id, zone)
      self._read(id, zone, :transfer => false)
    end

    # read multiple players
    # def self.readMulti(ids, zone)
    #   return [] if ids.nil? or zone.nil?
    #   ids = ids.compact
    #   return [] if ids.empty?

    #   redis = redis(zone)
    #   return [] unless redis

    #   datas = []
    #   blob_keys = ids.map {|id| blob_key(id, zone)}
    #   raws = redis.mget(blob_keys)
    #   raws.each do |raw|
    #     datas << Model.new.load!(raw) if raw
    #   end
    #   return datas
    # end

    def self.delete(id, zone)
      redis = redis(zone)
      return nil unless redis

      redis.del(blob_key(id, zone))
      # redis.del(version_key(id, zone))
    end

    def self.lock(id, zone, opts = {})
      RedisLock.new(redis(zone), blob_key(id, zone), opts).lock do |_, redis_lock|
        Fiber.current[:game_data_lock] = redis_lock
        yield id, zone if block_given?
      end
    end

    def self.read_lock(id, zone, opts = {}, &blk)
      self.lock(id, zone) do |lock_id, lock_zone|
        md = read(lock_id, lock_zone)
        yield(md)
        update(lock_id, lock_zone, md)
      end
    end

    def self.trylock(id, zone, opts = {})
      RedisLock.new(redis(zone), blob_key(id, zone), opts).trylock do |_, redis_lock|
        Fiber.current[:game_data_lock] = redis_lock
        yield id, zone if block_given?
      end
    end

    def self.blob_key(id, zone)
      "p:#{id}:#{zone}"
    end

    # for unit test
    def self.redis= redis
      @@redis = redis
    end

    def self.validate_id_zone(id, zone)
      (id != nil and id != '$noauth$' and id > 0 and
        zone != nil and zone > 0)
    end

  private

    def self.redis(zone)
      return @@redis if defined? @@redis and @@redis
      return get_redis zone
    end

    def self.version_key(id, zone)
      "ver:#{id}:#{zone}"
    end

  end

end