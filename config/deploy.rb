# config valid only for Capistrano 3.1

if ENV['log_level']
  set :log_level, ENV['log_level'].to_sym
end

APP = 'rs'
GOD_PORT = 17670
CURRENT_VER = '0.0.1'
UPGRADE_VER = '0.0.2'

set :application, APP
set :ssh_options, {
  user: 'jenkins',
  port: fetch(:ssh_port, 22),
}

# paths
set :deploy_to, "/usr/local/#{APP}"
set :app_path, deploy_path
set :app_config_path, deploy_to + '/config'
set :gm_path, deploy_path.join('app', 'gm')
set :stats_path, deploy_path.join('app', 'stat')
set :payment_path, deploy_path.join('app', 'payment')
set :pid_path, deploy_path.join('pids')

def with_rvm(path, version = 'default'); "/usr/bin/env rvm #{version} do #{path}"; end
def check_proc_just_started(name); "ps -o 'cputime=' `/sbin/pidof #{name}` | grep 00:00:0 > /dev/null 2>&1"; end
def wait_for(cmd, timeout = 120); "C=0; until #{cmd} || [ $C -gt #{timeout/3} ]; do C=$((C+1)); sleep 3 ; done"; end
# commands
SSHKit.config.command_map[:bundle] = with_rvm 'bundle'
SSHKit.config.command_map[:god] = with_rvm "god -p #{GOD_PORT}"
SSHKit.config.command_map[:check_god_started] = 'ps aux | grep [g]od && ' + with_rvm("god -p #{GOD_PORT} status")
SSHKit.config.command_map[:wait_god_start] = wait_for SSHKit.config.command_map[:check_god_started]
SSHKit.config.command_map[:check_pids] = "bin/check_pids.sh '" + fetch(:pid_path).to_s + "'"
SSHKit.config.command_map[:check_god_status] = '! ' + with_rvm("god -p #{GOD_PORT} status | egrep '(down|unmonitored)'")
SSHKit.config.command_map[:remove_c_sources] = "find lib -name '*.c' -o -name '*.cpp' | xargs rm -f"
SSHKit.config.command_map[:compile_skynet] = "if [[ ! -f lib/skynet/skynet ]]; then cd lib/skynet && make linux; fi;"

