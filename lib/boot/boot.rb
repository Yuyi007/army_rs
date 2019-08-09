# boot.rb
#

require 'optparse'
require 'logger'
require 'syslogger'
require 'singleton'
require 'eventmachine'
require 'em-resolv-replace'
require 'em-synchrony/em-http'
require 'nest'
require 'thread'

# require 'boot/helpers/bugsnag_ext'
require 'boot/helpers/syslogger_ext'
require 'boot/helpers/loggable'
require 'boot/helpers/jsonable'
require 'boot/helpers/cacheable'
require 'boot/helpers/statsable'
require 'boot/helpers/hash_storable'
require 'boot/helpers/hash_ext'
require 'boot/helpers/array_ext'
require 'boot/helpers/nil_ext'
require 'boot/helpers/string_ext'
require 'boot/helpers/ohm_ext'
require 'boot/helpers/big_decimal_ext'
require 'boot/helpers/rational_ext'
require 'boot/helpers/float_ext'
require 'boot/helpers/resolv_ext'
require 'boot/helpers/http_connection_ext'
require 'boot/helpers/synchrony_ext'
require 'boot/helpers/em_hiredis_ext'
require 'boot/helpers/redis_helper'
require 'boot/helpers/redis_ext'
require 'boot/helpers/redis_lock'
require 'boot/helpers/redis_hash'
require 'boot/helpers/zone_redis_hash_helper'
require 'boot/helpers/redis_index'
require 'boot/helpers/redis_queue'
require 'boot/helpers/redis_message_queue'
require 'boot/helpers/redis_rpc'
require 'boot/helpers/redis_conn_pool'
require 'boot/helpers/crc16'
require 'boot/helpers/cluster'
require 'boot/helpers/mysql2_ext'
require 'boot/helpers/load_logger'
require 'boot/helpers/fiber_pool'
require 'boot/helpers/lz4_ext'
require 'boot/helpers/helper'

require 'boot/packet/server_encoding'
require 'boot/packet/gen_long_packet'

require 'boot/server/app_config'
require 'boot/server/server_queue'
require 'boot/server/game_server'
require 'boot/server/dispatcher'

require 'boot/config'
require 'boot/handler'
require 'boot/session'
require 'boot/delegates'

require 'boot/rpc/bcast_info'
require 'boot/rpc/tcp_backend'
require 'boot/rpc/rpc'
require 'boot/rpc/rpc_server'
require 'boot/rpc/rpc_dispatcher'
require 'boot/rpc/rpc_functions'

require 'boot/jobs/archive_data_job'

require 'boot/db/sentinel_factory'
require 'boot/db/redis_factory'
require 'boot/db/redis_cluster_factory'
require 'boot/db/mysql_factory'
require 'boot/db/kyoto_factory'
require 'boot/db/dynamic_app_config'
require 'boot/db/game_data'
require 'boot/db/cached_game_data'
require 'boot/db/session_manager'
require 'boot/db/pubsub'
require 'boot/db/load_db'
require 'boot/db/action_db'
require 'boot/db/archive_data'
require 'boot/db/transfer_data'
require 'boot/db/redis_migrate_db'
require 'boot/db/queuing_db'
require 'boot/db/announcement'
require 'boot/db/permission'
require 'boot/db/user'

require 'boot/tools/gm_api'


BOOT_PATH = File.expand_path(File.join(File.dirname(__FILE__), '..'))

