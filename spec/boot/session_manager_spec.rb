# session_manager_spec.rb

require_relative 'spec_helper'

describe 'when using SessionManager' do

  before do
    @server = {}
    @session1 = DefaultSession.new(1, @server)
    @session2 = DefaultSession.new(2, @server)

    SessionManager.redis = Redis.new :db => 15
    SessionManager.init
  end

  it 'should add and delete session' do
    SessionManager.num_connected_sessions().should eql 0

    SessionManager.add_session(@session1.id, @session1)
    SessionManager.add_session(@session2.id, @session2)
    SessionManager.num_connected_sessions().should eql 2

    SessionManager.delete_session(@session1.id)
    SessionManager.delete_session(@session2.id)
    SessionManager.num_connected_sessions().should eql 0
  end

  it 'should add and remove player' do
    SessionManager.num_player_sessions(1).should eql 0
    SessionManager.num_player_sessions(2).should eql 0

    @session1.player_id = 1001; @session1.zone = 1;
    @session2.player_id = 1001; @session2.zone = 1;

    SessionManager.add_player(@session1.player_id, @session1.zone, @session1.id, @session1)
    SessionManager.num_player_sessions(1).should eql 1
    SessionManager.num_player_sessions(2).should eql 0

    SessionManager.add_player(@session2.player_id, @session2.zone, @session2.id, @session2)
    SessionManager.num_player_sessions(1).should eql 1
    SessionManager.num_player_sessions(2).should eql 0

    SessionManager.remove_player(@session1.player_id, @session1.zone, @session1.id)
    SessionManager.num_player_sessions(1).should eql 1
    SessionManager.num_player_sessions(2).should eql 0

    SessionManager.remove_player(@session2.player_id, @session2.zone, @session2.id)
    SessionManager.num_player_sessions(1).should eql 0
    SessionManager.num_player_sessions(2).should eql 0

    SessionManager.add_player(@session1.player_id, @session1.zone, @session1.id, @session1)
    SessionManager.add_player(@session2.player_id, @session2.zone, @session2.id, @session2)
    SessionManager.force_remove_player(@session1.player_id, @session1.zone)
    SessionManager.num_player_sessions(1).should eql 0
    SessionManager.num_player_sessions(2).should eql 0
    SessionManager.num_connected_sessions().should eql 0
  end

  after do
    SessionManager.redis = nil
    SessionManager.reset
  end

end

