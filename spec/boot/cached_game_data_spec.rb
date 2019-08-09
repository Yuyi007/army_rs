# cached_game_data_spec.rb

require_relative 'spec_helper'

describe 'when using game data' do

  class ModifyModelNameJob < CachedGameDataJob

    def self.perform(id, zone, model, arg1, arg2)
      model.name = "#{arg1}#{arg2}"
      Boot::ReadCachedGameDataJob.perform(id, zone, model)
    end

  end

  class ModelNamePlusOneJob < CachedGameDataJob

    def self.perform(id, zone, model)
      model.name += 1
    end

  end

  class ModelNameSetJob < CachedGameDataJob

    def self.perform(id, zone, model)
      model.name = 1984
    end

  end

  AppConfig.preload(ENV['USER'], nil)
  Statsable.init(AppConfig.statsd)

  before(:all) do
    @id = 1984
    @zone = 1
    @redis = Redis.new
    @lock_options = {:max_retry => 1, :retry_wait_time => 1.0,
      :lock_timeout => 0.5, :sane_expiry => 0.5, :expiry_grace => 0}

    RedisRpc.init(@redis, :poll_interval => 0.01,
      :call_timeout => 0.1, :max_queue_length => 5)

    GameData.redis = @redis
    CachedGameData.instance.redis = @redis
    CachedGameData.instance.lock_options = @lock_options
    CachedGameData.instance.mutex_try_limit = 8

    @cache1 = CachedGameData::CachedGameDataComp.new :my_id => 'test-id1',
      :redis => @redis, :lock_options => @lock_options,
      :put_back_all_interval => 0.01, :mutex_try_limit => 8
    @cache2 = CachedGameData::CachedGameDataComp.new :my_id => 'test-id2',
      :redis => @redis, :lock_options => @lock_options,
      :put_back_all_interval => 0.01, :mutex_try_limit => 8

    GameData.delete(@id, @zone)
    CachedGameData.force_delete_cache(@id, @zone)
    @cache1.force_delete_cache(@id, @zone, false)
  end

  after(:all) do
    puts "cleaning up RedisRpc and CachedGameData..."
    CachedGameData.instance.redis = nil
    RedisRpc.worker.clear(true)
    RedisRpc.destroy(@redis)
  end

  before :example do |x|
    puts "-------------- In Spec #{x.metadata[:description]} --------------"
  end

  it 'should take' do
    CachedGameData.take(@id, @zone) do |id, zone, model|
      id.should eql @id
      zone.should eql @zone
      model.should_not eql nil
    end
    CachedGameData.put_back(@id, @zone)
  end

  it 'should take successively' do
    counter = 0

    CachedGameData.take(@id, @zone) { |id, zone, model| counter += 1 }
    CachedGameData.take(@id, @zone) { |id, zone, model| counter += 1 }
    CachedGameData.put_back(@id, @zone)
    CachedGameData.take(@id, @zone) { |id, zone, model| counter += 1 }

    counter.should eql 3
  end

  it 'should not take in take, should take_or_ask_no_lock' do
    counter = 0

    CachedGameData.take(@id, @zone) do |id, zone, model|
      counter += 1
      lambda {
        CachedGameData.take(@id, @zone) { |_, _, _| counter += 1 }
      }.should raise_error /lock_mutex failed/

      CachedGameData.take_or_ask_no_lock(@id, @zone, ModelNameSetJob)
      model.name.should eql 1984
    end

    CachedGameData.delete_cache(@id, @zone)
    counter.should eql 1
  end

  it 'should raise error when a different instance has taken' do
    counter = 0

    CachedGameData.take(@id, @zone) { |_, _, _| counter += 1 }

    lambda { @cache1.take(@id, @zone, false) { |_, _, _| counter += 1 }
      }.should raise_error /already cached by/

    CachedGameData.take(@id, @zone) { |_, _, _| counter += 1 }

    counter.should eql 2
  end

  it 'should raise error when take or ask invalid id or zone' do
    [[nil, 1], ['$noauth$', 1], [-2, 0]].each do |id_zone|
      id, zone = *id_zone
      lambda { CachedGameData.take(id, zone) {|_, _, _|}
        }.should raise_error /invalid id zone/
      lambda { CachedGameData.ask(id, zone, Boot::ReadCachedGameDataJob)
        }.should raise_error /invalid id zone/
    end
  end

  it 'should raise error when take timeouts' do
    counter = 0

    CachedGameData.take(@id, @zone) { |id, zone, model| counter += 1 }
    Kernel.sleep CachedGameData.instance.lock_options[:lock_timeout]

    lambda { CachedGameData.take(@id, @zone) { |id, zone, model| counter += 1 }
      }.should raise_error /is invalid now/

    counter.should eql 1
  end

  it 'should raise error when processing in take timeouts' do
    counter = 0

    lambda do
      CachedGameData.take(@id, @zone) do |id, zone, model|
        Kernel.sleep CachedGameData.instance.lock_options[:lock_timeout]
        counter += 1
      end
    end.should raise_error /expired/

    counter.should eql 1
  end

  it 'should delete cache' do
    CachedGameData.delete_cache(@id, @zone)

    CachedGameData.delete_cache(@id, @zone).should be_falsey
    CachedGameData.take(@id, @zone) { |id, zone, model| model }
    CachedGameData.delete_cache(@id, @zone).should be_truthy

    CachedGameData.take(@id, @zone) { |id, zone, model|
      lambda {
        CachedGameData.delete_cache(@id, @zone)
      }.should raise_error /lock_mutex failed/
      CachedGameData.delete_cache(@id, @zone, true).should be_truthy
    }
  end

  it 'should put_back' do
    CachedGameData.has_cache?(@id, @zone).should be_falsey
    CachedGameData.cache_size().should eql 0

    CachedGameData.take(@id, @zone) { |id, zone, model| model }
    CachedGameData.has_cache?(@id, @zone).should be_truthy
    CachedGameData.cache_size().should eql 1

    CachedGameData.put_back(@id, @zone)
    CachedGameData.has_cache?(@id, @zone).should be_falsey
    CachedGameData.cache_size().should eql 0
  end

  it 'should put_back_all' do
    puts "first put_back_all should be 0/0..."
    CachedGameData.put_back_all().should eql 0

    puts "take data now"
    CachedGameData.take(@id, @zone) { |id, zone, model| model }

    puts "second put_back_all should be 1/1..."
    CachedGameData.put_back_all().should eql 1
  end

  it 'should not put_back in take' do
    counter = 0
    CachedGameData.take(@id, @zone) do |id, zone, model|
      counter += 1
      lambda {
        CachedGameData.put_back(@id, @zone)
      }.should raise_error /lock_mutex failed/
    end
    CachedGameData.delete_cache(@id, @zone)
    counter.should eql 1
  end

  it 'should renew' do
    CachedGameData.instance.renew(@id, @zone, false).should eql false
    CachedGameData.take(@id, @zone) do |id, zone, model|
    end
    CachedGameData.instance.renew(@id, @zone, false).should eql true
    CachedGameData.put_back(@id, @zone)
    CachedGameData.instance.renew(@id, @zone, false).should eql false
  end

  it 'should take and put_back concurrently' do
    n = 50
    counter = 0

    t1 = Thread.new do
      (1..n).each do |_|
        CachedGameData.take(@id, @zone) do
          counter += 1
          CachedGameData.has_cache?(@id, @zone).should eql true
          Kernel.sleep(rand() * 0.05)
          CachedGameData.has_cache?(@id, @zone).should eql true
          CachedGameData.delete_cache(@id, @zone, true)
          CachedGameData.has_cache?(@id, @zone).should eql false
        end
      end
    end

    t2 = Thread.new do
      (1..n).each do |_|
        counter += 1
        CachedGameData.put_back(@id, @zone)
      end
    end

    t3 = Thread.new do
      (1..n).each do |_|
        CachedGameData.put_back_all()
      end
    end

    t1.join
    t2.join
    t3.join
    counter.should eql n * 2
  end

  it 'should run work loop and shutdown' do
    work_loop_thread = Thread.new do
      CachedGameData.work_loop
    end

    CachedGameData.shutdown?.should be_falsey
    CachedGameData.shutdown!
    CachedGameData.shutdown?.should be_truthy

    work_loop_thread.join
  end

  it 'put_to_db should raise error when put_back but model was deleted' do
    CachedGameData.take(@id, @zone) { |id, zone, model| GameData.delete(@id, @zone) }
    CachedGameData.ensure_cache_deleted(@id, @zone) do |_, _, model|
      lambda { CachedGameData.instance.put_to_db(@id, @zone, model)
        }.should raise_error /was deleted/
    end
  end

  it 'put_to_db should raise error when put_back but model version is older' do
    CachedGameData.take(@id, @zone) { |id, zone, model| model.version = -1 }
    CachedGameData.ensure_cache_deleted(@id, @zone) do |_, _, model|
      lambda { CachedGameData.instance.put_to_db(@id, @zone, model)
        }.should raise_error /is older than/
    end
  end

  it 'should take_or_ask after take' do
    counter = 0

    CachedGameData.take(@id, @zone) { |_, _, _| counter += 1 }
    CachedGameData.take_or_ask(@id, @zone, Boot::ReadCachedGameDataJob).should_not eql nil

    counter.should eql 1
  end

  it 'should take_or_ask' do
    CachedGameData.delete_cache(@id, @zone)
    CachedGameData.take_or_ask(@id, @zone, Boot::ReadCachedGameDataJob).should_not eql nil
  end

  it 'should raise error when take then ask' do
    counter = 0

    CachedGameData.take(@id, @zone) { |_, _, _| counter += 1 }
    lambda { CachedGameData.ask(@id, @zone, Boot::ReadCachedGameDataJob)
      }.should raise_error /cached by myself/

    counter.should eql 1
  end

  it 'should ask when no one took' do
    CachedGameData.put_back(@id, @zone).should be_truthy
    CachedGameData.ask(@id, @zone, Boot::ReadCachedGameDataJob).should_not eql nil
  end

  it 'should ask when a different instance has taken' do
    counter = 0

    RedisRpc.worker.dequeue_count = 0
    rpc_worker_thread = Thread.new do
      RedisRpc.worker.work_loop do |job, res|
        count = RedisRpc.worker.dequeue_count
        puts "rpc.worker: count=#{count} job=#{job}"
        case count
        when 2
          RedisRpc.worker.shutdown
        end
      end
    end

    CachedGameData.take(@id, @zone) do |_, _, model|
      counter += 1
      model.name.should eql nil
    end

    model_hash = @cache1.ask(@id, @zone, ModifyModelNameJob, false, "name", "_mod")
    model = ComputerHashStorable.new.from_hash! model_hash
    model.name.should eql 'name_mod'

    CachedGameData.put_back(@id, @zone)
    CachedGameData.take(@id, @zone) do |_, _, model|
      counter += 1
      model.name.should eql 'name_mod'
    end

    counter.should eql 2

    RedisRpc.worker.shutdown
    rpc_worker_thread.join
  end

  it 'should handle different instances concurrent take' do
    counter = 0

    # access thread 1
    t1 = Thread.new do
      CachedGameData.take(@id, @zone) { |_, _, model| counter += 1 } rescue nil
    end

    # access thread 2
    t2 = Thread.new do
      @cache1.take(@id, @zone) { |_, _, model| counter += 1 } rescue nil
    end

    # access thread 3
    t3 = Thread.new do
      @cache2.take(@id, @zone) { |_, _, model| counter += 1 } rescue nil
    end

    t1.join
    t2.join
    t3.join

    counter.should eql 1
  end

  it 'should handle different instances concurrent access' do
    # init as 0
    CachedGameData.force_delete_cache(@id, @zone)
    CachedGameData.take(@id, @zone) do |_, _, model|
      model.name = 0
    end

    # rpc worker thread
    RedisRpc.worker.dequeue_count = 0
    rpc_worker_thread = Thread.new do
      RedisRpc.worker.work_loop do |job, res|
        count = RedisRpc.worker.dequeue_count
        puts "rpc.worker: count=#{count} job=#{job}"
        case count
        when 8
          RedisRpc.worker.shutdown
        end
      end
    end

    # access thread 1
    t1 = Thread.new do
      CachedGameData.take(@id, @zone) do |_, _, model|
        model.name += 1
        model.name += 1
      end
      CachedGameData.take(@id, @zone) do |_, _, model|
        model.name += 1
      end

      lambda { CachedGameData.ask(@id, @zone, ModelNamePlusOneJob)
        }.should raise_error /cached by myself/

      CachedGameData.take(@id, @zone) do |_, _, model|
        model.name += 1
      end
    end

    # access thread 2
    t2 = Thread.new do
      lambda { @cache1.take(@id, @zone, false) { |_, _, model| }
        }.should raise_error /already cached/

      @cache1.ask(@id, @zone, ModelNamePlusOneJob, false)
      @cache1.ask(@id, @zone, ModelNamePlusOneJob, false)
    end

    # access thread 3
    t3 = Thread.new do
      lambda { @cache2.take(@id, @zone, false) { |_, _, model| }
        }.should raise_error /already cached/

      @cache2.ask(@id, @zone, ModelNamePlusOneJob, false)
      @cache2.ask(@id, @zone, ModelNamePlusOneJob, false)
    end

    t1.join
    t2.join
    t3.join

    CachedGameData.take(@id, @zone) do |_, _, model|
      model.name.should eql 8
    end

    RedisRpc.worker.shutdown
    rpc_worker_thread.join
  end

end