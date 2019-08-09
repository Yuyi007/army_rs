# Pubsub.rb
#
# 统一订阅分发消息
#

require 'eventmachine'
require 'json'
require 'fileutils'

module Boot

  HOT_PATH_RUBY_FILE = '/tmp/rs/last_patched_ruby_code.rb'
  CONFIG_FILE = 'game-config/config.json'

  def self.hot_patch_ruby_string(str)
    Kernel.eval(str)
  end

  def self.hot_patch_config()
    $boot_config.auto_load_on_file_changed.call CONFIG_FILE
  end

  module Pubsub

    KEEPALIVE_TIME = 10 unless defined? KEEPALIVE_TIME

    @@subscribers ||= {}
    @@psubscribers ||= {}
    @@timers ||= {}
    @@alivetimers ||= {}
    @@redises ||= {}

    include Loggable
    include Statsable
    include RedisHelper

    def self.init options
      @@options = options
      @@within_event_loop = options[:within_event_loop] || false
      @@no_subscribe = options[:no_subscribe] || false

      @@redises = make_channel_redises

      @@pubsub_redis = @@redises.values.sample
      raise "no pubsub redis" unless @@pubsub_redis

      unless @@no_subscribe
        @@redises.each do |name, redis|
          if @@within_event_loop
            EM.synchrony do
              begin
                init_redis(name, redis)
              rescue => e
                error("Pubsub Error: ", e)
              end
            end
          else
            init_redis(name, redis)
          end
        end

        subscribe_to_system

        $boot_config.server_delegate.on_pubsub_init
      end
    end

    def self.fini
      unless (defined? @@no_subscribe) and @@no_subscribe
        @@redises.each do |name, redis|
          EM.synchrony do
            begin
              fini_redis(name, redis)
            rescue => e
              Log_.error("fini_redis Error: ", e)
            end
          end
        end
      end

      @@redises = {}
      @@pubsub_redis = nil
      @@subscribers = {}
      @@psubscribers = {}
    end

    def self.init_redis(name, r)
      d { "-- pubsub init_redis name=#{name} r=#{r}" }
      redis = r.pubsub

      disable_keepalive(name)
      enable_keepalive(name, redis, KEEPALIVE_TIME + 3)

      redis.punsubscribe("ch:*:*")
      redis.remove_all_listeners :pmessage
      redis.psubscribe("ch:*:*")
      redis.on(:pmessage) do |pattern, channel, raw|
        EM.synchrony do
          begin
            keepalive(name)
            stats_increment_local 'pubsub.total'

            k = channel.rindex(':', -1)
            name1 = channel.slice(3, k - 3)
            zone = channel.slice(k + 1, channel.length - k + 3)
            hash = Jsonable.load_hash raw

            d{ "-- pubsub message: #{channel} #{name1} #{zone} #{raw.bytesize}" } if name1 != '__ka' 
            # d{"------@@subscribers:#{@@subscribers}"}
            blocks = @@subscribers[name1]
            if blocks
              blocks.each { |blk| blk.call(name1, zone, hash) }
            end

            @@psubscribers.each do |pattern, blocks|
              if pattern =~ name1
                blocks.each { |blk| blk.call(name1, zone, hash) }
              end
            end
          rescue => e
            error("Pubsub Error: ", e)
          end
        end
      end
    end

    def self.fini_redis(name, r)
      d { "-- pubsub fini_redis name=#{name} r=#{r}" }
      redis = r.pubsub

      disable_keepalive(name)

      redis.punsubscribe("ch:*:*")
      redis.remove_all_listeners :pmessage
      redis.close_connection
      r.close_connection
    end

    def self.subscribe(channel, &blk)
      if @@subscribers[channel]
        @@subscribers[channel] << blk
      else
        @@subscribers[channel] = [ blk ]
      end
    end

    def self.psubscribe(pattern, &blk)
      if @@psubscribers[pattern]
        @@psubscribers[pattern] << blk
      else
        @@psubscribers[pattern] = [ blk ]
      end
    end

    def self.enable_keepalive(name, redis, timeout)
      @@timers[name] ||= EM::Synchrony.add_periodic_timer(timeout) do
        begin
          if not @@alivetimers[name]
            Log_.info("redis name=#{name} idle for #{timeout} secs, reconnecting")
            self.fini; self.init(@@options)
          end
          @@alivetimers[name] = nil
        rescue => e
          Log_.error("Pubsub keepalive Error: ", e)
        end
      end
    end

    def self.disable_keepalive(name)
      EM.cancel_timer @@timers[name]
      @@timers[name] = nil
    end

    def self.keepalive(name)
      @@alivetimers[name] = true
    end

    def self.subscribe_to_system
      Pubsub.subscribe('system') do |channel, _, hash|
        case hash['command']
        when 'invalidate_cache'
          klass, method, args = hash['p1'], hash['p2'], hash['args']
          Kernel.const_get(klass).send(method + '_invalidate_cache', *args)
        when 'sessions'
          subcmd, id, zone = hash['p1'], hash['id'], hash['zone']
          case subcmd
          when 'disconnect_all'
            info "disconnect all sessions: total=#{$boot_config.server.session_count}"
            $boot_config.server.disconnect_all_sessions
          when 'disconnect'
            info "disconnect session: id=#{id} zone=#{zone}"
            $boot_config.server.disconnect_session(id, zone)
          else
            error("system channel: unknown session subcmd #{subcmd}")
          end
        when 'redis'
          if hash['p1'] == 'reinit'
            EM::Synchrony.next_tick do
              info "force reinit redis connections"
              Pubsub.fini
              RedisFactory.fini
              RedisClusterFactory.fini
              RedisClusterFactory.init
              RedisFactory.init :within_event_loop => true
              Pubsub.init :within_event_loop => true
              info "reinit redis connections done"
            end
          end
        when 'dev_mode'
          dev_mode = hash['p1']
          info "set AppConfig.server['dev_mode'] to #{dev_mode}"
          AppConfig.server['dev_mode'] = dev_mode
          Loggable.set_suppress_logs()
        when 'patch_ruby_code'
          ruby_code_str = hash['p1']
          info "calling patch_ruby_code #{ruby_code_str}"
          # FileUtils.mkdir_p('/tmp/rs/')
          # IO.write(Boot::HOT_PATH_RUBY_FILE, ruby_code_str)
          res = Boot.hot_patch_ruby_string(ruby_code_str)
          info "patch_ruby_code done!"
        when 'reload_server_config'
          Boot.hot_patch_config()
        when 'patch_client_code'
          client_lua_code = hash['p1']
          info "patch_client_code #{client_lua_code}"
          ClientHotPatchDb.get_patch_code_invalidate_cache()
        when 'clear_patch_client_code'
          info "calling clear_patch_client_code"
          ClientHotPatchDb.get_patch_code_invalidate_cache()
        when 'reload_server_list'
          info 'pubsub: reload_server_list'
          AppConfig.reload_server_list(AppConfig.path)
          CSRouter.init_checker_groups
        when 'garbage_collect_all'
          info 'pubsub: garbage_collect_all'
          GC.start
        else
          error("system channel: unknown message #{hash}")
        end

        stats_increment_local 'pubsub.system'
      end
    end

    def self.redis
      # gm tools won't init pubsub
      if not defined? @@pubsub_redis
        redises = make_channel_redises
        @@pubsub_redis = redises.values.sample
      end
      @@pubsub_redis
    end

    ######## exported keys start #########

    def self.key(channel, zone = nil)
      "ch:#{channel}:#{zone}"
    end

    ######## exported keys end #########


    ###############################################################################

    def self.included(base)
      base.extend ClassMethods
    end

    module ClassMethods

      def client_each_all_sessions(delay, &blk)
        delay ||= 0.005
        sessions = SessionManager.get_all_sessions
        hash_each(sessions, delay, &blk)
      end

      def client_each_all(delay, &blk)
        delay ||= 0.005
        sessions = SessionManager.get_all_zones
        hash_each(sessions, delay, &blk)
      end

      def client_each(zone, delay, &blk)
        delay ||= 0.005
        sessions = SessionManager.get_zone(zone)
        hash_each(sessions, delay, &blk)
      end

      def hash_each(hash, delay, &blk)
        hash_each_direct(hash, &blk)
        # hash_each_delayed(hash, delay, &blk)
      end

      def hash_each_direct(hash, &blk)
        hash.each do |k, v|
          begin
            blk.call(k, v)
          rescue => e
            error("hash_each Error: ", e)
          end
        end
      end

      # this can create subtle bugs due to its async nature
      def hash_each_delayed(hash, delay, &blk)
        EM::Synchrony.add_timer(delay) do
          if hash.size > 0
            pair = hash.shift
            begin
              blk.call(pair[0], pair[1])
            rescue => e
              error("hash_each Error: ", e)
            end
            hash_each(hash, delay, &blk)
          end
        end
      end

      def publish(channel, zone, hash)
        # Too many channels, too many whisper metrics
        # stats_increment_local "pubsub.zone.#{zone}.#{channel}"
        Pubsub.redis.publish(Pubsub.key(channel, zone), Jsonable.dump_hash(hash))
      end

      def publish_global(channel, hash)
        stats_increment_local "pubsub.global.#{channel}"
        Pubsub.redis.publish(Pubsub.key(channel), Jsonable.dump_hash(hash))
      end

      def publish_system(hash)
        stats_increment_local "pubsub.system"
        Pubsub.redis.publish(Pubsub.key('system'), Jsonable.dump_hash(hash))
      end

      # Never start this on player request basis
      def publish_system_invalidate_cache(klass, method, *args)

        # make sure the local cache has been cleared
        invalidate_method = "#{method}_invalidate_cache"

        if klass.respond_to?(invalidate_method)
          klass.send(invalidate_method, *args)
        end

        publish_system(command: 'invalidate_cache', p1: klass.to_s, p2: method, args: args)
      end

      def publish_system_disconnect_all_sessions
        publish_system(command: 'sessions', p1: 'disconnect_all')
      end

      def publish_system_disconnect_session(id, zone)
        publish_system(command: 'sessions', p1: 'disconnect', id: id, zone: zone)
      end

      def publish_system_redis_reinit
        publish_system(command: 'redis', p1: 'reinit')
      end

      def publish_system_dev_mode(dev_mode)
        publish_system(command: 'dev_mode', p1: dev_mode)
      end

      def publish_system_patch_ruby_code(ruby_code_str)
        publish_system(command: 'patch_ruby_code', p1: ruby_code_str)
      end

      def publish_system_reload_server_config()
        publish_system(command: 'reload_server_config')
      end

      def publish_system_patch_client_code(client_lua_code)
        publish_system(command: 'patch_client_code', p1: client_lua_code)
      end

      def publish_system_clear_patch_client_code()
        publish_system(command: 'clear_patch_client_code')
      end

      def publish_system_reload_server_list()
        publish_system(command: 'reload_server_list')
      end

      def publish_system_garbage_collect_all()
        publish_system(command: 'garbage_collect_all')
      end

      def publish_keepalives
        Pubsub.redis.publish(Pubsub.key('__ka'), '{}')
      end

    end

  end

end