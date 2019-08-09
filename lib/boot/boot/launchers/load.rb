#!/usr/bin/env ruby
# load.rb
# load test init file
#

$LOAD_PATH.unshift("#{File.expand_path(File.join(File.dirname(__FILE__), '..'))}")
$LOAD_PATH.unshift("#{File.expand_path(File.join(File.dirname(__FILE__), '../boot'))}")

BASE_PATH=File.expand_path(File.join(File.dirname(__FILE__), '../../../..'))

Dir.chdir(File.expand_path(File.dirname(__FILE__)))

require 'rubygems'
require 'optparse'
require 'eventmachine'

require 'boot'
include Boot

require 'tools/load/client_rpc'
require 'tools/load/client'
require 'tools/load/test'

Boot.set_config(BootConfig.new do |cfg|
end)

#####################
# parse opts

options = {}
optparse = OptionParser.new do |opts|
  opts.banner = "Usage: load.rb [options]"
  opts.on('-h', '--help', 'Display this help') do
    puts opts
    exit
  end
  options[:host] = '127.0.0.1'
  opts.on('-H', '--host HOST', "Set server host, default is #{options[:host]}") do |v|
    options[:host] = v
  end
  options[:port] = 5081
  opts.on('-p', '--port PORT', "Set server port, default is #{options[:port]}") do |v|
    options[:port] = v.to_i
  end
  options[:total] = 1
  opts.on('-t', '--total TOTAL', "Set total clients, default is #{options[:total]}") do |v|
    options[:total] = v.to_i
  end
  options[:repeat] = 1 # TODO implement repeat in LoadClient
  opts.on('-r', '--repeat REPEAT', "Set each client repeat times, default is #{options[:repeat]}") do |v|
    options[:repeat] = v.to_i
  end
  options[:concurrency] = 1
  opts.on('-c', '--concurrency CONCURRENCY', "Set max concurrent clients, default is #{options[:concurrency]}") do |v|
    options[:concurrency] = v.to_i
  end
  options[:start_user] = 1
  opts.on('-s', '--start START', "Start from user, default is #{options[:start_user]}") do |v|
    options[:start_user] = v.to_i
  end
  options[:zone] = 1
  opts.on('-z', '--zone ZONE', "Set the zone to test, default is #{options[:zone]}") do |v|
    options[:zone] = v.to_i
  end
  options[:connection_only] = false
  opts.on('-C', '--connection', "Test connection only. default is #{options[:connection_only]}") do
    options[:connection_only] = true
  end
  options[:idle] = 0
  opts.on('-i', '--idle IDLE', "hold for IDLE seconds after connected. default is #{options[:idle]}") do |v|
    options[:idle] = v.to_i
  end
  options[:encoding] = 2
  opts.on('-e', '--encoding ENCODING', "Set client encoding, default is #{options[:encoding]}") do |v|
    options[:encoding] = v.to_i
  end
  options[:server_encoding] = 'msgpack-auto'
  opts.on('-E', '--server ENCODING', "Set server encoding, default is '#{options[:server_encoding]}'") do |v|
    options[:server_encoding] = v
  end
  options[:param] = nil
  opts.on('-P', '--param PARAM', "Special param for specific tests") do |v|
    options[:param] = v
  end
  options[:test] = 1
  opts.on('-T', '--test TEST', "run specified test. default is #{options[:test]}
                                      available tests:
                                      1 - update
                                      2 - login
                                      3 - get game data
                                      others - random tests") do |v|
    options[:test] = v.to_i
  end
end.parse!

Boot::AppConfig.preload(options[:environment], BASE_PATH)
Boot::AppConfig.override(options)

#####################
# start load test

info = {
  :started => 0,
  :running => 0,
  :finished => 0,
  :error => 0,
  :errorReasons => {},
  :timeout => 0,
  :beginTime => 0,
  :endTime => 0,
  :requests => 0,
  :totalDelay => 0,
}

summary = Proc.new do
  total = options[:total]
  started = info[:started]
  time = (Time.now - info[:beginTime]).to_i
  r = info[:running]
  f = info[:finished]
  e = info[:error]
  t = info[:timeout]
  puts "running #{r} | finished #{f} | error #{e} | #{started}/#{total} | #{time} secs"
end

stats = Proc.new do
  time = (info[:endTime] - info[:beginTime]).round(3)
  throughput = (info[:requests] / time.to_f).round(2)
  if info[:requests] == 0
    latency = 0.0
  else
    latency = (info[:totalDelay] / info[:requests] * 1000).round(2)
  end
  errors = info[:errorReasons].inject('') do |s, reason|
    s + reason[0] + '=' + reason[1].to_s + ' '
  end
  puts "- clients: #{options[:total]}
- concurrency: #{options[:concurrency]}
- time: #{time} secs
- errors: #{errors}
- request/response: #{info[:requests]}
- throughput: #{throughput} req/sec
- latency (avg): #{latency} msecs"
end

finish = Proc.new do
  info[:endTime] = Time.now
  summary.call
  stats.call
  EventMachine.stop
end

Loggable.set_suppress_logs true

EM.epoll
EM.kqueue = true if EM.kqueue?

if RUBY_PLATFORM =~ /darwin/
  begin
    Process.setrlimit(Process::RLIMIT_NOFILE, 4096)
  rescue => e
    puts "Failed to modify the socket limit Error: #{e}"
  end
end

fdnum = EM.set_descriptor_table_size(32768)
EM.set_max_timers(100000)
puts "fdnum=#{EM.set_descriptor_table_size} maxtimers=#{EM.get_max_timers}"

EventMachine.run do

  queue = EM::Queue.new
  info[:beginTime] = Time.now

  userFactory = LoadUserFactory.new options[:zone], options[:start_user]
  testFactory = LoadTestFactory.new options[:test]
  LoadClient.init queue, userFactory, testFactory, options

  create = Proc.new do |result|
    # result.status is :finished or :error or :timeout
    if result != nil
      info[result[:status]] += 1
      if result[:status] == :error
        if info[:errorReasons][result[:message]]
          info[:errorReasons][result[:message]] += 1
        else
          info[:errorReasons][result[:message]] = 1
        end
      end
      info[:requests] += result[:requests]
      info[:totalDelay] += result[:totalDelay]
    end
    info[:running] = info[:started] - info[:finished] - info[:error] - info[:timeout]
    quota = options[:total] - info[:started]

    if quota == 0 and info[:running] == 0
      # all done, end the test
      finish.call
    else
      # create enough clients
      num = [options[:concurrency] - info[:running], quota].min
      info[:started] += num
      info[:running] += num

      created = 0
      batch = 50 # limit session rate
      createBatch = proc do
        EM.next_tick do # next_tick to avoid stack overflow
          if created < num then
            last = [created + batch, num].min
            for i in created...last do
              EventMachine.connect options[:host], options[:port], LoadClient
              created += 1
            end
            if created < num then
              EM.add_timer 0.1, createBatch
            end
          end
        end
      end
      createBatch.call

      queue.pop &create
    end
  end

  queue.pop &create
  queue.push nil

  EventMachine.add_periodic_timer(10, &summary)

  Signal.trap('INT', &finish)

end