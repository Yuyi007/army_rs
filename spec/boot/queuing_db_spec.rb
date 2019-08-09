# action_db_spec.rb

require_relative 'spec_helper'

describe 'when using queuing db' do

  before(:all) do
    @test_id1 = 1
    @test_id2 = 2
    @test_zone1 = 1
    @test_zone2 = 2

    redis = Redis.new :db => 15
    DynamicAppConfig.redis = redis
    SessionManager.redis = redis
    QueuingDb.redis = redis
    QueuingDb.clear_all(@test_zone1)
    QueuingDb.clear_all(@test_zone2)
  end

  after(:all) do
    DynamicAppConfig.redis = nil
    SessionManager.redis = nil
    QueuingDb.redis = nil
  end

  it 'should judge whether to enqueue' do
    QueuingDb.should_queue?(@test_id1, @test_zone1).should eql false
    QueuingDb.should_queue?(@test_id2, @test_zone2).should eql false
  end

  it 'should get correct dequeue num' do
    QueuingDb.dequeue_num(@test_zone1).should eql QueuingDb::MAX_DEQUEUE_BATCH
    QueuingDb.dequeue_num(@test_zone2).should eql QueuingDb::MAX_DEQUEUE_BATCH
  end

  it 'should enqueue' do
    QueuingDb.queue_len(@test_zone1).should eql 0
    QueuingDb.queue_len(@test_zone2).should eql 0

    QueuingDb.enqueue(@test_id1, @test_zone1).should eql true
    QueuingDb.enqueue(@test_id1, @test_zone1).should eql false
    QueuingDb.enqueue(@test_id2, @test_zone1).should eql true
    QueuingDb.queue_len(@test_zone1).should eql 2

    QueuingDb.enqueue(@test_id2, @test_zone2).should eql true
    QueuingDb.queue_len(@test_zone2).should eql 1
  end

  it 'should get correct rank' do
    QueuingDb.rank(@test_id1, @test_zone1).should eql 0
    QueuingDb.rank(@test_id2, @test_zone1).should eql 1

    QueuingDb.rank(@test_id2, @test_zone2).should eql 0
  end

  it 'should raise error when enqueue_jump with invalid forward' do
    expect {
      QueuingDb.enqueue_jump(@test_id2, @test_zone1, 0)
    }.to raise_error
  end

  it 'should enqueue_jump' do
    QueuingDb.enqueue_jump(@test_id2, @test_zone1, 1).should eql true
    QueuingDb.enqueue_jump(@test_id2, @test_zone1, 100).should eql true

    QueuingDb.queue_len(@test_zone1).should eql 2
    QueuingDb.rank(@test_id1, @test_zone1).should eql 1
    QueuingDb.rank(@test_id2, @test_zone1).should eql 0
  end

  it 'should raise error when dequeue with invalid count' do
    expect {
      QueuingDb.dequeue(0, @test_zone1)
    }.to raise_error
  end

  it 'should dequeue' do
    QueuingDb.dequeue(2, @test_zone1).length.should eql 2
    QueuingDb.dequeue(3, @test_zone2).length.should eql 1
    QueuingDb.dequeue(1, @test_zone2).length.should eql 0

    QueuingDb.queue_len(@test_zone1).should eql 0
    QueuingDb.queue_len(@test_zone2).should eql 0
  end

  it 'should renew' do
    QueuingDb.should_queue?(@test_id1, @test_zone1).should eql false
    QueuingDb.renew(@test_id1, @test_zone1, 1)
    QueuingDb.should_queue?(@test_id1, @test_zone1).should eql false
    Kernel.sleep 1.0
    QueuingDb.should_queue?(@test_id1, @test_zone1).should eql false
  end

  it 'should remove' do
    QueuingDb.enqueue_jump(@test_id1, @test_zone1, 1)
    QueuingDb.queue_len(@test_zone1).should eql 1

    QueuingDb.remove(@test_id1, @test_zone1)
    QueuingDb.queue_len(@test_zone1).should eql 0
  end

  it 'should clear all' do
    QueuingDb.clear_all(@test_zone1)
    QueuingDb.clear_all(@test_zone2)

    QueuingDb.queue_len(@test_zone1).should eql 0
    QueuingDb.queue_len(@test_zone2).should eql 0
  end

end

