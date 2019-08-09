# encoding: utf-8
# load.rake: load tests rakefile

def module_name
  'KfGame'
end

def get_arg(s, default)
  (s.nil? || s.length == 0) && default || s
end

namespace :load do
  %w(Idle Echo
     Update UpdateAsync
     Login LoginWait Data Delete Reset
     JoinLeave
     SwitchScene
     MainScene
     MainSceneScatter64 MainSceneScatter128 MainSceneScatter256
     MainSceneDiv2 MainSceneDiv3 MainSceneDiv4 MainSceneDiv5
     MainSceneDiv10 MainSceneDiv20 MainSceneDiv200 MainSceneDiv500
     PveScene
     PveSceneDiv2 PveSceneDiv5 PveSceneDiv10 PveSceneDiv50 PveSceneDiv80
     PveSceneDiv100 PveSceneDiv200 PveSceneDiv300 PveSceneDiv400 PveSceneDiv500
     PvpScene
     ).each do |name|
    task_name = name.downcase.to_sym
    desc "#{name} load test"
    task task_name, [:repeat, :conc, :total, :start, :zone, :port, :host] do |_t, args|
      conc = get_arg(args[:conc], 1)
      repeat = get_arg(args[:repeat], 1)
      total = get_arg(args[:total], conc)
      start = get_arg(args[:start], 0)
      zone = get_arg(args[:zone], 1)
      port = get_arg(args[:port], 5081)
      host = get_arg(args[:host], "127.0.0.1")
      load_erl_options = "ELIXIR_ERL_OPTIONS='#{ERL_OPTIONS_CONTENT} -env ERL_MAX_ETS_TABLES 25000' "
      system "ulimit -n #{ulimit_nofile}; #{load_erl_options} \
        elixir --name load#{start}@127.0.0.1 -S \
        mix do compile --no-deps-check, egg.load #{module_name}.Load.#{name} \
        -h #{host} -c #{conc} -r #{repeat} -t #{total} -s #{start} -p #{port} -z #{zone}"
    end
  end
end

# legacy ruby load test client
namespace :load2 do
  %w(Update).each do |name|
    task_name = name.downcase.to_sym
    desc "#{name} load test"
    task task_name, [:repeat, :conc, :total, :port] do |_t, args|
      conc = get_arg(args[:conc], 1)
      repeat = get_arg(args[:repeat], 1)
      total = get_arg(args[:total], conc)
      port = get_arg(args[:port], 5081)
      system "ulimit -n #{ulimit_nofile}; \
        ruby -C. -Ilib/boot lib/boot/boot/launchers/load.rb \
        -p #{port} -c #{conc} -r #{repeat} -t #{total} -T 1"
    end
  end
end
