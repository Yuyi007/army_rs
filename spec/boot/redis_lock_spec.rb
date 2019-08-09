# redis_lock_spec.rb

require_relative 'spec_helper'

describe 'redis_lock_spec' do

  before do
    @key1 = 'test_lock1'
    @key2 = 'test_lock2'

    redis_lock1 = RedisLock.new(Redis.new, @key1)
    redis_lock2 = RedisLock.new(Redis.new, @key2)

    redis_lock1.clear
    redis_lock2.clear
  end

  it 'should handle options' do
    redis_lock1 = RedisLock.new(Redis.new, @key1,
      :max_retry => 1, :retry_wait_time => 0.2,
      :lock_timeout => 0.1, :sane_expiry => 20, :expiry_grace => 0)

    redis_lock1.clear
    redis_lock1.unlock.should be_nil # not acquired
    redis_lock1.trylock.should be_truthy
    redis_lock1.unlock.should be_truthy

    # should aquire after lock timeout
    redis_lock1.lock do
      Kernel.sleep redis_lock1.lock_timeout * 1.01 # lock has only 3 digits precision
      redis_lock1.lock do
      end.should be_truthy
    end.should be_truthy

    # TODO more sanity tests about options
  end

  it 'should handle lock' do
    m, n = 5, 500

    redis = Redis.new
    redis.set(@key1, 0)

    redis_lock = RedisLock.new(redis, @key1)
    redis_lock.unlock
    redis_lock.acquired?.should be_falsey
    redis_lock.timeout?.should be_falsey

    for i in 0..m do
      redis_lock.lock.should be_truthy
      redis_lock.acquired?.should be_truthy
      redis_lock.timeout?.should be_falsey
      redis_lock.unlock
    end

    t = []
    for i in 0..m do
      t[i] = Kernel.fork do
        r = Redis.new
        redis_lock = RedisLock.new(r, @key1, :max_retry => 100,
          :retry_wait_time => 0.02, :lock_timeout => 0.01)
        for j in 0..n do
          (redis_lock.lock { |_| r.set(@key1, r.get(@key1).to_i + 1) }).should be_truthy
        end
      end
    end
    for i in 0..m do
      Process.waitpid2 t[i]
    end

    redis.get(@key1).to_i.should eql (m+1)*(n+1)
  end

  it 'should handle trylock' do
    m = 5
    counter = 0

    redis_lock = RedisLock.new(Redis.new, @key1)
    redis_lock.unlock

    for i in 0..m do
      redis_lock.trylock.should be_truthy
      redis_lock.acquired?.should be_truthy
      redis_lock.timeout?.should be_falsey
      redis_lock.unlock
    end

    for i in 0..m do
      redis_lock.trylock { |_| counter += 1 }.should be_truthy
    end

    counter.should eql (m+1)
  end

  it 'should handle deadlock' do
    options = {:max_retry => 3, :retry_wait_time => 0.001, :lock_timeout => 0.01, :expiry_grace => 0.0}

    redis_lock1 = RedisLock.new(Redis.new, @key1, options)
    redis_lock2 = RedisLock.new(Redis.new, @key2, options)
    redis_lock1.unlock
    redis_lock2.unlock

    redis_lock1.acquired?.should be_falsey
    redis_lock1.timeout?.should be_falsey
    redis_lock2.acquired?.should be_falsey
    redis_lock2.timeout?.should be_falsey

    redis_lock1.lock do
      lambda { redis_lock2.lock { redis_lock1.lock } }.should raise_error
    end

    redis_lock1.acquired?.should be_falsey
    redis_lock1.timeout?.should be_falsey
    redis_lock2.acquired?.should be_falsey
    redis_lock2.timeout?.should be_falsey

    # should aquire after deadlock
    redis_lock1.lock do
      Kernel.sleep redis_lock1.lock_timeout

      redis_lock2.lock do
        redis_lock1.lock { |_| }.should be_truthy
      end.should be_truthy
    end.should be_truthy
  end

  it 'should return valid parameters' do
    redis_lock = RedisLock.new(Redis.new, @key1)

    redis_lock.lock do |key, lock|
      key.should be_kind_of String
      lock.should eql redis_lock
    end
  end

  it 'should return correct acquired?' do
    redis_lock = RedisLock.new(Redis.new, @key1)
    redis_lock.acquired?.should be_falsey

    redis_lock.lock
    redis_lock.acquired?.should be_truthy

    redis_lock.unlock
    redis_lock.acquired?.should be_falsey
  end

  it 'should return correct timeout?' do
    redis_lock = RedisLock.new(Redis.new, @key1, :lock_timeout => 0.01, :expiry_grace => 0)
    redis_lock.timeout?.should be_falsey

    redis_lock.lock
    redis_lock.timeout?.should be_falsey
    redis_lock.about_to_timeout?.should be_falsey

    Kernel.sleep 0.001
    redis_lock.about_to_timeout?.should be_falsey
    Kernel.sleep 0.008
    redis_lock.about_to_timeout?.should be_truthy

    Kernel.sleep 0.02
    redis_lock.timeout?.should be_truthy
    redis_lock.about_to_timeout?.should be_truthy

    redis_lock.unlock.should be_nil

    redis_lock.clear
    redis_lock.timeout?.should be_falsey
  end

  it 'should renew' do
    redis = Redis.new
    redis_lock = RedisLock.new(redis, @key1, :lock_timeout => 0.01, :expiry_grace => 0)
    redis_lock.renew.should be_falsey

    redis_lock.lock
    Kernel.sleep 0.02
    redis_lock.renew.should be_falsey

    redis_lock.lock
    redis_lock.renew.should be_truthy

    Kernel.sleep 0.005
    now = Time.now
    redis_lock.renew.should be_truthy
    ((redis_lock.lock_acquire_time - now.to_f).abs).should be < 0.001

    Kernel.sleep 0.001
    redis_lock.acquired?.should be_truthy
    redis_lock.timeout?.should be_falsey

    Kernel.sleep 0.01
    redis_lock.acquired?.should be_truthy
    redis_lock.timeout?.should be_truthy

    redis_lock.renew.should be_falsey

    redis_lock.lock
    redis.del(redis_lock.key)
    lambda { redis_lock.renew }.should raise_error /no old expiry/

    redis_lock.lock
    redis.set(redis_lock.key, Time.now + 5.0)
    redis_lock.renew.should be_truthy
  end

end