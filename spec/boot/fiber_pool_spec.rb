# fiber_pool_spec.rb

require_relative 'spec_helper'

describe Fiber do

  it 'should store local variables' do
    Fiber.current[:test_variable] = 1984
    Fiber.current[:test_variable].should eql 1984
  end

end

describe FiberPool do

  it 'should spawn' do
    m, n = 400, 2000

    pool = FiberPool.new(m)
    pool.size.should eql m
    pool.busy_size.should eql 0
    pool.queue_size.should eql 0

    for i in 0..n do
      pool.spawn do
        pool.busy_size.should eql 1
        pool.size.should eql m - 1
        pool.queue_size.should eql (m < 1 ? 1 : 0)
      end
    end

    pool.size.should eql m
    pool.busy_size.should eql 0
    pool.queue_size.should eql 0
  end

  it 'should handle callbacks' do
    count = 0
    pool = FiberPool.new(1)
    pool.generic_callbacks << lambda { count += 1 }
    pool.spawn { Fiber.current[:callbacks] << lambda { count += 1} }
    count.should eql 2
  end

end