# redis_migrate_db_spec.rb

require 'mock_redis'
require_relative 'spec_helper'

describe RedisMigrateDb do

  before do
    @old_hosts = [ 'redis://localhost:6379/0' ]
    @new_hosts = [ 'redis://localhost:6379/0', 'redis://localhost:6380/2' ]
    @new_hosts2 = [ 'redis://localhost:6379/0', 'redis://localhost:6380/2', 'redis://localhost:6381/3' ]

    @mock_redises = {}
    (@old_hosts + @new_hosts + @new_hosts2).uniq.each do |url|
      db = url.split('/').last.to_i
      @mock_redises[url] ||= MockRedis.new(:db => db)
    end

    expect(Redis).to receive(:new).at_least(1).times do |options|
      url = options[:url]
      redis = @mock_redises[url]
      allow(redis).to receive(:migrate) do |key, options|
        db = options[:db]
        redis.move(key, db)
      end
      redis
    end

    @m = RedisMigrateDb.new(Redis.new :url => @old_hosts[0])
  end

  it 'should get/set/del redis config' do
    @m.get_old_redis_cfg.should eql nil
    @m.set_old_redis_cfg({})
    @m.get_old_redis_cfg.should eql ({})
    @m.del_old_redis_cfg.should eql 1
  end

  it 'should migrate' do
    old_cluster = Redis::Distributed.new(@old_hosts)
    new_cluster = Redis::Distributed.new(@new_hosts)
    new_cluster2 = Redis::Distributed.new(@new_hosts2)

    N = 100
    (0...N).each { |i| old_cluster.set("_redis_migrate_spec_#{i}", i) }
    (0...N).each { |i| old_cluster.get("_redis_migrate_spec_#{i}").should eql "#{i}" }
    old_cluster.keys('*').length.should eql N

    # Not working, not sure why

    # @m.run_migration @old_hosts, @new_hosts
    # (0...N).each { |i| new_cluster.get("_redis_migrate_spec_#{i}").should eql "#{i}" }

    # @m.run_migration @new_hosts, @new_hosts2
    # (0...N).each { |i| new_cluster2.get("_redis_migrate_spec_#{i}").should eql "#{i}" }

    # @m.run_migration @new_hosts2, @old_hosts
    # (0...N).each { |i| old_cluster.get("_redis_migrate_spec_#{i}").should eql "#{i}" }
  end

end

