# init.rb
#
# server entry file
#
require 'boot'
require 'rs'

#####################
# parse opts

options = {}
optparse = OptionParser.new do |opts|
  opts.banner = "Usage: init.rb [options]"
  opts.on('-h', '--help', 'Display this help') do
    puts opts
    exit
  end
  options[:environment] = $ENVIRONMENT || ENV['USER']
  opts.on('-e', '--environment ENV', "Server environment, default is $USER") do |v|
    options[:environment] = v
  end
  options[:server_id] = $SERVER_ID
  opts.on('-s', '--serverid ID', "Server id") do |v|
    options[:server_id] = v
  end
  options[:host] = nil
  opts.on('-H', '--host HOST', "Server host, if set, will override config settings") do |v|
    options[:host] = v
  end
  options[:port] = $PORT || nil
  opts.on('-p', '--port PORT', "Server port, if set, will override config settings") do |v|
    options[:port] = v.to_i
  end
end.parse!

cleanup = Proc.new do
  begin
    Log_.info("@@ performing cleanup...")
    $boot_cleanup = true
    RedisClusterFactory.init_failsafe
    RedisFactory.init_failsafe
    Log_.info("@@ saving cached game data...")
    CachedGameData.put_back_all
    if CachedGameData.cache_size > 0
      # put_back may fail, because there can be packets in-processing
      # if we have force stopped eventmachine
      CachedGameData.cache_keys.each do |key|
        Log_.info("@@ cached game data #{key} remains unsaved!")
      end
      Log_.error("@@ there are #{CachedGameData.cache_size} cached game data remains unsaved!")
    end
    SessionManager.reset
    RedisRpc.destroy
    Log_.info("@@ cleanup done.")
  rescue => e
    Log_.error("Cleanup Error", e)
  ensure
    Log_.flush
  end
end

tcp_server = nil
stop = Proc.new do
  # synchronize can't be called from trap context
  Thread.new do
    begin
      Log_.info("@@ stopping rs server...")
      EM.stop_server tcp_server if tcp_server
      $boot_config.server.close_all_servers
    rescue => e
      Log_.error("Stop Error", e)
    ensure
      EM.add_periodic_timer(0.5) do
        if $boot_config.server.packet_processing == 0 then
          Log_.info("@@ stopping event machine...")
          EM.stop
        end
      end
      # in local test, 581 load test data can be put back in 8 secs
      # give more time in production environment
      EM.add_timer(180.0) do
        Log_.info("@@ force stopping event machine...")
        EM.stop
      end
      Log_.flush
    end
  end
end

step = 0
begin_time = Time.now
last_time = Time.now

timer = Proc.new do
  begin
    step = step + 1
    now = Time.now

    # if step % 60 == 0
    #   Stats_.stats_gauge_local 'timer_latency', ((now - last_time - 1.0) * 1000).to_i, 1
    #   Stats_.stats_gauge_local "load.uptime", (now - begin_time).to_i, 1
    #   Stats_.stats_gauge_local "load.connection", EM.connection_count, 1
    #   Stats_.stats_gauge_local "load.session_num", SessionManager.num_all_player_sessions, 1
    #   Stats_.stats_gauge_local 'load.redis_ops', RedisHelper_.redis_total_ops_count, 1
    #   Stats_.stats_gauge_local 'load.packet_processing', $boot_config.server.packet_processing, 1
    #   Stats_.stats_gauge_local "fiber.busy", EM::Synchrony.fiber_pool.busy_size, 1
    #   Stats_.stats_gauge_local "fiber.queued", EM::Synchrony.fiber_pool.queue_size, 1
    # end

    if step % 120 == 0
      SessionManager.cleanup_inactive_sessions()
    end

    last_time = now

    if LoadLogger.instance.enable_metrics
      LoadLogger.instance.dump_gc if step % 60 == 0
    end
  rescue => e
    Log_.error("Timer Error: ", e)
  end
end

Boot.wrap_run(options, cleanup, stop, timer) do
  host = AppConfig.server['host']
  port = AppConfig.server['port']

  EM.synchrony do
    CachedGameData.work_loop do |id, zone, success|
      ActionDb.log_action(id, zone, 'fail_save') unless success
    end
  end

  # tcp_server = EventMachine::start_server host, port, RpcServer
   Log_.info "@@ running game server on <#{host}:#{port}> env=#{options[:environment]} server_id=#{AppConfig.server_id}"
  tcp_server = EventMachine::start_server host, port, GameServer

  Log_.info "@@ running game server on <#{host}:#{port}> env=#{options[:environment]} server_id=#{AppConfig.server_id}"
end
