# redis_lock.rb
# Redis lock helper

module Boot

  #
  # Class for lock a specified key
  #
  # Distributed locks can be complicated, this implementation
  # can not ensure that only one can hold the lock at any given time,
  # two main reasons:
  #
  # 1. The pauses in execution of codes can lead to invalid locks.
  #    e.g. A obtains the lock, the lock expires, B obtains the lock, A was paused
  #    (GC, scheduled out, async delays whatever) before checking the lock validity,
  #    and A thinks it still hold the lock.
  # 2. The disruption of machine time can break the lock validity.
  #
  # For counter-measures, these two are recommended:
  #
  # 1. Check again with the lock validity the moment before you do update to the
  #    shared resource. This can reduce the chance of data corruption.
  # 2. Maintain a version for the shared resource, let the DB checks the version
  #    before update (atomically), only do real update when the version is monotonically
  #    increasing. Note the version can still be outdated if it's retrieved when
  #    the lock is invalid (e.g. timed out).
  #
  # It is recommended that this lock implementation be used in low-frequency
  # competitions, as the timing precision is in milliseconds level.
  #
  # If the shared resource consistency is a concern, use a version-based check
  # before any updates to the shared resource.
  #
  # References:
  # 1. http://martin.kleppmann.com/2016/02/08/how-to-do-distributed-locking.html
  # 2. http://antirez.com/news/101
  #
  class RedisLock

    DEFAULT_LOCK_TIMEOUT = 10.0 unless const_defined? :DEFAULT_LOCK_TIMEOUT

    DEFAULT_SANE_EXPIRY = 15 unless const_defined? :DEFAULT_SANE_EXPIRY

    DEFAULT_EXPIRY_GRACE = 0.3 unless const_defined? :DEFAULT_EXPIRY_GRACE

    include Loggable

    attr_accessor :redis, :key, :lock_acquire_time

    # options
    attr_accessor :max_retry, :retry_wait_time, :lock_timeout, :sane_expiry, :expiry_grace

    def initialize redis, key_to_lock, opts = {}
      self.redis = redis
      self.key = lock_key(key_to_lock)
      self.lock_acquire_time = nil

      opts = opts || {}
      self.max_retry = opts[:max_retry] || 5
      self.retry_wait_time = opts[:retry_wait_time] || 1.0
      self.lock_timeout = opts[:lock_timeout] || DEFAULT_LOCK_TIMEOUT
      self.sane_expiry = opts[:sane_expiry] || DEFAULT_SANE_EXPIRY
      self.expiry_grace = opts[:expiry_grace] || DEFAULT_EXPIRY_GRACE
    end

    def lock
      return false unless redis

      lock = self.trylock
      try = 1

      while not lock
        try = try + 1
        raise "trylock limit exceeded: #{key} #{try}" if try > max_retry
        Boot::Helper.sleep retry_wait_time
        lock = self.trylock
      end

      # info "== lock acquired #{key}"

      if block_given?
        begin
          yield key, self
        ensure
          self.unlock
        end
      end

      return true
    end

    def trylock
      return nil unless redis

      # info "== trylock #{key}"

      now = Time.now.to_f.round(3)
      lock = nil
      set = redis.setnx(key, now + lock_timeout)
      if set
        lock = true
      else
        value = redis.get(key)
        if value
          old_expiry = value.to_f
          if now <= old_expiry + expiry_grace
            lock = false
            now = Time.now.to_f
            if old_expiry - now > sane_expiry
              raise "lock in the future, probably bad system time: #{key}, #{old_expiry - now}"
            end
          else
            now = Time.now.to_f.round(3)
            warn("deadlock detected: #{key}, #{now - old_expiry}")
            value = redis.getset(key, now + lock_timeout)
            if value then
              old_expiry = value.to_f
              if now <= old_expiry
                d{ "competitor trylock first: #{key}, #{now - old_expiry}" }
                lock = false
              else
                info "acquired while deadlock: #{key}, #{now - old_expiry}"
                lock = true
              end
            end
          end
        end
      end

      if lock
        self.lock_acquire_time = now
        if block_given?
          begin
            # info "== trylock acquired #{key}"
            yield key, self
          ensure
            self.unlock
          end
        end
      end

      return lock
    end

    def renew
      return false unless redis

      return false if (not acquired?)

      return false if (timeout?)

      now = Time.now.to_f.round(3)
      value = redis.getset(key, now + lock_timeout)

      if value then
        old_expiry = value.to_f

        if (lock_acquire_time + lock_timeout - old_expiry).abs >= 0.01
          warn("invalid old expiry time when renew #{key}! probably because of previous redis timeouts or lock_timeout changed. acquire=#{lock_acquire_time} timeout=#{lock_timeout} old_expiry=#{old_expiry}")
        end

        self.lock_acquire_time = now
        return true
      else
        raise "error when renew #{key}: no old expiry found!"
      end
    end

    def unlock
      return nil unless redis

      return nil if (not acquired?)

      return nil if (timeout?)

      # info "== unlock #{key}"

      clear
    end

    # force clear the lock, use with caution
    def clear
      self.lock_acquire_time = nil

      redis.del(key)
    end

    def acquired?
      (lock_acquire_time != nil)
    end

    def time_locked
      (Time.now - lock_acquire_time).to_f
    end

    def timeout?
      if lock_acquire_time
        (time_locked > lock_timeout)
      else
        false
      end
    end

    def about_to_timeout?
      if lock_acquire_time
        ((lock_timeout - time_locked) / (lock_timeout + 0.0) < 0.1)
      else
        false
      end
    end

  private

    def lock_key(key)
      "lo:#{key}"
    end

  end

end