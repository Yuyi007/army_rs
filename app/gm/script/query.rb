#!/usr/bin/env ruby
#
# query entry file
#
# To Run this, cd to gm folder, and
# RAILS_ENV=ENV rails runner script/query.rb -- -e ENV -n NUMPROCS
#

BASE_PATH = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..'))
RS_PATH = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'rs'))
$LOAD_PATH.unshift(RS_PATH)

require 'forkmanager'
require 'boot'
require 'rs'

options = {
  :timeout => 120.0, :maxTimers => 500000, :numprocs => 2,
}
optparse = OptionParser.new do |opts|
  opts.banner = "Usage: query.rb [options]
Query player data"
  opts.on('-h', '--help', 'Display this help') do
    puts opts
    exit
  end
  options[:environment] = $ENVIRONMENT || ENV['USER']
  opts.on('-e', '--environment ENV', "Server environment, default is $USER") do |v|
    options[:environment] = v.strip
  end
  options[:server_id] = $SERVER_ID
  opts.on('-s', '--serverid ID', "Server id") do |v|
    options[:server_id] = v
  end
  opts.on('-n', '--numprocs PROCS', "number of worker processes, default is #{options[:numprocs]}") do |v|
    options[:numprocs] = v.to_i
  end
  opts.on('-o', '--out OUT', "output log to file") do |v|
    options[:out] = v
  end
  opts.on('-p', '--playerIdWithZones PLAYERS', "Run on players, instead of all users") do |v|
    options[:players] = v.split(',').reject { |x| x == nil or x.empty? }
      .map { |idWithZone| pair = idWithZone.split(':'); pair[1] = pair[1].to_i; pair }
  end
end.parse!

def logresult msg; puts msg; end
def loginfo msg; puts "query.rb: #{msg}"; end
def logerr msg, e; puts "query.rb: #{msg} #{e.message}\n\t" + e.backtrace.join("\n\t"); end

##################
# the Mapper
class Mapper

  attr_reader :data

  def initialize
    @data = {}
  end

  def map model
    # Handles model here, fills in data
    # This example tries to count total player numbers and each levels
    zone = model.chief.zone || 0

    data[zone] = data[zone] || { :count => 0, :levels => {} }
    zone_data = data[zone]

    zone_data[:count] += 1
    if model.cur_instance_exist?
      # level = model.cur_instance.hero.level
      level = -1
      model.instances.each do |_, inst|
        if inst and inst.hero.level > level then level = inst.hero.level end
      end
    else
      level = 0
    end
    zone_data[:levels][level] = zone_data[:levels][level] || 0
    zone_data[:levels][level] += 1
  end

end

##################
# the Reducer
class Reducer

  attr_reader :result

  def initialize
    @result = {}
  end

  def reduce data
    # Merge mapped data to result
    # This example tries to count total player numbers and each levels
    data.each do |zone, zone_data|
      result[zone] = result[zone] || { :count => 0, :levels => {} }
      zone_result = result[zone]

      zone_result[:count] += zone_data[:count]
      zone_data[:levels].each do |level, count|
        zone_result[:levels][level] = zone_result[:levels][level] || 0
        zone_result[:levels][level] += count
      end
    end
  end

end

##################
# the Outputer
class Outputer

  def output result
    # Print result
    # This example tries to count total player numbers and each levels
    (1..DynamicAppConfig.num_open_zones).each do |zone|
      zone_result = result[zone]
      if zone_result
        logresult "zone #{zone}: total player=#{zone_result[:count]}"
        (-1..70).each do |level|
          if zone_result[:levels][level]
            logresult "  level #{level}: #{zone_result[:levels][level]}"
          end
        end
      end
    end
  end

end

