# godconfig.rb
#

ROOT_DIR = File.expand_path(File.dirname(__FILE__) + '/..')
PID_DIR = File.expand_path(File.dirname(__FILE__) + '/../pids')
BOOT_DIR = File.expand_path(File.dirname(__FILE__) + '/../lib/boot')
DATA_DIR = File.expand_path(File.dirname(__FILE__) + '/../app/data')
COMBAT_DIR = File.expand_path(File.dirname(__FILE__) + '/../lib/skynet')
GM_DIR = File.expand_path(File.dirname(__FILE__) + '/../app/gm')
STATS_DIR = File.expand_path(File.dirname(__FILE__) + '/../app/stat')
PAYMENT_DIR = File.expand_path(File.dirname(__FILE__) + '/../app/payment')
DEFAULTS_FILE = ROOT_DIR + '/god.defaults'
# ERL_OPTIONS = "-kernel inet_dist_listen_min 4100 inet_dist_listen_max 4200 \
#   +P 262144 +Q 655360 +t 1048576 +hms 200 +K true +A 16 -sbt db \
#   -env ERL_MAX_ETS_TABLES 3500 \
#   -heart -env HEART_BEAT_TIMEOUT 30"
# ERL_COOKIE = "(&uwuquta_rec-e?uv2wa5@EpeBRa@e2"
DATA_ULIMIT = 20000
START_PORT = 5081
END_PORT = START_PORT + 32
GM_PORT = 3008
STATS_PORT = 3010
PAYMENT_PORT = 3009
APP = 'rs'

$LOAD_PATH.unshift(BOOT_DIR).unshift(DATA_DIR)
require 'rs'

defaults_file = JSON.parse(File.read(DEFAULTS_FILE)) rescue {}
defaults = { 'procs' => Boot::Helper.processor_count, 'environment' => ENV['USER'] }
opts = defaults.merge(defaults_file)

opts['procs'] = ENV['PROCS'].to_i if ENV['PROCS']
opts['checker'] = (ENV['CHECKER'] == 'true') if ENV['CHECKER']
opts['checkers'] = ENV['CHECKERS'].to_i if ENV['CHECKERS']
opts['checkers'] = opts['checkers'] || 1
opts['combat'] = (ENV['COMBAT'] == 'true') if ENV['COMBAT']
opts['gm'] = (ENV['GM'] == 'true') if ENV['GM']
opts['stats'] = (ENV['STATS'] == 'true') if ENV['STATS']
opts['payment'] = (ENV['PAYMENT'] == 'true') if ENV['PAYMENT']
opts['environment'] = ENV['ENVIRONMENT'] if ENV['ENVIRONMENT']

File.open(DEFAULTS_FILE, 'w+') { |f| f.puts JSON.generate(opts) }

$ENVIRONMENT = opts['environment']
require 'launchers/prefork'

applog(nil, :info, "opts=#{opts}")

God.terminate_timeout = 120
God.pid_file_directory = PID_DIR

require 'socket'
LOCAL_IP = TCPSocket.gethostbyname($ENVIRONMENT)[3]

def daemonize w
  exit! if fork
  Process.setsid
  exit! if fork
  $0 = w.name
  Dir.chdir '/'
  STDIN.reopen '/dev/null'
  STDOUT.reopen '/dev/null', 'a'
  STDERR.reopen '/dev/null', 'a'
  File.open(w.pid_file, 'w') { |f| f.write Process.pid }
  srand
end

def wait_pidfile pid_file
  c = 0
  until File.exists?(pid_file) or c > 10 do
    c = c + 1
    sleep 0.3
  end
end

def start_data w, port
  pid = fork do
    daemonize w
    $PORT = port
    $SERVER_ID = "data#{port}@#{$ENVIRONMENT}"
    require 'launchers/init'
  end
  # Process.setrlimit(:NOFILE, DATA_ULIMIT)
  Process.waitpid pid
  wait_pidfile w.pid_file

  # cmd = "ruby -C. -Ilib/boot -Iapp/data app/data/launchers/init.rb --environment #{$ENVIRONMENT} --port #{port}"
  # system(cmd)
end

def start_checker w, index
  pid = fork do
    daemonize w
    $SERVER_ID = "checker#{index}@#{$ENVIRONMENT}"
    $SERVER_INDEX = "#{index}"
    require 'launchers/checker'
  end
  Process.waitpid pid
  wait_pidfile w.pid_file

  # cmd = "ruby -C. -Ilib/boot -Iapp/data app/data/launchers/checker.rb --environment #{$ENVIRONMENT}"
  # system(cmd)
end

