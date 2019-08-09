# redis_ext_spec.rb

require_relative 'spec_helper'

describe 'redis_ext_spec' do

  it 'should handle timeout' do
    r0 = Redis.new :timeout => 0
    r1 = Redis.new :timeout => 1

    key = 'timeout_test'

    r1.set(key, 'value').should be_truthy

    lambda { r0.get key }.should raise_error

    r1.get(key).should eql 'value'

    r1.del(key)
  end

  it 'lrange_batch' do
    r = Redis.new
    key = 'lrange_batch_test'
    t = Proc.new do
      [ [0, -1], [243, -1], [243, 398], [243, 32343], [2323243, 4343434] ].each do |pair|
        i, j = pair[0], pair[1]
        res = []; r.lrange_batch(key, i, j, 1000) { |v| res << v }
        res.should eql r.lrange(key, i, j)
        res = []; r.lrange_batch(key, i, j, 6000) { |v| res << v }
        res.should eql r.lrange(key, i, j)
      end
    end
    (1..10000).each { |i| r.lpush(key, i) }
    t.call
    (1..173).each { |i| r.lpush(key, i) }
    t.call
    (1..373).each { |i| r.lpush(key, i) }
    t.call
    r.del(key)
  end

  it 'zrange_batch' do
    r = Redis.new
    key = 'zrange_batch_test'
    t = Proc.new do
      [ [0, -1], [243, -1], [243, 398], [243, 32343], [32324, 433434] ].each do |pair|
        i, j = pair[0], pair[1]
        res = []; r.zrange_batch(key, i, j, 1000) { |v| res << v }
        res.should eql r.zrange(key, i, j)
        res = []; r.zrange_batch(key, i, j, 397, :withscores => true) { |v| res << v }
        res.should eql r.zrange(key, i, j, :withscores => true)
      end
    end
    (1..10000).each { |i| r.zadd(key, i, i) }
    t.call
    (1..173).each { |i| r.zadd(key, i, i) }
    t.call
    (1..373).each { |i| r.zadd(key, i, i) }
    t.call
    r.del(key)
  end

  it 'should lpush_batch' do
    r = Redis.new
    key = 'lpush_batch_test'
    r.del(key)
    r.lpush_batch(key, 1, 2, 3)
    r.lpush_batch(key, 4, 5)
    r.llen(key).should eql 5
    r.rpop(key).should eql '1'
    r.rpop(key).should eql '2'
    r.rpop(key).should eql '3'
    r.rpop(key).should eql '4'
    r.rpop(key).should eql '5'
    r.llen(key).should eql 0
    r.del(key)
  end

end

