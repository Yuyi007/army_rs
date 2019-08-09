# redis_hash_spec.rb

require_relative 'spec_helper'

class TestRedisHash

  attr_accessor :array

  include Jsonable

  def initialize
    self.array = []
  end

end

describe 'redis_hash_spec' do

  N = 5

  before do
    lock_options = {:max_retry => 6, :retry_wait_time => 0.001,
      :lock_timeout => 0.01, :expiry_grace => 0.0}
    @redis_hash = RedisHash.new(Redis.new, 'test_redis_hash', TestRedisHash, :lock => lock_options)
    @redis_hash2 = RedisHash.new(Redis.new, 'test_redis_hash2', nil, :lock => lock_options)
  end

  it 'should delete_all' do
    @redis_hash.delete_all
    @redis_hash.hlen.should eql 0
  end

  it 'should hget' do
    @redis_hash.hdel('default')
    @redis_hash.hget('default').should be nil
    @redis_hash.hget_or_new('default').array.length.should be 0
  end

  it 'should hset_with_lock' do
    @redis_hash.hset_with_lock('default') do |t|
      t.array << 1
      t
    end
    @redis_hash.hset_with_lock('default') do |t|
      t.array << 2
      t
    end

    @redis_hash.hlen.should eql 2 # 'default' and its version
    @redis_hash.hget('default').array.length.should be 2
  end

  it 'should hmget' do
    @redis_hash.hset_with_lock('default') do |t| t end
    @redis_hash.hset_with_lock('default2') do |t| t end

    @redis_hash.hmget(['default', 'default2']).each_with_index do |data, index|
      if index == 0
        data.array.length.should be 2
      elsif index == 1
        data.array.length.should be 0
      else
        raise 'invalid index'
      end
    end
  end

  it 'should hlen' do
    @redis_hash.hlen.should eql 4 # 2 keys and 2 versions
  end

  it 'should hset without storing result' do
    @redis_hash.hset_with_lock('default') do |t|
      t.array << 3
      nil
    end

    @redis_hash.hget('default').array.length.should be 2
  end

  it 'should raise because of wrong return value' do
    expect {
      @redis_hash.hset_with_lock('default') do |t|
        t.array << 3
        t.array
      end
      }.to raise_error
  end

  it 'should return true or false' do
    @redis_hash.hset_with_lock('default') do |t|
      t.array << 3
      t
    end.should be true

    @redis_hash.hget('default').array.length.should be 3
  end

  it 'should hset with lock' do
    threads = []

    (1..N).each do |i|
      threads[i] = Thread.new do
        @redis_hash.hset_with_lock('default') do |t|
          t.array << (3+i)
          t
        end
      end
    end

    (1..N).each { |i| threads[i].join }

    @redis_hash.hget('default').array.length.should be 3 + N
  end

  it 'should hset without lock' do
    t = @redis_hash.hget('default')
    t.array << (4+N)
    @redis_hash.hset('default', t)
    @redis_hash.hget('default').array.length.should be 4 + N
  end

  it 'should hdel with lock' do
    @redis_hash.hset_with_lock('default') do |t|
      t.array << (3+N+1)
      lambda { @redis_hash.hdel_with_lock('default') }.should raise_error /trylock limit/
      t
    end
  end

  it 'should hdel' do
    @redis_hash.hdel_with_lock('default')
    @redis_hash.hget('default').should be nil
  end

  it 'should process nil jsonable' do
    @redis_hash2.hset_with_lock('default') do |t|
      { 'a' => 2, 'b' => 'cc' }
    end

    res = @redis_hash2.hget('default')
    res.length.should eql 2
    res['a'].should eql 2
    res['b'].should eql 'cc'

    @redis_hash2.hdel_with_lock('default')
  end

  it 'should do correct version-checking' do
    lambda { @redis_hash.hset_with_lock('default') do |t|
      redis = Redis.new
      version = redis.hget(@redis_hash.key, 'default_redis_hash_version')
      redis.hset(@redis_hash.key, 'default_redis_hash_version', version.to_i + 1)
      t
    end }.should raise_error /version\-check/
  end

end