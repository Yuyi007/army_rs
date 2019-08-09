
# CachedGameData: cache game data in memory for long term use
#
# NOTE: The game data should be periodically put back to db
# everytime before the lock timeout
#
module Boot::CachedGameData

# High Level API

  # take the game data model for cached use
  # if we do not have the cache, try to build the cache
  # if we already have the cache, use it directly
  #
  # @param id the player id
  # @param zone the player zone
  # @param blk block that take 3 params: id, zone, model
  def self.take(id, zone, &blk)
    instance.take(id, zone, false, &blk)
  end

  # put back the game data model, delete cache
  # once the cache is deleted and lock released, others can take this model
  #
  # @param id the player id
  # @param zone the player zone
  def self.put_back(id, zone)
    instance.put_back(id, zone, false)
  end

  # put back all game data caches
  def self.put_back_all
    instance.put_back_all(false)
  end

  # start work loop to put back cached items periodically
  def self.work_loop &blk
    instance.work_loop(&blk)
  end

  # work loop shut down?
  def self.shutdown?
    instance.shutdown?
  end

  # shut down work loop
  def self.shutdown!
    instance.shutdown = true
  end

  # ask the cache owner of the game data model to run the job class on the model
  # this is used when want to operate on game data other is taking its cache
  #
  # @param id the player id
  # @param zone the player zone
  # @param job_klass the job class for processing the player model
  def self.ask(id, zone, job_klass, *job_args)
    instance.ask(id, zone, job_klass, false, *job_args)
  end

  # take if I can, or ask
  #
  # @param id the player id
  # @param zone the player zone
  # @param job_klass the job class for processing the player model
  def self.take_or_ask(id, zone, job_klass, *job_args)
    instance.take_or_ask(id, zone, job_klass, false, *job_args)
  end

  # use with care
  def self.take_or_ask_no_lock(id, zone, job_klass, *job_args)
    instance.take_or_ask(id, zone, job_klass, true, *job_args)
  end