##################
# the worker class
class Worker

  def initialize id, list, wrapper_options
    @id = id
    @list = list
    @wrapper_options = wrapper_options.clone
    @skipped = 0
    @processed = 0
    @mapper = Mapper.new
  end

  def run
    Boot.wrap_run(@wrapper_options, nil, nil, nil) do
      loginfo "worker #{@id} running..."

      @list.each do |pair|
        EM.synchrony do
          begin
            player_id, zone = pair[0], pair[1]
            model = GameData.read_hot(player_id, zone)
            if model
              @mapper.map model
            else
              @skipped += 1
            end
          rescue => er
            logerr("worker #{@id} handle #{player_id} #{zone} Error:", er)
          ensure
            @processed += 1
          end
        end
      end

      EM.synchrony do
        while @processed < @list.length do; EM::Synchrony.sleep 1.0; end
        Thread.new do
          Log_.info("query worker #{@id} stop...")
          EM.stop
        end
      end
    end

    loginfo "worker #{@id} finishes, size=#{@list.length} processed=#{@processed} skipped=#{@skipped}"
    { :processed => @list.length - @skipped, :data => @mapper.data }
  end

end

##################
# init supervisor
AppConfig.preload(options[:environment], BASE_PATH)
# SentinelFactory.init :within_event_loop => false, :with_channel => false
# RedisFactory.init :within_event_loop => false, :timeout => options[:timeout]
RedisClusterFactory.init :within_event_loop => false, :timeout => options[:timeout]
MysqlFactory.init :within_event_loop => false
KyotoFactory.init :within_event_loop => false
GameConfig.preload(BASE_PATH)
GameDataFactory.preload(BASE_PATH)
loginfo "supervisor up, splitting worksets..."

# get splitted work sets
if options[:players]
  loginfo "supervisor splitting worksets: using player ids from options..."
  total = options[:players].length
  num = (total.to_f / options[:numprocs]).ceil
  worksets = options[:players].shuffle.each_slice(num).to_a
else
  loginfo "supervisor splitting worksets: collecting all player ids from redis..."
  players = []
  zones = Player.get_all_players_cached()
  loginfo "zones=#{zones}"
  zones.each { |zone, ids| ids.each { |player_id| players << [ player_id, zone.to_i ] } }
  total = players.length
  num = (total.to_f / options[:numprocs]).ceil
  loginfo "supervisor splitting worksets: total=#{total} numprocs=#{options[:numprocs]} num=#{num}"
  worksets = players.shuffle.each_slice(num).to_a
end
loginfo "supervisor worksets ready, num = #{worksets.length}, size = #{worksets[0].length}, forking workers..."
stime = Time.now

RedisRpc.destroy
RedisClusterFactory.fini

# fork workers
pm = Parallel::ForkManager.new(options[:numprocs], { 'tempdir' => '/tmp' })
reducer = Reducer.new
outputer = Outputer.new

pm.run_on_finish do |pid,exit_code,ident,exit_signal,core_dump,data|
  loginfo "supervisor worker #{exit_code} pid [#{pid}] finishes"
  reducer.reduce data[:data] if defined? data and data
end

i = 0
worksets.each do |set|
  pid = pm.start(i) and (loginfo "worker #{i} pid [#{pid}] started, work set is #{set.length}"; i += 1; next)

  # from child
  begin
    pm.finish(i, Worker.new(i, set, options).run)
  rescue => er
    logerr "supervisor worker #{i} Error: ", er
    pm.finish(i, nil)
  end
end

loginfo "supervisor sleeping... #{Process.pid}"
pm.wait_all_children

duration = Time.now - stime
mps = (total.to_f / duration).to_i
mps_worker = (mps.to_f / options[:numprocs]).to_i
loginfo "supervisor stats: total=#{total} time=#{duration}s throughput=#{mps} throughput_worker=#{mps_worker}"

loginfo "-----------------------------------------------------"
loginfo "supervisor result:"
json = JSON.generate(reducer.result)
loginfo json
File.open(options[:out], 'w+') { |f| f.puts json } if options[:out]

loginfo "-----------------------------------------------------"
loginfo "outputer result:"
outputer.output(reducer.result)
loginfo ""
loginfo "-----------------------------------------------------"

loginfo "supervisor terminate."