module Boot

  VERSION = '0.1.0'

  class Log_
    include Loggable
  end

  class Stats_
    include Statsable
  end

  class RedisHelper_
    include RedisHelper
  end

  def self.debug_watch_files
    mtable = {}
    files = debug_scan_files
    debug_update_files(mtable, files, false)

    Thread.new do
      loop do
        Kernel.sleep 2.5
        files = debug_scan_files
        debug_update_files(mtable, files, true)
      end
    end
  end

  def self.debug_scan_files
    files = Dir.glob("lib/boot/**/*.rb")
    rest = $boot_config.auto_load_paths.call
    files += rest if rest
    files
  end

  def self.debug_update_files(mtable, files, reload)
    files.each do |name|
      t = Kernel.test(?M, name)
      if reload and t.to_i > mtable[name].to_i
        puts "$$ Reloading: #{name}"
        begin
          loaded = $boot_config.auto_load_on_file_changed.call name

          if not loaded
            if name =~ /launchers/
              puts "$$ Skip launchers"
            elsif name.end_with? '.rb'
              load name
            end
          end
        rescue Exception => e
          puts "$$ Reloading #{name} failed: #{e.message}"
        end
      end
      mtable[name] = t
    end
  end

  def self.wrap_run(options, cleanup, stop, timer, &start)
    unless cleanup
      cleanup = Proc.new do
        begin
          Log_.info("@@ performing general cleanup...")
          $boot_cleanup = true
          RedisClusterFactory.init_failsafe
          RedisFactory.init_failsafe
          RedisRpc.destroy
        rescue => e
          Log_.error("Cleanup Error", e)
        ensure
          Log_.flush
        end
      end
    end

    unless stop
      stop = Proc.new do
        Thread.new do
          Log_.info("@@ performing general stop...")
          EM.stop
        end
      end
    end

    unless timer
      timer = Proc.new do
      end
    end

    #########################################

    Dir.chdir($boot_config.root_path)

    AppConfig.preload(options[:environment], options[:base_path])
    AppConfig.override(options)

    dev_mode = AppConfig.dev_mode?
    Log_.info "[*** in development mode ***]" if dev_mode

    debug_watch_files if dev_mode
    Loggable.set_suppress_logs()

    Statsable.init(AppConfig.statsd)
    # Stats_.sample_rate = 0.001

    # Bugsnag.configure do |config|
    #   config.api_key = AppConfig.bugsnag['api_key']
    # end

    #########################################

    EM.epoll
    EM.kqueue = true if EM.kqueue?

    if RUBY_PLATFORM =~ /darwin/
      begin
        Process.setrlimit(Process::RLIMIT_NOFILE, 4096)
      rescue => e
        Log_.error("Modify the socket limit Error: ", e)
      end
    end

    EM.set_descriptor_table_size(options[:max_descriptors] || 32768)
    EM.set_max_timers(options[:max_timers] || 100000) unless EM.reactor_running?

    EM::Synchrony.init_fiber_pool

    init = Proc.new do
      EM.run do # run handles fork better than synchrony
        EM.synchrony do
          begin
            Log_.info("@@ event loop started env=%s fdnum=%d max_timers=%d" %
              [ options[:environment], EM.set_descriptor_table_size, EM.get_max_timers ])

            Signal.trap("INT") { stop.call }
            Signal.trap("TERM") { stop.call }

            SentinelFactory.init :within_event_loop => true, :with_channel => true
            RedisFactory.init :within_event_loop => true, :pool_size => options[:pool_size], :timeout => options[:timeout]
            RedisClusterFactory.init :within_event_loop => true, :pool_size => options[:pool_size], :timeout => options[:timeout]
            MysqlFactory.init :within_event_loop => true
            KyotoFactory.init :within_event_loop => true
            Pubsub.init :within_event_loop => true

            SessionManager.init

            RedisRpc.init(RedisHelper_.get_redis)

            EM.add_shutdown_hook { cleanup.call } if cleanup
            EM.error_handler { |e| Log_.error("Error raised during event loop", e) }
            EM::Synchrony.add_periodic_timer(1) { timer.call } if timer

            RedisRpc.worker.refill

            $boot_config.server_delegate.on_server_prefork options
            $boot_config.server_delegate.on_server_start options

            start.call

            EM.synchrony { RedisRpc.work_loop }
          rescue => e
            Log_.error("Init Error: ", e)
            stop.call
          end
        end
      end

      Log_.info("@@ stopped.")
    end

    # server restarting is deprecated
    # using the more robust daemon monitor
    begin
      init.call
    rescue => e
      Log_.error("Fatal Error: ", e)
      Log_.info "@@ wrapper stopped because of fatal error."
    end

  end

end