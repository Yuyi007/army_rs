require_relative 'spec_helper'

require "timeout"

describe RedisQueue do
  before(:all) do
    @redis = Redis.new
    @queue = RedisQueue.new('__test', 'bp__test')
    @queue.clear true
  end

  after(:all) do
    @queue.clear true
  end

  it 'should return correct version string' do
    RedisQueue.version.should == "redis-queue version #{RedisQueue::VERSION}"
  end

  it 'should create a new redis-queue object' do
    queue = RedisQueue.new('__test', 'bp__test')
    queue.class.should == RedisQueue
  end

  it 'should add an element to the queue' do
    @queue << "a"
    @queue.size.should be == 1
  end

  it 'should return an element from the queue' do
    message = @queue.pop(true)
    message.should be == "a"
  end

  it 'should remove the element from bp_queue if commit is called' do
    @redis.llen('bp__test').should be == 1
    @queue.commit
    @redis.llen('bp__test').should be == 0
  end

  it 'should implements fifo pattern' do
    @queue.clear
    payload = %w(a b c d e)
    payload.each {|e| @queue << e}
    test = []
    while e=@queue.pop(true)
      test << e
    end
    payload.should be == test
  end

  it 'should remove all of the elements from the main queue' do
    %w(a b c d e).each {|e| @queue << e}
    @queue.size.should be > 0
    @queue.pop(true)
    @queue.clear
    @redis.llen('bp__test').should be > 0
  end

  it 'should reset queues content' do
    @queue.clear(true)
    @redis.llen('bp__test').should be == 0
  end

  it 'should prcess a message' do
    @queue << "a"
    @queue.process(true){|m|m.should be == "a"; true}
  end

  it 'should prcess a message leaving it into the bp_queue' do
    @queue << "a"
    @queue << "a"
    @queue.process(true){|m|m.should be == "a"; false}
    @redis.lrange('bp__test',0, -1).should be == ['a', 'a']
  end

  it 'should refill a main queue' do
    @queue.clear(true)
    @queue << "a"
    @queue << "a"
    @queue.process(true){|m|m.should be == "a"; false}
    @redis.lrange('bp__test',0, -1).should be == ['a', 'a']
    @queue.refill
    @redis.lrange('__test',0, -1).should be == ['a', 'a']
    @redis.llen('bp__test').should be == 0
  end

  it 'should work with the timeout parameters' do
    @queue.clear(true)
    2.times { @queue << rand(100) }
    is_ok = true
    begin
      Timeout::timeout(2.1) {
        @queue.process(false, 1) {|m| true}
      }
    rescue Timeout::Error => e
      is_ok = false
    end

    is_ok.should be_truthy

  end

  it 'should honor the timeout param in the initializer' do
    redis = Redis.new
    queue = RedisQueue.new('__test_tm', 'bp__test_tm', :redis => redis, :timeout => 1)
    queue.clear true

    is_ok = true
    begin
      Timeout::timeout(2.1) {
        queue.pop
      }
    rescue Timeout::Error => e
      is_ok = false
    end
    queue.clear
    is_ok.should be_truthy
  end

  it 'should push an array of objects' do
    @queue.push_batch 'a', 'b', 'c', 'd'
    @queue.length.should eql 4
    @queue.pop.should eql 'a'
    @queue.pop.should eql 'b'
    @queue.pop.should eql 'c'
    @queue.pop.should eql 'd'
    @queue.length.should eql 0
  end

end