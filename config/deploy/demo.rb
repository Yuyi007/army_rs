set :environment, 'demo'
server '106.15.198.248', env: :demo, roles: [ :data, :checker, :gm, :combat], procs: 1, checkers: 1