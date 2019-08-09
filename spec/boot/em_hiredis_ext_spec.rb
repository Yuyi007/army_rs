# em_hiredis_ext_spec.rb

require_relative 'spec_helper'

describe EventMachine::Hiredis do

  EM::Synchrony.init_fiber_pool

  before do
    @key = 'em_hiredis_ext_spec_key'
  end

  it 'should handle reconnect' do
    counters = [ 0, 0 ]

    EM.synchrony do
      begin
        redis = EM::Hiredis.connect("redis://127.0.0.1:6379")
        redis.on(:connected) do |fail_count|
          puts "redis connected"
          counters[0] += 1
        end
        redis.pubsub.on(:connected) do |fail_count|
          puts "redis pubsub connected"
          counters[1] += 1
        end

        redis.set @key, 0
        redis.del @key

        EM::Hiredis.reconnect_timeout = 0.001
        redis.reconnect!
        redis.pubsub.reconnect!

        EM::Synchrony.sleep 0.1
      ensure
        EM.stop
        counters[0].should eql 2
        counters[1].should eql 2
      end
    end
  end

end