# Low level API

  # ensure the game data model is cached on me
  # use a RedisLock to ensure only one can cache it
  def self.ensure_cached(id, zone, &blk)
    instance.ensure_cached(id, zone, false, &blk)
  end

  # ensure cache, run the block, and finally delete the cache
  def self.ensure_cache_deleted(id, zone, &blk)
    instance.ensure_cache_deleted(id, zone, false, &blk)
  end

  # delete my cache
  # Do not use this unless you know exactly what you're doing
  def self.delete_cache(id, zone, no_lock = false)
    instance.delete_cache(id, zone, no_lock)
  end

  # force delete cache (could be hold by anyone currently)
  # Danger! use with extrem care
  def self.force_delete_cache(id, zone, no_lock = false)
    instance.force_delete_cache(id, zone, no_lock)
  end

  # has cache for the player?
  #
  # @param id the player id
  # @param zone the player zone
  def self.has_cache?(id, zone)
    instance.has_cache?(id, zone)
  end

  # cache size
  #
  # @return cache size of the instance
  def self.cache_size()
    instance.cache_size()
  end

  # cache keys
  #
  # @return cached keys of the instance
  def self.cache_keys()
    instance.cache_keys()
  end

  # get the singleton instance
  def self.instance
    @instance ||= CachedGameDataComp.new()
  end

  # An intermediate job to read the model and run the job class
  class AskCachedGameDataJob

    include Boot::Loggable

    def self.perform from_server_id, job_klass, no_lock, id, zone, *job_args
      CachedGameData.instance.ensure_cached(id, zone, no_lock) do |cache_id, cache_zone, model|
        info "AskCachedGameDataJob: from=#{from_server_id} class=#{job_klass} id=#{id} zone=#{zone} ver=#{model.version}"
        job_klass = job_klass.constantize
        job_klass.perform(cache_id, cache_zone, model, *job_args)
      end
    end

  end

  # A cache item for game data model
  class GameDataCacheItem

    attr_accessor :lock, :model

    def initialize lock, model
      @lock = lock
      @model = model
    end

  end

  # Instanitiatable CachedGameData
  class CachedGameDataComp

    include Boot::Loggable
    include Boot::Statsable
    include Boot::RedisHelper

    DEFAULT_LOCK_OPTIONS = {:max_retry => 1, :retry_wait_time => 1.0,
        :lock_timeout => 120.0, :sane_expiry => 120.0,
        :expiry_grace => 0} unless defined? DEFAULT_LOCK_OPTIONS

    DEFAULT_PUT_BACK_ALL_INTERVAL = 600.0 unless
      defined? DEFAULT_PUT_BACK_ALL_INTERVAL

    DEFAULT_MUTEX_TRY_LIMIT = 100

    attr_reader :cached_data, :mutex
    attr_writer :redis
    attr_accessor :lock_options, :my_id, :put_back_all_interval, :mutex_try_limit, :shutdown

    def initialize opts = {}
      @my_id = opts[:my_id] || AppConfig.server_id
      @redis = opts[:redis] || nil
      @lock_options = opts[:lock_options] || DEFAULT_LOCK_OPTIONS
      @put_back_all_interval = opts[:put_back_all_interval] || DEFAULT_PUT_BACK_ALL_INTERVAL
      @mutex_try_limit = opts[:mutex_try_limit] || DEFAULT_MUTEX_TRY_LIMIT
      @shutdown = false

      @cached_data = {}
      @mutex = {}
    end

    def take(id, zone, no_lock, &blk)
      raise "invalid id zone #{id} #{zone}" unless
        GameData.validate_id_zone(id, zone)

      ensure_cached(id, zone, no_lock, &blk)
    end

    def put_back(id, zone, no_lock)
      raise "invalid id zone #{id} #{zone}" unless
        GameData.validate_id_zone(id, zone)

      ensure_cache_deleted(id, zone, no_lock) do |cache_id, cache_zone, model|
        put_to_db(cache_id, cache_zone, model)
      end
    end

    def put_back_all no_lock, &blk
      start_time = Time.now
      success_count = 0
      total_count = 0
      success = false

      @cached_data.keys.each do |key|
        begin
          id, zone = breakdown_key(key)
          success = false
          success = put_back(id, zone, no_lock)
          if success
            success_count += 1
          else
            if not renew(id, zone, no_lock)
              error("put_back_all: renew also failed #{id} #{zone}")
            end
          end
          Boot::Helper.sleep 0.005 # slow down
        rescue => er
          error("put_back_all: id=#{id}:#{zone} Error=", er)
        ensure
          total_count += 1
          yield id, zone, success if block_given?
        end
      end

      time_used = (Time.now - start_time).to_f.round(3)
      info "put_back_all: success #{success_count}/#{total_count}, #{time_used} secs"
      success_count
    end

    def renew_all no_lock, &blk
      start_time = Time.now
      success_count = 0
      total_count = 0
      success = false

      @cached_data.keys.each do |key|
        begin
          id, zone = breakdown_key(key)
          success = renew(id, zone, no_lock)
          if success
            success_count += 1
          else
            d{ "renew_all: failed #{id} #{zone}" }
          end
          Boot::Helper.sleep 0.005 # slow down
        rescue => er
          error("renew_all id=#{id}:#{zone} Error: ", er)
        ensure
          total_count += 1
          yield id, zone, success if block_given?
        end
      end

      time_used = (Time.now - start_time).to_f.round(3)
      info "renew_all: success #{success_count}/#{total_count}, #{time_used} secs"
      success_count
    end

    def shutdown?; @shutdown; end

    def work_loop &blk
      last_put_back_all_time = Time.now
      while not shutdown? do
        begin
          now = Time.now
          if now - last_put_back_all_time > put_back_all_interval
            put_back_all(false, &blk)
            last_put_back_all_time = Time.now
          else
            renew_all(false)
            Boot::Helper.sleep(lock_options[:lock_timeout] / 3.0)
          end
        rescue => er
          error("CachedGameData Worker Error: ", er)
          Boot::Helper.sleep(1.0)
        end
      end
    end

    def ask(id, zone, job_klass, no_lock, *job_args)
      return _ask(id, zone, false, no_lock, job_klass, *job_args)
    end

    def take_or_ask(id, zone, job_klass, no_lock, *job_args)
      return _ask(id, zone, true, no_lock, job_klass, *job_args)
    end

    def _ask(id, zone, allow_cached, no_lock, job_klass, *job_args)
      raise "invalid id zone #{id} #{zone}" unless
        GameData.validate_id_zone(id, zone)

      raise "#{job_klass} must be a CachedGameDataJob" unless
        job_klass.superclass == CachedGameDataJob

      cache_key = cache_key(id, zone)
      redis = redis(zone)
      cacher_id = redis.get(cache_key)

      # This is not an atomic operation though,
      # the actual cacher_id may change after we get the old value,
      # in which case, errors will be thrown.
      if cacher_id == my_id
        if allow_cached
          ensure_cached(id, zone, no_lock) do |cache_id, cache_zone, model|
            job_klass.perform(cache_id, cache_zone, model, *job_args)
          end
        else
          raise "#{cache_key} was cached by myself, should call take() instead?"
        end
      elsif cacher_id == nil
        ensure_cache_deleted(id, zone, no_lock) do |cache_id, cache_zone, model|
          result = job_klass.perform(cache_id, cache_zone, model, *job_args)
          put_to_db(cache_id, cache_zone, model) if job_klass.save?
          result
        end
      else
        RedisRpc.call(AskCachedGameDataJob, cacher_id, my_id, job_klass.to_s, no_lock, id, zone, *job_args)
      end
    end

  # low level API

    def ensure_cached(id, zone, no_lock, &blk)
      with_player_mutex(id, zone, no_lock) do
        cache_key = cache_key(id, zone)
        cached_item = _ensure_cached_item(id, zone)

        if cached_item
          lock = cached_item.lock
          model = cached_item.model

          # unless lock.acquired?
          #   _delete_cache(id, zone)
          #   raise "#{cache_key} lock was not acquired!"
          # end

          # if lock.about_to_timeout?
          #   info "#{cache_key} about to timeout, renewing"
          #   _renew(id, zone)
          # end

          # it's allowed to delete cache in the block
          block_res = yield id, zone, model

          if lock.acquired? and lock.timeout?
            # when timeout happens it's often not desirable to simply delete the cache
            # even if it's dirty data the player probably want to have it saved properly
            put_to_db(id, zone, model)
            _delete_cache(id, zone)
            raise "#{cache_key} lock has expired!"
          end

          block_res
        else
          raise "#{cache_key} cached_item is #{cached_item}"
        end
      end
    end

    def _ensure_cached_item(id, zone)
      cache_key = cache_key(id, zone)
      cache_item = @cached_data[cache_key]
      redis = redis(zone)

      if cache_item
        lock = cache_item.lock
        lock.redis = redis
        if lock and lock.acquired? and (not lock.timeout?)
          # I have the lock currently
          return cache_item
        else
          # I had the lock once, but now it's gone
          info "_ensure_cached_item: delete #{cache_key}"
          @cached_data.delete(cache_key)
          # @mutex.delete(cache_key)
          raise "#{cache_key} data is invalid now!"
        end
      else
        # I do not have the lock, try to obtain it
        lock = RedisLock.new(redis, cache_key, @lock_options)
        if lock.trylock
          model = read_from_db(id, zone)
          cache_item = GameDataCacheItem.new(lock, model)

          info "_ensure_cached_item: obtain #{cache_key}"
          @cached_data[cache_key] = cache_item

          redis.set(cache_key, my_id)

          return cache_item
        else
          cacher_id = redis.get(cache_key)
          raise "#{cache_key} data already cached by #{cacher_id}!"
        end
      end

      return nil
    end

    def ensure_cache_deleted(id, zone, no_lock, &blk)
      ensure_cached(id, zone, no_lock) do |cache_id, cache_zone, model|
        begin
          yield cache_id, cache_zone, model if block_given?
        rescue => er
          error("ensure_cached Error: ", er)
          nil
        ensure
          _delete_cache(cache_id, cache_zone)
          nil
        end
      end
    end

    def delete_cache(id, zone, no_lock)
      with_player_mutex(id, zone, no_lock) do
        _delete_cache(id, zone)
      end
    end

    def _delete_cache(id, zone)
      cache_key = cache_key(id, zone)
      cache_item = @cached_data[cache_key]
      redis = redis(zone)

      if cache_item
        lock = cache_item.lock
        lock.redis = redis
        if lock and lock.acquired? and (not lock.timeout?)
          # I have the lock currently
          if redis.get(cache_key) == my_id
            redis.del(cache_key)
          end

          lock.unlock
        else
          # I had the lock once, but now it's gone
        end

        info "_delete_cache: #{cache_key}"
        @cached_data.delete(cache_key)
        # @mutex.delete(cache_key)
        true
      else
        # I do not have the lock, nothing to delete
        false
      end
    end

    def force_delete_cache(id, zone, no_lock)
      with_player_mutex(id, zone, no_lock) do
        _force_delete_cache(id, zone)
      end
    end

    def _force_delete_cache(id, zone)
      cache_key = cache_key(id, zone)
      redis = redis(zone)

      redis.del(cache_key)

      lock = RedisLock.new(redis, cache_key, @lock_options)
      lock.clear

      info "_force_delete_cache: #{cache_key}"
      @cached_data.delete(cache_key)
      # @mutex.delete(cache_key)
    end

    def renew(id, zone, no_lock)
      with_player_mutex(id, zone, no_lock) do
        _renew(id, zone)
      end
    end

    def _renew(id, zone)
      cache_key = cache_key(id, zone)
      cache_item = @cached_data[cache_key]
      redis = redis(zone)

      if cache_item
        lock = cache_item.lock
        lock.redis = redis
        if lock and lock.acquired? and (not lock.timeout?)
          lock.renew
        else
          # I had the lock once, but now it's gone
          false
        end
      else
        # I do not have the lock, cannot renew
        false
      end
    end

    def has_cache?(id, zone)
      cache_key = cache_key(id, zone)
      cache_item = @cached_data[cache_key]
      redis = redis(zone)

      if cache_item
        lock = cache_item.lock
        lock.redis = redis
        if lock and lock.acquired? and (not lock.timeout?)
          # I have the lock currently
          (redis.get(cache_key) == my_id)
        else
          # I had the lock once, but now it's gone
          false
        end
      else
        # I do not have the lock, nothing to delete
        false
      end
    end

    def cache_size()
      @cached_data.size()
    end

    def cache_keys()
      @cached_data.keys()
    end

    def read_from_db(id, zone)
      model = GameData.read(id, zone)

      if model == nil
        model = GameData.new_game_data_model(id, zone).init_hash_storable!({}) do |_, cur_value|
          cur_value
        end
        GameData.create(id, zone, model)
      end

      model
    end

    def put_to_db(id, zone, model)
      db_model = GameData.read(id, zone)

      if db_model == nil
        raise "put_to_db: model #{id}:#{zone} was deleted!"
      elsif model.version < db_model.version
        raise "put_to_db: model version #{model.version} is older than db #{db_model.version}!"
      else
        res = GameData.update(id, zone, model)
        if res
          info "put_to_db: success #{id} #{zone} ver=#{model.version}"
        else
          warn "put_to_db: failed! #{id} #{zone} ver=#{model.version}"
        end
        res
      end
    end

  private

    def redis(zone)
      return @redis if defined? @redis and @redis
      return get_redis(zone)
    end

    def cache_key(id, zone); "cache:#{id}:#{zone}"; end

    def breakdown_key(key)
      arr = key.split(':')
      return arr[1].to_i, arr[2].to_i
    end

    ####
    # player_mutex is used for protecting critical region for accessing player data
    # FIXME: garbage collect unused player mutex

    # ensure player mutex obtained before yielding
    def with_player_mutex(id, zone, no_lock, &blk)
      if no_lock then
        yield
      else
        cache_key = cache_key(id, zone)

        @mutex[cache_key] ||= Mutex.new
        this_mutex = @mutex[cache_key]

        Boot::Helper.lock_mutex this_mutex, @mutex_try_limit
        begin
          yield
        ensure
          Boot::Helper.unlock_mutex this_mutex
        end
      end
    end

  end

end

module Boot

  class CachedGameDataJob

    def self.perform player_id, zone, model
      raise "you must implement perform()!"
    end

    # Should the model be saved after execution?
    # (only when the job is run from caller)
    def self.save?
      true
    end

  end

  # A Helper job class to read cached game data
  class ReadCachedGameDataJob < CachedGameDataJob

    include Loggable

    def self.perform id, zone, model
      model.to_hash
    end

    def self.save?
      false
    end

  end

  # A Helper job class to update cached game data
  # NOTE: this job will overwrite online player data
  class UpdateCachedGameDataJob < CachedGameDataJob

    include Loggable

    def self.perform id, zone, model, hash
      model.from_hash! hash
      true
    end

  end

end