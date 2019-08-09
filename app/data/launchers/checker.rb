# checker.rb
#
# checker entry file
#

require 'boot'
require 'rs'

options = { :timeout => 120.0, :pool_size => 10, :max_timers => 500000 }
optparse = OptionParser.new do |opts|
  opts.banner = "Usage: checker.rb [options]"
  opts.on('-h', '--help', 'Display this help') do
    puts opts
    exit
  end
  options[:environment] = ENV['USER']
  opts.on('-e', '--environment ENV', "Server environment, default is $USER") do |v|
    options[:environment] = v
  end
  options[:server_id] = $SERVER_ID
  opts.on('-s', '--serverid ID', "Server id") do |v|
    options[:server_id] = v
  end

  options[:server_index] = $SERVER_INDEX
  opts.on('-i', '--serverindex index', "Server index") do |v|
    options[:server_index] = v
  end
end.parse!

def stats_online
  num_open_zones = DynamicAppConfig.num_open_zones
  result = {}
  total = 0

  Stats_.stats_gauge_global "zone", num_open_zones, 1
  (1..num_open_zones).each do |zone|
    num_online = SessionManager.num_online(zone)
    Stats_.stats_gauge_global "zones.#{zone}.online", num_online, 1
    Stats_.stats_gauge_global "zones.#{zone}.players", Player.player_count(zone), 1

    result["z:#{zone}"] = "#{num_online}"
  end
  result.each { |k, v| total += v.to_i }
  result["total"] = total.to_s

  Log_.stat("-- online_new, #{JSON.generate(result)}")
end

def stats_queues
  RedisRpc.instance.all_registered_ids.each do |id|
    RedisRpc::CallJob.set_server_id(id)
    RedisRpc::ReplyJob.set_server_id(id)
    worker = RedisMessageQueue::Worker.new(RedisHelper_.get_redis,
      [RedisRpc::CallJob, RedisRpc::ReplyJob])
    worker.queues.each do |queue|
      Stats_.stats_gauge_global "queues.#{queue.name}.length", queue.length, 0.01
      Stats_.stats_gauge_global "queues.#{queue.name}.process_length", queue.process_length, 0.01
    end
  end
end

step = 0
timer = Proc.new do
  begin
    step = step + 1
    sid = AppConfig.server_id
    zones = CSRouter.get_checker_zones(sid)

    #to do initialize
    MatchManager.init sid, zones
    PeriodicUpdate.tick step, zones
  rescue => e
    Log_.error("Timer Error: ", e)
  end
end

Boot.wrap_run(options, nil, nil, timer) do
  if not AppConfig.checker_servers.select{ |server| server['name'] == AppConfig.server_id }
    raise "server_id #{AppConfig.server_id} was not found in config.json!"
  end

  Log_.info "@@ running checker server_id=#{AppConfig.server_id} env=#{options[:environment]}"

  if AppConfig.server_id == CSRouter.get_archive_checker()
    Log_.info "schedule to delete old archives..."
    Helper.schedule_everyday('3am') do
      EM.synchrony do
        begin
          days = AppConfig.server['archive_data_days'] || 21
          time = Chronic.parse("#{days} days ago")
          Log_.info "deleting archive data older than #{days} days..."

          (1..DynamicAppConfig.num_open_zones).each do |zone|
            Log_.info "deleting all archives in zone #{zone} older than #{time}..."
            ArchiveData.delete_archive_older_than(zone, time)
          end
        rescue => er
          Log_.error("clean up archives Error: ", er)
        end
      end
    end

    if AppConfig.server['transfer_cold_data']
      Log_.info "starting transfer work loop..."
      EM.synchrony { TransferDataWorker.new.work_loop }
    else
      Log_.info "transfer of redis data not enabled"
    end
  end

end