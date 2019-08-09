# prefork.rb
#
# prefork actions to utilize linux copy-on-write on fork
#

require 'boot'

Dir.chdir(File.expand_path(File.dirname(__FILE__) + '/../../..'))

AppConfig.preload($ENVIRONMENT)
Loggable.set_suppress_logs()

$boot_config.server_delegate.on_server_prefork

EM.epoll
EM.kqueue = true if EM.kqueue?

EM.set_descriptor_table_size(32768)
EM.set_max_timers(100000) unless EM.reactor_running?

EM::Synchrony.init_fiber_pool
