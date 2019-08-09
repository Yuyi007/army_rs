# game_server_spec.rb

require_relative 'spec_helper'

SOCK_FILE = '/tmp/game_server_spec.sock'

class TestGameClient

  def initialize
    connect
    @number = 0
    @send_queue = []
    @recv_buf = ''
    @client_codec_state = CodecState.new
  end

  def connect
    @sock = UNIXSocket.new(SOCK_FILE)
    # don't want to block even once since this will run in the event loop
    @sock.setsockopt(Socket::SOL_SOCKET, Socket::SO_SNDBUF, 64 * 1024)
  end

  def queue_msg t, msg
    @number += 1

    packet = $boot_config.game_packet_format.new
    packet.n = @number
    packet.t = t
    packet.msg = msg

    codec_state = CodecState.new()
    @send_queue << [packet, codec_state]
  end

  def flush
    if @send_queue.length > 0
      str = @send_queue.inject('') do |str, item|
        packet = item[0]
        codec_state = item[1]
        (str + packet.to_wire(nil, codec_state))
      end
      @send_queue = []
      @sock.write str
    end
  end

  def receive
    @recv_buf += @sock.recv 64 * 1024
    packets = []
    while true
      packet = $boot_config.game_packet_format.new
      packet.parse! @recv_buf, @client_codec_state
      break if not (packet.complete?)
      packets << packet
    end
    packets
  end

  def close
    flush
    @sock.close
    @sock = nil
  end

end

describe 'the game server' do

  before(:all) do
  end

  after(:all) do
  end

  def start_server &blk
    stop = Proc.new do
      Thread.new do
        EM.stop
      end
    end

    Dir.chdir($boot_config.root_path)

    AppConfig.preload(ENV['USER'], nil)
    Loggable.set_suppress_logs()
    Statsable.init(AppConfig.statsd)

    EM.epoll
    EM.kqueue = true if EM.kqueue?
    EM.set_descriptor_table_size(32768)
    EM.set_max_timers(100000)
    Process.setrlimit(Process::RLIMIT_NOFILE, 4096)

    EM::Synchrony.init_fiber_pool

    EM.run do # run handles fork better than synchrony
      EM.synchrony do
        begin
          Signal.trap("INT") { stop.call }
          Signal.trap("TERM") { stop.call }

          SentinelFactory.init :within_event_loop => true, :with_channel => true
          RedisFactory.init :within_event_loop => true, :pool_size => 3, :timeout => 3
          RedisClusterFactory.init :within_event_loop => true, :pool_size => 3, :timeout => 3
          MysqlFactory.init :within_event_loop => true
          KyotoFactory.init :within_event_loop => true
          Pubsub.init :within_event_loop => true

          res = EventMachine::start_unix_domain_server SOCK_FILE, Boot::GameServer
          puts("test server started")

          yield
          EM::Synchrony.sleep 0.1

          stop.call
        rescue => e
          Log_.error("Loop Error: ", e)
          stop.call
          EM.next_tick { fail e.message }
        end
      end
    end

    puts("test server stopped")
  end

  def test_id i
    "spec_c#{i}"
  end

  it 'should process batch correctly' do
    packets1, packets2, packets3, packets4 = nil, nil, nil, nil
    model1, model2, model3, model4 = nil, nil, nil, nil

    start_server do
      # remove last spec run test game data
      (1..4).to_a.each { |i| GameData.delete(test_id(i), 1) }
      # remove last spec run cached data
      (1..4).each { |i| CachedGameData.force_delete_cache(test_id(i), 1) }

      Thread.new do
        puts "sending messages..."

        # all should succeed
        c1 = TestGameClient.new
        c1.queue_msg 1, { :id => test_id(1), :zone => 1 }
        c1.flush
        c1.queue_msg 2, { :id => 'a1', :name => 'XCode 5' }
        c1.queue_msg 2, { :id => 'a2', :name => 'XCode 6' }
        c1.queue_msg 2, { :id => 'a3', :name => 'iMovie' }
        c1.flush
        c1.queue_msg 3, { :id => 'a1' }
        c1.flush
        packets1 = c1.receive
        c1.close

        # all should succeed
        c2 = TestGameClient.new
        c2.queue_msg 1, { :id => test_id(2), :zone => 1 }
        c2.flush
        c2.queue_msg 5, { :name => 'redis' }
        c2.queue_msg 5, { :name => 'redis2' }
        c2.queue_msg 5, { :name => 'mysql' }
        c2.queue_msg 5, { :name => 'riak' }
        c2.queue_msg 5, { :name => 'sqlite' }
        c2.queue_msg 6, { :name => 'mysql' }
        c2.flush
        packets2 = c2.receive
        c2.close

        # all should fail because id a1 exists
        c3 = TestGameClient.new
        c3.queue_msg 1, { :id => test_id(3), :zone => 1 }
        c3.queue_msg 2, { :id => 'a1', :name => 'XCode 5' }
        c3.queue_msg 2, { :id => 'a1', :name => 'XCode 5' }
        c3.queue_msg 2, { :id => 'a4', :name => 'iTunes' }
        c3.flush
        packets3 = c3.receive
        c3.close

        # all should fail because UpgradeCpu should have a exception
        c4 = TestGameClient.new
        c4.queue_msg 1, { :id => test_id(4), :zone => 1 }
        c4.flush
        c4.queue_msg 2, { :id => 'a4', :name => 'iTunes' }
        c4.queue_msg 4, {}
        c4.flush
        packets4 = c4.receive
        c4.close

        # EM::Synchrony.sleep 1.0

        puts "sending messages done"
      end
    end

    puts "checking server responses"

    # the responses num should be the same with requests
    packets1.length.should eql 5
    packets2.length.should eql 7
    packets3.length.should eql 4
    packets4.length.should eql 3

    # all should be processed in order (n == i + 1)

    # all should succeed
    packets1.each_with_index do |packet, i|
      packet.n.should eql i + 1
      packet.msg['success'].should eql true
    end
    packets2.each_with_index do |packet, i|
      packet.n.should eql i + 1
      packet.msg['success'].should eql true
    end

    # all in the second batch should fail, except for the first login packet
    packets3.each_with_index do |packet, i|
      packet.n.should eql i + 1
      packet.msg['success'].should eql false if i > 1
    end
    packets4.each_with_index do |packet, i|
      packet.n.should eql i + 1
      packet.msg['success'].should eql false if i > 1
    end

    # c3 and c4 game data should not be changed
    RedisFactory.fini
    RedisFactory.init_failsafe
    RedisClusterFactory.init_failsafe
    model3 = GameData.read(test_id(3), 1)
    model3.applications.length.should eql 0
    model4 = GameData.read(test_id(4), 1)
    model4.applications.length.should eql 0
  end

end