# redis_migrate_db.rb
# Migrate redis data when hash ring distribution has changed
# DOES NOT support migration to same host and port but different ports

require 'redis_migrator'

# Monkey patches redis-migrator to wrap errors and put logs
class Redis

  class Migrator

    # dump all keys to files
    def dump_all_keys
      file_keep = File.open('migrator_keys.keep', 'w+')
      file_migrate = File.open('migrator_keys.migrate', 'w+')

      old_cluster_keys.inject({}) do |acc, key|
        old_node = @old_cluster.node_for(key).client
        new_node = @new_cluster.node_for(key).client

        old_url = "redis://#{old_node.host}:#{old_node.port}/#{old_node.db}"
        new_url = "redis://#{new_node.host}:#{new_node.port}/#{new_node.db}"

        if (old_node.host != new_node.host) || (old_node.port != new_node.port)
          file_migrate.puts "#{key} #{old_url} -> #{new_url}"
        else
          file_keep.puts "#{key} #{old_url}"
        end
      end

      file_keep.close
      file_migrate.close
    end

    # dump migrated keys
    def dump_migrated_keys
      file = File.open('migrator_keys.after', 'w+')

      new_cluster_keys.each do |key|
        new_node = @new_cluster.node_for(key).client

        new_url = "redis://#{new_node.host}:#{new_node.port}/#{new_node.db}"
        file.puts "#{key} #{new_url}"
      end

      file.close
    end

    def new_cluster_keys
      @new_cluster_keys ||= @new_cluster.keys("*")
    end
  end

  class NativeMigrator

    TARGET_KEY_BUSY_REGEX ||= /Target key name is busy/

    include Boot::Loggable

    # For scenarios the migration is breaked and continued, there are three conditions
    # that this method would meet when called:
    # 1. old node has the key, new node has no key [do migrate the key]
    # 2. old node has no key, new node has the migrated key [redis returns NOKEY]
    # 3. old node and new node both has the key [redis returns Target key busy]
    def migrate_key(node, key, options)
      begin
        if Redis::VERSION > '3.0.4'
          node.migrate(key, options)
        else
          node.migrate([options[:host], options[:port], key, options[:db], options[:timeout]])
        end
      rescue Redis::CommandError => e
        if e.message =~ TARGET_KEY_BUSY_REGEX
          # TODO check the value is correct, and delete the key from the old host
          # This might be better to be done by humans
          raise "key #{key}: Target key busy!"
        else
          raise e
        end
      end
    end
  end

end


module Boot

  #
  # Redis migrate db
  #
  class RedisMigrateDb

    attr_reader :redis

    include Loggable

    def self.instance
      @@instance ||= RedisMigrateDb.new(Boot::RedisFactory.make_system_redis)
    end

    def initialize redis
      @redis = redis
    end

    # Do the data migration
    # @param old_cfg [Array] the old redis config
    #   - if not specified, default to get_old_redis_cfg
    # @param new_cfg [Array] the new redis config
    #   - if not specified, default to AppConfig.redis
    def do_migrate old_cfg = nil, new_cfg = nil
      old_cfg ||= get_old_redis_cfg
      new_cfg ||= AppConfig.redis

      if old_cfg == new_cfg
        info "redis_migrate_db: config was not changed"
        return false
      end

      old_hosts = make_hosts_from_cfg old_cfg
      new_hosts = make_hosts_from_cfg new_cfg

      # validate hosts
      ok, message = validate old_hosts, new_hosts
      raise "validation failed! reason: #{message}" unless ok

      # run migration
      run_migration old_hosts, new_hosts, true

      # after successful migration, record this redis cfg
      set_old_redis_cfg AppConfig.redis

      true
    end

    def validate old_hosts, new_hosts
      return true, nil
    end

    def run_migration old_hosts, new_hosts, dump_keys = false
      info "redis_migrate_db: old_hosts=#{old_hosts}"
      info "redis_migrate_db: new_hosts=#{new_hosts}"

      migrator = Redis::Migrator.new(old_hosts, new_hosts)

      if dump_keys
        info "redis_migrate_db: dumping all keys to file..."
        migrator.dump_all_keys
      end

      info "redis_migrate_db: start migrating keys..."
      migrator.run

      if dump_keys
        info "redis_migrate_db: dumping all keys to file after migrated..."
        migrator.dump_migrated_keys
      end

      info "redis_migrate_db: migration ended successfully"
    end

    # Check if the old redis config is the same with the new redis config
    # If not the same, a migration is needed before the app can be run
    def should_migrate?
      old_redis_cfg = get_old_redis_cfg
      cur_redis_cfg = AppConfig.redis
      if old_redis_cfg == nil
        info "redis_migrate_db: old redis config is empty, using current redis config"
        set_old_redis_cfg cur_redis_cfg
        return false
      end

      return old_redis_cfg != cur_redis_cfg
    end

    # Get the old redis config
    # @return [Hash] the redis config
    def get_old_redis_cfg
      raw = redis.get(old_redis_cfg_key)
      raw ? Jsonable.load_hash(raw) : nil
    end

    # Set the old redis config
    # @param cfg [Hash] the redis config
    def set_old_redis_cfg cfg
      redis.set(old_redis_cfg_key, Jsonable.dump_hash(cfg))
    end

    # Delete the old redis config
    def del_old_redis_cfg
      redis.del(old_redis_cfg_key)
    end

    ############# For tests only

    # Test can be done like this, in console (Never do this on production!)
    def self.test_migration
      m = RedisMigrateDb.instance
      old_hosts = [ 'redis://127.0.0.1:6379/1', 'redis://127.0.0.1:6380/1' ]
      new_hosts = [ 'redis://127.0.0.1:6379/1' ]
      m.run_migration old_hosts, new_hosts, true
      m.run_migration new_hosts, old_hosts, false
    end

  private

    def make_hosts_from_cfg redis_cfg
      redis_cfg.map do |cfg|
        host = cfg['host']
        port = cfg['port']
        db = cfg['db'] || AppConfig.default_db.to_i
        "redis://#{host}:#{port}/#{db}"
      end
    end

    def old_redis_cfg_key
      'old_redis_cfg'
    end

  end

end