# game_server_queue_spec.rb

require_relative 'spec_helper'

SOCK_FILE = '/tmp/game_server_queue_spec.sock'

class TestGameServer < EventMachine::Connection

  include Loggable

  attr_reader :id

  @@servers = []

  def self.should_process_all_events
    # check all events are processed
    @@servers.each { |server| server.should_process_all_events }
  end

  def initialize
    @@servers << self
    @id = @@servers.length
    @event_counter = 0
    @executed_counters = {}
    @queue = ServerQueue.new
  end

  def post_init
    queue_event { do_event 'post_init' }
  end

  def unbind
    queue_event { do_event 'unbind' }
  end

  def receive_data data
    queue_event { do_event "receive_data #{data.length}"; send_data data }
  end

  def queue_event &blk
    @event_counter += 1
    counter = @event_counter
    @queue.submit do
      yield
      # check the event are processed in order
      @executed_counters.each { |k, _| EM.next_tick { k.should < counter } }
      @executed_counters[counter] = true
    end
  end

  def should_process_all_events
    # check all events are processed
    @event_counter.should == @executed_counters.size
  end

  # simulate the event
  def do_event name
    # puts "[#{@id}] #{name} start"
    v = rand
    if v > 0.5
      wait_sec = 0.01 * v
      # puts "[#{@id}] #{name} #{wait_sec}"
      EM::Synchrony.sleep wait_sec
    else
      # puts "[#{@id}] #{name} 0"
    end
    # puts "[#{@id}] #{name} end"
  end

end

class TestGameClient

  def initialize
    connect
  end

  def connect
    @sock = UNIXSocket.new(SOCK_FILE)
    # don't want to block even once since this will run in the event loop
    @sock.setsockopt(Socket::SOL_SOCKET, Socket::SO_SNDBUF, 64 * 1024)
  end

  def send_msg msg
    @sock.puts msg
  end

  def close
    @sock.close
    @sock = nil
  end

end

describe 'the game server queue' do

  def start_server &blk
    stop = Proc.new do
      Thread.new do
        EM.stop
      end
    end

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

          res = EventMachine::start_unix_domain_server SOCK_FILE, TestGameServer
          puts("test server started")

          yield
          EM::Synchrony.sleep 0.5

          TestGameServer.should_process_all_events
          stop.call
        rescue => e
          puts("Loop Error: ", e)
          stop.call
          EM.next_tick { fail e.message }
        end
      end
    end

    puts("test server stopped")
  end

  it 'should send msg and process all events in order' do
    start_server do
      puts "sending messages..."
      (0..100).each do |_|
        c1 = TestGameClient.new
        (0..1000).each { c1.send_msg 'hello' * 5 }
        (0..1000).each { c1.send_msg 'world' * 4 }
        c1.send_msg 'watermelon' * 5
        c1.send_msg 'bananas' * 4
        c1.close

        c2 = TestGameClient.new
        c2.send_msg 'hello2' * 5
        c2.send_msg 'world2' * 4
        c2.close

        EM::Synchrony.sleep 0.001
      end
      puts "sending messages done"
    end
  end

end