def ensure_running w, memory_max = 3500
  interval = 10.seconds

  w.start_grace = w.restart_grace = 30.seconds

  if false#God::EventHandler.loaded?
    w.transition(:init, { true => :up, false => :start }) do |on|
      on.condition(:process_running) do |c|
        c.interval = interval
        c.running = true
      end
    end

    w.transition([:start, :restart], :up) do |on|
      on.condition(:process_running) do |c|
        c.interval = interval
        c.running = true
      end
    end

    w.transition(:up, :start) do |on|
      on.condition(:process_exits) do |c|
      end
    end
  else
    w.start_if do |start|
      start.condition(:process_running) do |c|
        c.interval = interval
        c.running = false
      end
    end
  end

  w.restart_if do |restart|
    if memory_max and memory_max > 0
      restart.condition(:memory_usage) do |c|
        c.interval = interval
        c.above = memory_max.megabytes
        c.times = [3,5]
        c.notify = 'developers'
      end
    end

    if false
      restart.condition(:cpu_usage) do |c|
        c.interval = interval
        c.above = 100.percent
        c.times = [3,5]
        c.notify = 'developers'
      end
    end
  end

end

def ensure_stopped w
  w.stop_if do |stop|
    stop.condition(:process_running) do |c|
      c.interval = 5
      c.running = true
    end
    stop.condition(:tries) do |c|
      c.interval = 5
      c.times = 1
      c.transition = :init
    end
  end

  w.start = lambda { }
end

# setup contacts
God::Contacts::Email.defaults do |d|
  d.from_email = "god@#{`hostname`}"
  d.from_name = 'God'
  d.delivery_method = :sendmail
end

God.contact(:email) do |c|
  c.name = 'duwenjie'
  c.group = 'developers'
  c.to_email = 'dwjsx@163.com'
end

#monitor combat server
God.watch do |w|
  w.name = "#{APP}_combat"
  w.pid_file = File.join(PID_DIR, "skynet.pid")
  w.dir = COMBAT_DIR
  env = opts['environment'] 
  w.start = "./skynet ../../config/config.#{env}.combat && sleep 3"
  w.behavior(:clean_pid_file)
end

# monitoring data server
(START_PORT..END_PORT).each do |port|
God.watch do |w|[]
    w.group = "#{APP}_data"
    w.name = "#{APP}_#{port}"
    w.pid_file = File.join(PID_DIR, "#{w.name}.pid")
    w.env = { 'BUNDLE_GEMFILE' => "#{ROOT_DIR}/Gemfile" }
    w.stop_timeout = 30 # for saving player data

    w.start = lambda { start_data(w, port) }
    w.behavior(:clean_pid_file)

    port < START_PORT + opts['procs'] ? ensure_running(w) : ensure_stopped(w)
  end
end

# monitoring checker
(0..(opts['checkers'] - 1)).each do |index|
  God.watch do |w|
    w.group = "#{APP}_checker"
    w.name = "#{APP}_checker#{index}"
    w.pid_file = File.join(PID_DIR, "#{w.name}.pid")
    w.env = { 'BUNDLE_GEMFILE' => "#{ROOT_DIR}/Gemfile" }

    w.start = lambda { start_checker(w, index) }
    w.behavior(:clean_pid_file)

    opts['checker'] ? ensure_running(w) : ensure_stopped(w)
  end
end

# monitoring gm
God.watch do |w|
  w.name = "#{APP}_gm"
  w.pid_file = File.join(PID_DIR, "#{w.name}.pid")
  w.dir = GM_DIR
  w.env = { 'RAILS_ROOT' => GM_DIR, 'RAILS_ENV' => $ENVIRONMENT, 'BUNDLE_GEMFILE' => "#{ROOT_DIR}/Gemfile" }

  w.start = "rails server -d -P #{w.pid_file} -p #{GM_PORT} && sleep 3"
  w.behavior(:clean_pid_file)

  opts['gm'] ? ensure_running(w) : ensure_stopped(w)
end

# monitoring stats
God.watch do |w|
  w.name = "#{APP}_stats"
  w.pid_file = File.join(PID_DIR, "#{w.name}.pid")
  w.dir = STATS_DIR
  w.env = { 'RAILS_ROOT' => STATS_DIR, 'RAILS_ENV' => $ENVIRONMENT, 'BUNDLE_GEMFILE' => "#{ROOT_DIR}/Gemfile"}

  w.start = "rails server -d -P #{w.pid_file} -p #{STATS_PORT} && sleep 3"
  w.behavior(:clean_pid_file)

  opts['stats'] ? ensure_running(w) : ensure_stopped(w)
end

# monitoring payment
God.watch do |w|
  w.name = "#{APP}_payment"
  w.pid_file = File.join(PID_DIR, "#{w.name}.pid")
  w.dir = PAYMENT_DIR
  w.env = { 'RAILS_ROOT' => PAYMENT_DIR, 'RAILS_ENV' => $ENVIRONMENT, 'BUNDLE_GEMFILE' => "#{ROOT_DIR}/Gemfile" }

  w.start = "rails server -d -P #{w.pid_file} -p #{PAYMENT_PORT} && sleep 3"
  w.behavior(:clean_pid_file)

  opts['payment'] ? ensure_running(w) : ensure_stopped(w)
end
