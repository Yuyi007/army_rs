# action_db_spec.rb

require_relative 'spec_helper'

describe 'when using action db' do

  before do
    @test_id1 = 'spec_a1'
    @test_id2 = 'spec_a2'
    @test_zone1 = 1
    @test_zone2 = 1

    ActionDb.redis = Redis.new :db => 15
    ActionDb.register_action_type(1, 'test_action1')
    ActionDb.register_action_type(2, 'test_action2')
    ActionDb.register_action_type(3, 'test_action3')
  end

  it 'raises error when action not registered' do
    expect {
      ActionDb.log_actions(@test_id1, @test_zone1, 4)
    }.to raise_error
    ActionDb.remain_log_count.should eql 0
  end

  it 'raise error when there are more than five parameters' do
    expect {
      ActionDb.log_actions(@test_id1, @test_zone1, 1, 2, 2, 2, 2, 2, 2)
    }.to raise_error
    ActionDb.remain_log_count.should eql 0
  end

  it 'log actions' do
    ActionDb.log_actions(@test_id1, @test_zone1, [ [ 1 ] ])
    ActionDb.log_actions(@test_id1, @test_zone1, [ [ 2 ] ])
    ActionDb.log_actions(@test_id2, @test_zone2, [ [ 3 ] ])
    ActionDb.remain_log_count.should eql 3

    ActionDb.log_action(@test_id1, @test_zone1, 1, 'test', '11')
    ActionDb.log_action(@test_id1, @test_zone1, 2, 'test', '12')
    ActionDb.log_action(@test_id2, @test_zone2, 3, 'test', '13')
    ActionDb.remain_log_count.should eql 6
  end

  it 'clear actions' do
    ActionDb.clear_actions
    ActionDb.remain_log_count.should eql 0
  end

  after do
    ActionDb.redis = nil
  end

end

