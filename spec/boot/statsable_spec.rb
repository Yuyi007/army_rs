# statsable_spec.rb

require_relative 'spec_helper'

describe Statsable do

  AppConfig.preload(ENV['USER'], nil)
  Statsable.init(AppConfig.statsd)

  before do
    @key = 'statsable_spec_key'
    @key1 = 'statsable_spec_key1'
    @key2 = 'statsable_spec_key2'
    @key3 = 'statsable_spec_key3'
    @key4 = 'statsable_spec_key4'
    @key5 = 'statsable_spec_key5'
    @key6 = 'statsable_spec_key6'
  end

  it 'should call basic' do
    counter = 0

    Stats_.stats_increment @key
    Stats_.stats_gauge @key, 5
    Stats_.stats_timing @key, 3.0
    Stats_.stats_time @key do
      counter += 1
    end

    counter.should eql 1
  end

  it 'should call _local' do
    counter = 0

    Stats_.stats_increment_local @key
    Stats_.stats_gauge_local @key, 5
    Stats_.stats_timing_local @key, 3.0
    Stats_.stats_time_local @key do
      counter += 1
    end

    counter.should eql 1
  end

  it 'should call _global' do
    counter = 0

    Stats_.stats_increment_global @key
    Stats_.stats_gauge_global @key, 5
    Stats_.stats_timing_global @key, 3.0
    Stats_.stats_time_global @key do
      counter += 1
    end

    counter.should eql 1
  end

  it 'should support sample rate' do
    Stats_.sample_rate = 1
    Stats_.stats_increment @key

    Stats_.sample_rate = 0.5
    Stats_.stats_increment @key

    Stats_.sample_rate = 0.01
    Stats_.stats_increment @key
  end
end