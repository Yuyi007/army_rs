# cacheable_spec.rb

require_relative 'spec_helper'

class TestCacheable

  include Cacheable

  gen_static_cached 600, :get_time
  gen_static_invalidate_cache :get_time

  def self.get_time
    Time.now
  end

end

describe Cacheable do

  it 'should handle cached' do
    obj = TestCacheable

    time0 = obj.get_time
    time1 = obj.get_time_cached
    time2 = obj.get_time_cached

    obj.get_time_invalidate_cache

    time3 = obj.get_time_cached
    time4 = obj.get_time_cached

    time0.should be < time1
    time1.should eql time2
    time3.should be > time2
    time4.should eql time3
  end

end