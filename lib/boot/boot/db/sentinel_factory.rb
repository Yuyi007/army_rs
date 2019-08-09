# SentinelFactory.rb

module Boot

  class SentinelFactory

    include Loggable

    def self.init options
      @@within_event_loop = options[:within_event_loop] || false
      @@within_pubsub = options[:within_pubsub] || false
      @@timeout = options[:timeout] || 3.0
      @@pool_size = options[:pool_size] || 1

      if AppConfig.sentinels
        @@redises = {}
        AppConfig.redis.each { |cfg| @@redises[cfg['name']] = nil }

        @@sentinels = {}
        AppConfig.sentinels.each do |sname|
          host, port = * sname.split(':')
          @@sentinels[sname] ||= self.make_sentinel(
            :host => host,
            :port => port,
            :timeout => @@timeout,
            :pool_size => @@pool_size)
          info "sentinel: found sentinel instance #{host}:#{port}"
        end

        @@last_query_time = Time.now
        check_redis_config
      else
        info "sentinel: no sentinels config found, will try to use hard-coded redis addr"
      end
    end

    def self.fini
    end

    def self.query_redis_config_changes
      if AppConfig.sentinels
        if Time.now - @@last_query_time > 5
          @@last_query_time = Time.now
          changed = check_redis_config
          if changed > 0
            info "sentinel: there are #{changed} changes in redis config, reinit redis connections"
            Pubsub.fini if @@within_pubsub
            RedisFactory.fini
            RedisFactory.init(:within_event_loop => true)
            Pubsub.init(:within_event_loop => true) if @@within_pubsub
            info "sentinel: reinit redis connections done"
          else
            info "sentinel: no changes in redis config"
          end
        end
      end
    end

  private

    def self.check_redis_config
      changed = 0

      @@redises.each do |name, value|
        d{ "sentinel: checking redis config #{name}" }

        @@sentinels.each do |sname, sentinel|
          begin
            result = sentinel.sentinel_get_master_name name
            if result and result.is_a?(Array) and result.length == 2
              if value != result
                @@redises[name] = result
                info "sentinel: #{sname}: got redis master new addr #{name} -> #{result}"

                AppConfig.redis.each { |cfg| fix_redis_config(cfg, name, result) }

                changed += 1
              end
              break
            end
          rescue
          end
        end
      end

      changed
    end

    def self.fix_redis_config(cfg, name, result)
      if cfg['name'] == name
        cfg['host'] = result[0]
        cfg['port'] = result[1].to_i
      end
    end

    def self.make_sentinel(options)
      if @@within_event_loop
        RedisConnPool.new(size: options[:pool_size]) do
          info "[sentinel] redis new options:#{options} "
          Redis.new(:host => options[:host], :port => options[:port],
            :timeout => options[:timeout], :tcp_keepalive => 0, :driver => :synchrony, :sentinel => true)
        end
      else
        Redis.new(:host => options[:host], :port => options[:port],
          :timeout => options[:timeout], :tcp_keepalive => 0, :driver => :hiredis)
      end
    end

  end

end