namespace :deploy do

  ########################################
  # Starting

  desc 'Start update'
  task :starting do
  end

  ########################################
  # Updating

  desc 'Do update'
  task :updating do
    invoke('deploy:remove_previous_version')
    invoke('deploy:update_code')
    invoke('deploy:update_game_config')
    invoke('deploy:gen_server_list')
  end

  desc 'Remove previous version, this speed up rsync'
  task :remove_previous_version do
    on roles(:all), in: :parallel do |host|
      within fetch(:deploy_to) do
        execute "rm -rf app/gm/tmp/ app/gm/log/ app/payment/tmp/"
      end
    end
  end

  desc 'Update codes to all servers'
  task :update_code do
    on roles(:all), in: :parallel do |host|
      run_locally do
        within "'" + File.expand_path(File.join(File.dirname(__FILE__), '..')) + "'" do
          user = fetch(:ssh_options)[:user]
          port = fetch(:ssh_port, 22)
          env = host.fetch(:env)
          execute :rsync, %Q{-racz -e 'ssh -p #{port}' \
            --include '/bin/check_pids.sh' \
            --include '/bin/loadtest.sh' \
            --include '/bin/delete_loadtest_users.rb' \
            --include '/rel/config.exs' \
            --include '/rel/vm.args.eex' \
            --include '/config/process.rb' \
            --include '/config/schedule.rb' \
            --include '/game-config/strings.json' \
            --include '/game-config/strings_loc.json' \
            --include '/game-config/config.json' \
            --include '/game-config/cdkeys.json' \
            --include '/client/scripts/game/proto.lua' \
            --exclude '.git/' \
            --exclude '.bundle/' \
            --exclude '/_build/' \
            --exclude 'log/' \
            --exclude 'temp/' \
            --exclude 'certs/' \
            --exclude 'redis-cluster/' \
            --exclude '/misc/' \
            --exclude '/legacy/' \
            --exclude '/client/*.lua' \
            --exclude '/client/*squish*' \
            --exclude '/client/scripts/*' \
            --exclude '/pids/' \
            --exclude '/loc/' \
            --exclude '/bin/*' \
            --exclude '/rel/*' \
            --exclude '/priv/*' \
            --exclude '/config/*' \
            --exclude '/templates/*' \
            --exclude 'game-config/*' \
            --exclude 'game-config-fix/' \
            --exclude 'game-config-processed/' \
            --exclude 'app/gm/log/' \
            --exclude 'app/gm/tmp/' \
            --exclude 'app/gm/db/*.sqlite3' \
            --exclude 'app/gm/config/database.yml' \
            --exclude 'app/gm/environments/*.rb' \
            --exclude 'app/payment/log/' \
            --exclude 'app/payment/tmp/' \
            --exclude 'app/payment/db/*.sqlite3' \
            --exclude 'app/payment/config/database.yml' \
            --exclude 'app/payment/environments/*.rb' \
            --exclude 'app/stat/log/' \
            --exclude 'app/stat/tmp/' \
            --exclude 'app/stat/db/*.sqlite3' \
            --exclude 'app/stat/config/database.yml' \
            --exclude 'app/stat/environments/*.rb' \
            --exclude '.DS_Store' \
            --exclude 'Capfile' \
            --exclude '/.gitignore' \
            --exclude '/README.md' \
            --exclude '/gameDataStrings.json' \
            --exclude '/gameDataStrings.xls' \
            --exclude '/*.sh' \
            --exclude '/*.out' \
            --exclude '/*.txt' \
            --exclude '/*.dot' \
            --exclude '/*.png' \
            --exclude '/*.svg' \
            --exclude '/*.json' \
            --exclude '*.iml' \
            --exclude '*.pid' \
            --exclude '*.log' \
            --exclude '*.csv' \
            --exclude '*.xls' \
            --exclude '*.rdb' \
            --exclude '*.dump' \
            --exclude '*.beam' \
            --exclude '*.app' \
            --exclude '*.proto' \
            --exclude '*.o' \
            --exclude '*.so' \
            --exclude 'lib/skynet/skynet' \
            --exclude 'god.*' \
            --exclude 'fprof.*' \
            ./ #{user}@#{host.hostname}:#{deploy_path}/
          }

        end
      end
    end
  end

  desc 'Generate server list'
  task :gen_server_list do
    data = {
      'combat_servers' => [],
      'data_servers' => [],
      'checker_servers' => [],
      'stats_servers' => []
    }
    environment = fetch(:environment)
    roles(:data).each do |host|
      env = host.fetch(:env)
      local_ip = host.fetch(:ip) || host.hostname
      procs = host.fetch(:procs) || 0
      (1..procs).each do |idx|
        port = 5082 + idx - 1
        data['data_servers'] << {
          'name' => "data#{port}@#{env}",
          'addr' => "#{local_ip}:#{port}",
          'type' => 'tcp',
          'check' => '5s',
        }
      end
    end

    roles(:combat).each do |host|
      data['combat_servers'] << host.fetch(:env)
    end

    roles(:checker).each do |host|
      env = host.fetch(:env)
      checkers = host.fetch(:checkers) || 0
      (1..checkers).each do |idx|
        data['checker_servers'] << {
          'name' => "checker#{idx-1}@#{env}",
        }
      end
    end

    roles(:stats).each do |host|
      data['stats_servers'] << host.fetch(:env)
    end

    require 'json'
    tmp_file = '/tmp/server_list.json'
    File.write(tmp_file, JSON.pretty_generate(data))

    on roles(:all), in: :parallel do |host|
      upload! tmp_file, "#{fetch(:app_path)}/config/server_list.json"
    end
    File.delete(tmp_file)
  end

  desc 'Update game configs to all servers'
  task :update_game_config do
    config_scheme = fetch(:game_config_scheme, 'default')
    if config_scheme != 'default'
      config_json = "operation/#{config_scheme}/config.json"
      if File.exist?(config_json)
        on roles(:all), in: :parallel do |host|
          run_locally do
            within "'" + File.expand_path(File.join(File.dirname(__FILE__), '..')) + "'" do
              user = fetch(:ssh_options)[:user]
              port = fetch(:ssh_port, 22)
              env = host.fetch(:env)
              execute :rsync, %Q{-acvz -e 'ssh -p #{port}' \
                #{config_json} #{user}@#{host.hostname}:#{deploy_path}/game-config/
              }
            end
          end
        end
      end
    end
  end

  def update_rails_config(src, dst, env, mysql_host = 'localhost')
    execute "mkdir -p #{dst}/environments"

    if File.exists?("#{src}/environments/#{env}.rb")
      upload! "#{src}/environments/#{env}.rb", "#{dst}/environments/#{env}.rb"
    else
      system("sed -e 's/\\*ENVIRONMENT\\*/#{env}/g' #{src}/environments/common.rb > /tmp/#{env}.rb")
      upload! "/tmp/#{env}.rb", "#{dst}/environments/#{env}.rb"
    end

    if File.exists?("#{src}/database.#{env}.yml")
      upload! "#{src}/database.#{env}.yml", "#{dst}/database.yml"
    else
      system("sed -e 's/\\*ENVIRONMENT\\*/#{env}/g' #{src}/database.common.yml > /tmp/temp_#{env}.yml")
      system("sed -e 's/localhost/#{mysql_host}/g' /tmp/temp_#{env}.yml > /tmp/#{env}.yml")
      upload! "/tmp/#{env}.yml", "#{dst}/database.yml"
    end
  end

  desc 'Update configs to all servers'
  task :update_config do
    config_path = ENV['CONFIG_PATH'] || "../pp/modules/#{APP}/files/#{APP}"
    if File.directory?(config_path)
      on roles(:all), in: :parallel do |host|
        # env = host.fetch(:env)
        environment = fetch(:environment)
        src = "#{config_path}/config/common"
        dst = "#{fetch(:app_path)}/config"
        execute "mkdir -p #{dst}"
        upload! "#{src}/config.#{environment}.exs", "#{dst}/config.exs" if File.exists? "#{src}/config.#{environment}.exs"
      end
      on roles(:gm), in: :parallel do |host|
        env = host.fetch(:env)
        src = "#{config_path}/lib/gm/config"
        dst = "#{fetch(:gm_path)}/config"
        update_rails_config(src, dst, env)
      end

      on roles(:stats), in: :parallel do |host|
        env = host.fetch(:env)
        host = fetch(:stats_host)
        src = "#{config_path}/lib/stat/config"
        dst = "#{fetch(:stats_path)}/config"
        update_rails_config(src, dst, env, host)
      end

      on roles(:payment), in: :parallel do |host|
        env = host.fetch(:env)
        src = "#{config_path}/lib/payment/config"
        dst = "#{fetch(:payment_path)}/config"
        update_rails_config(src, dst, env)
      end
    end
  end

  ########################################
  # Publishing

  desc 'Publishing update'
  task :publishing do
    invoke('deploy:compile')
    invoke('deploy:bundle')
    invoke('deploy:update_log_crontabs')
    invoke('deploy:update_gm_crontabs')
    invoke('deploy:migrate_gm_db')
    invoke('deploy:migrate_stats_db')
  end

  desc 'Update crontabs for server log'
  task :update_log_crontabs do 
    on roles(:combat), in: :parallel do |host|
      within fetch(:deploy_to) do
        execute :bundle, 'exec whenever --update-crontab'
      end
    end
  end

  desc 'Compile skynet'
  task :compile do 
    on roles(:combat), in: :parallel do |host|
      within fetch(:deploy_to) do
        execute :compile_skynet
      end
    end
  end

  desc 'Execute bundle install for the app'
  task :bundle do
    on roles(:all), in: :parallel do |host|
      within fetch(:app_path) do
        execute :bundle, 'install --local --without profile'
      end
    end
  end

  desc 'Update crontabs for gm'
  task :update_gm_crontabs do
    on roles(:gm), in: :sequence do |host|
      within fetch(:gm_path) do
        with RAILS_ENV: host.fetch(:env) do
          execute :bundle, 'exec whenever --update-crontab'
        end
      end
    end
  end

  desc 'Execute rake db:migrate for gm'
  task :migrate_gm_db do
    on roles(:gm), in: :sequence do |host|
      within fetch(:gm_path) do
        with RAILS_ENV: host.fetch(:env) do
          execute :bundle, 'exec rake db:migrate'
        end
      end
    end
  end

  desc 'Execute rake db:reset for gm [DANGEROUS!!!]'
  task :reset_gm_db do
    on roles(:gm), in: :sequence do |host|
      within fetch(:gm_path) do
        with RAILS_ENV: host.fetch(:env) do
          execute :bundle, 'exec rake db:reset'
        end
      end
    end
  end

  desc 'Execute rake db:migrate for stats'
  task :migrate_stats_db do
    on roles(:stats), in: :sequence do |host|
      within fetch(:stats_path) do
        with RAILS_ENV: host.fetch(:env) do
          execute :bundle, 'exec rake db:migrate'
        end
      end
    end
  end

  desc 'Execute rake db:reset for stats [DANGEROUS!!!]'
  task :reset_stats_db do
    on roles(:stats), in: :sequence do |host|
      within fetch(:stats_path) do
        with RAILS_ENV: host.fetch(:env) do
          execute :bundle, 'exec rake db:reset'
        end
      end
    end
  end

  desc 'Execute rake db:migrate for payment'
  task :migrate_payment_db do
    on roles(:payment), in: :sequence do |host|
      within fetch(:payment_path) do
        with RAILS_ENV: host.fetch(:env) do
          execute :bundle, 'exec rake db:migrate'
        end
      end
    end
  end

  desc 'Execute rake db:reset for payment [DANGEROUS!!!]'
  task :reset_payment_db do
    on roles(:payment), in: :sequence do |host|
      within fetch(:payment_path) do
        with RAILS_ENV: host.fetch(:env) do
          execute :bundle, 'exec rake db:reset'
        end
      end
    end
  end

  ########################################
  # Finishing

  desc 'Finishing update, currently do nothing'
  task :finishing do
  end

  ########################################
  # Restarting

  desc 'Restart all services, using god'
  task :restart do
    invoke('god:stop_god')
    invoke('god:start_god')
    invoke('god:restart_checker')
    invoke('god:restart_data')
    invoke('god:restart_combat')
    invoke('god:restart_gm')
    invoke('god:restart_stats')
    invoke('god:restart_payment')
    invoke('god:check_pids')
  end

  after :publishing, :restart

  after :restart, :clear_cache do
    on roles(:data), in: :groups, limit: 3, wait: 10 do |host|
    end
  end

