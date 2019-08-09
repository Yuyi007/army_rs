#!/usr/bin/env ruby
#
# query entry file
#
# To Run this, cd to gm folder, and
# RAILS_ENV=ENV rails runner script/query_action_log.rb -- -e ENV -n NUMPROCS
#

BASE_PATH = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..'))
RS_PATH = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'rs'))
$LOAD_PATH.unshift(RS_PATH)

require 'forkmanager'
require 'boot'
require 'rs'

options = {
  :timeout => 120.0, :maxTimers => 500000, :numprocs => 1,
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
  end

end

##################
# the Outputer
class Outputer

  def output result
  end

end

##################
# the worker class
class Worker

  def initialize id, list, wrapper_options
    @id = id
    @input_file = '/tmp/input.csv'
    @output_file = '/tmp/output.csv'
    @list = gen_list
    @wrapper_options = wrapper_options.clone
    @skipped = 0
    @processed = 0
    @mapper = Mapper.new
  end

  def gen_list
    @result = {}
    File.open(@input_file).each do |line|
      line = line.encode('utf-8', 'gbk').strip
      raise "invalid line! #{line}" unless line.match(/.*,.*,.*,.*/)
      sdk, name, id, level = line.split(/,/)
      #puts "line=#{line} sdk=#{sdk} name=#{name} id=#{id} level=#{level}"
      if id.include?('_') or id.include?('-') or id.include?(' ')
        zone, cid = * (id.split(/(__)|\s+|[_\-]/))
      else
        zone, cid = 1, id
      end
      raise "invalid cid #{cid}! line is #{line}" unless cid.match(/\d+/)
      zone = 1 if zone.nil?
      zone = zone.to_i
      cid = cid.to_i
      puts "duplicate id #{cid}!" if @result[cid]
      @result[cid] = {
        :sdk => sdk,
        :id => id,
        :name => name,
        :level => level,
        :cid => cid,
        :zone => zone,
      }
    end
    @result.map { |cid, hash| [cid, hash[:zone]] }
  end

  def collect_result cid, zone
    hash = @result[cid]
    model = GameData.read_hot(cid, zone)
    raise "#{cid} not exists!" unless model and model.cur_instance_exist?
    name = model.cur_instance.name
    raise "#{cid} name is #{name}!" unless name == hash[:name]

    params = {}
    params[:player_id] = cid.to_s
    params[:zone] = zone.to_s
    params[:type] = 'login'
    params[:time_s] = '12/20/2017 12:00'
    params[:time_e] = '12/27/2017 12:00'
    params[:per_page] = 1_000_000

    logs = ElasticActionLog.search_by(params)
    for log in logs do
      hash[:reg_time] = TimeHelper.gen_date_time_sec(log.time)
    end
  end

  def gen_result
    File.open(@output_file, 'w+') do |f|
      @result.each do |pid, hash|
        c1 = hash[:sdk]
        c2 = hash[:name]
        c3 = hash[:id]
        c4 = hash[:level]
        c5 = hash[:cid]
        c6 = hash[:zone]
        c7 = hash[:reg_time]
        f.puts "#{c1}, #{c2}, #{c3}, #{c4}, #{c5}, #{c6}, #{c7}"
      end
    end
  end

  def run
    Boot.wrap_run(@wrapper_options, nil, nil, nil) do
      loginfo "worker #{@id} running..."

      @list.each do |pair|
        EM.synchrony do
          begin
            cid, zone = pair[0], pair[1]
            collect_result(cid, zone)
          rescue => er
            logerr("worker #{@id} handle #{cid} #{zone} Error:", er)
          ensure
            @processed += 1
          end
        end
      end

      EM.synchrony do
        while @processed < @list.length do; EM::Synchrony.sleep 1.0; end
        Thread.new do
          Log_.info("query worker #{@id} stop...")
          gen_result()
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

worksets = [[]]
total = 1
loginfo "supervisor worksets ready, num = #{worksets.length}, size = #{worksets[0].length}, forking workers..."
stime = Time.now

RedisRpc.destroy
RedisClusterFactory.fini

# fork workers
pm = Parallel::ForkManager.new(1, { 'tempdir' => '/tmp' })
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
