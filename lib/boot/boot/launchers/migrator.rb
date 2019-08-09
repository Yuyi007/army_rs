# migrator.rb
#
# migrator entry file
#

require 'boot'

options = { :timeout => 120.0, :pool_size => 10, :max_timers => 500000 }
optparse = OptionParser.new do |opts|
  opts.banner = "Usage: migrator.rb [options]"
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
end.parse!

Boot::AppConfig.preload(options[:environment], options[:base_path])
Boot::AppConfig.override(options)
Boot::RedisMigrateDb.instance.do_migrate