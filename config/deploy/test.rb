set :environment, 'test'
set :base_config_name, 'test'
server '127.0.0.1', env: :test52, roles: [ :data, :checker, :gm, :combat], procs: 1, checkers: 3
server '127.0.0.1', env: :test53, roles: [ :data, :checker, :combat], procs: 3, checkers: 3