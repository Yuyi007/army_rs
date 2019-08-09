
require 'redis'
require 'redis/connection/synchrony'
require 'em-hiredis'
require 'em-synchrony'

module Boot

  class RedisFactory

    DEFAULT_SYSTEM_REDIS_DB = 15

    include Loggable

    @@redises ||= {}

    # Init the redis subsystem
    def self.init options = nil
      # init options
      @@within_event_loop ||= options[:within_event_loop] || false
      @@timeout ||= options[:timeout] || 2.5
      @@pool_size ||= options[:pool_size] || 3
      @@default_db = AppConfig.default_db.to_i || 0

      @@redises = {}
      @@distributed = Redis::Distributed.new []

      if @@default_db != 0 then
        info "default db is #{@@default_db}"
      end

      if AppConfig.redis
        AppConfig.redis.each do |cfg|
          name = redis_name cfg
          @@redises[name] ||= self.make_redis(
            :id => name,
            :host => cfg['host'],
            :port => cfg['port'],
            :timeout => cfg['timeout'] || @@timeout,
            :pool_size => cfg['pool_size'] || @@pool_size,
            :db => cfg['db'] || @@default_db)
          @@distributed.add_redis @@redises[name], {}
        end

        # Checking if a migration is needed
        if RedisMigrateDb.new(self.make_system_redis).should_migrate?
          raise "redis_factory: data migration is needed"
        end
      end
    end

    def self.init_failsafe
      @@within_event_loop = false
      @@pool_size = 1

      @@redises = {}
      @@distributed = Redis::Distributed.new []

      if AppConfig.redis
        AppConfig.redis.each do |cfg|
          name = redis_name cfg
          @@redises[name] ||= self.make_redis(
            :id => name,
            :host => cfg['host'],
            :port => cfg['port'],
            :timeout => cfg['timeout'] || @@timeout,
            :pool_size => cfg['pool_size'] || @@pool_size,
            :db => cfg['db'] || @@default_db)
          @@distributed.add_redis @@redises[name]
        end
      end
    end

    def self.fini
      @@redises.each do |_, r|
        r.close_connections if r.respond_to?(:close_connections)
        r.close_connection if r.respond_to?(:close_connection)
        r.pubsub.close_connection if r.respond_to?(:pubsub)
        r.quit if r.respond_to?(:quit)
      end

      @@redises = {}
      @@distributed = Redis::Distributed.new []
    end

    # Distributed redis as the main redis we should be using
    # @return [Redis] the distributed redis
    def self.distributed
      @@distributed
    end

    def self.total_ops_count
      count = @@redises.values.inject(0) { |sum, r| sum + r.ops_count }
      count
    end

    def self.make_channel_redises
      res = {}

      if AppConfig.pubsub_redis
        configs = AppConfig.pubsub_redis
      else
        configs = AppConfig.redis
      end

      configs.each do |cfg|
        name = redis_name(cfg)
        res[name] ||= self.make_hiredis(
          :id => name,
          :host => cfg['host'],
          :port => cfg['port'],
          :timeout => cfg['timeout'] || @@timeout)
      end

      res
    end

    def self.make_system_redis
      return nil unless AppConfig.redis

      system_cfg = AppConfig.system_redis || AppConfig.redis[0]
      name = redis_name system_cfg
      db = system_cfg['db'] || DEFAULT_SYSTEM_REDIS_DB

      info "using system redis #{system_cfg}"

      if @@default_db == db then
        raise "default db shouldn't be the same with system_redis db"
      end

      self.make_redis(
        :id => name,
        :host => system_cfg['host'],
        :port => system_cfg['port'],
        :timeout => 30,
        :pool_size => 1,
        :db => db
      )
    end

  private

    def self.redis_name(cfg)
      "#{cfg['name']}#{cfg['host']}:#{cfg['port']}"
    end

    def self.make_redis(options)
      if defined?(@@within_event_loop) and @@within_event_loop
        RedisConnPool.new(size: options[:pool_size]) do
          info "[factory] redis new options:#{options} "
          Redis.new(:id => options[:id], :host => options[:host], :port => options[:port], :db => options[:db],
            :timeout => options[:timeout], :tcp_keepalive => 0, :driver => :synchrony)
        end
      else
        Redis.new(:id => options[:id], :host => options[:host], :port => options[:port], :db => options[:db],
          :timeout => options[:timeout], :tcp_keepalive => 0, :driver => :hiredis)
      end
    end

    def self.make_hiredis(options)
      if defined?(@@within_event_loop) and @@within_event_loop
        redis = EM::Hiredis.connect("redis://#{options[:host]}:#{options[:port].to_i}")
        redis.on(:reconnect_failed) do |fail_count|
          info "reconnect_failed #{fail_count}"
        end
        redis.pubsub.on(:reconnect_failed) do |fail_count|
          info "pubsub reconnect_failed #{fail_count}"
        end
        redis
      else
        # NOTE: this instance doens't work with Channel.rb
        Redis.new(:host => options[:host], :port => options[:port], :driver => :hiredis)
      end
    end

  end

end