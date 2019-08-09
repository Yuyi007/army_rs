# redis_conn_pool_spec.rb

require_relative 'spec_helper'

describe 'when using redis conn pool' do

  Fiber.current[:redis_ops_count] = 0

  before do
    @key1 = 'test_key1'
  end

  it 'should handle pool sizes' do
    m, n = 500, 5000

    r = RedisConnPool.new(size: m) { Redis.new }
    for i in 0..n do
      r.set @key1, i
    end

    r.get(@key1).to_i.should be n
  end

  it 'should handle timeout' do
    r = RedisConnPool.new(size: 1) { Redis.new :timeout => 0.000001 }
    lambda { r.get(@key1) }.should raise_error
  end

end