end

namespace :upgrade do

  ########################################
  # Hot Upgrade

  desc 'Publishing hot upgrades'
  task :hot_upgrade do
    invoke('deploy:update_code')
    # invoke('deploy:update_game_config')

    # invoke('deploy:compile_deps')
  end

end

namespace :god do

  desc 'Stop god'
  task :stop_god do
    on roles(:all), in: :parallel do |host|
      execute :god, 'quit' if test :check_god_started
    end
  end

  desc 'Start god'
  task :start_god do
    on roles(:all), in: :parallel do |host|
      within fetch(:app_path) do
        with ENVIRONMENT: host.fetch(:env),
          PROCS: host.fetch(:procs),
          CHECKER: host.has_role?(:checker),
          CHECKERS: host.fetch(:checkers),
          COMBAT: host.has_role?(:combat),
          GM: host.has_role?(:gm),
          STATS: host.has_role?(:stats),
          PAYMENT: host.has_role?(:payment) do
          execute :mkdir, "-p #{fetch(:pid_path)}"
          execute :god, '-c config/process.rb -l god.log -V --no-syslog --log-level info'
          execute :wait_god_start
        end
      end
    end
  end

  desc 'Restart data'
  task :restart_data do
    on roles(:data), in: :groups, limit: 12 do |host|
      execute :god, "restart #{APP}_data"
    end
  end

  desc 'Restart combat'
  task :restart_combat do 
    on roles(:combat) do |host|
      execute :god, "restart #{APP}_combat"
    end
  end

  desc 'Restart checker'
  task :restart_checker do
    on roles(:checker), in: :groups, limit: 12 do |host|
      execute :god, "restart #{APP}_checker"
    end
  end

  desc 'Restart gm'
  task :restart_gm do
    on roles(:gm), in: :parallel do |host|
      execute :god, "restart #{APP}_gm"
    end
  end

  desc 'Restart stats'
  task :restart_stats do
    on roles(:stats), in: :parallel do |host|
      execute :god, "restart #{APP}_stats"
    end
  end

  desc 'Restart payment'
  task :restart_payment do
    on roles(:payment), in: :parallel do |host|
      execute :god, "restart #{APP}_payment"
    end
  end

  desc 'Check all restarts successfull'
  task :check_pids do
    on roles(:all), in: :parallel do |host|
      within fetch(:app_path) do
        execute :check_pids
        execute :check_god_status
      end
    end
  end

end

