

RS_PATH = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', ''))
LIB_PATH = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'lib/boot'))
DATA_PATH = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'app/data/'))

$LOAD_PATH.unshift(RS_PATH)
$LOAD_PATH.unshift(DATA_PATH)
$LOAD_PATH.unshift(LIB_PATH)

require 'rs'
require_relative '../boot/spec_helper'

Statsable.init(AppConfig.statsd)

RedisClusterFactory.init :within_event_loop => false, :pool_size => 3, :timeout => 3
RedisFactory.init :within_event_loop => false, :pool_size => 3, :timeout => 3

GameConfig.preload(RS_PATH)