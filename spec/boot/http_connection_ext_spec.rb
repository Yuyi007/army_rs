# http_connection_ext_spec.rb

require_relative 'spec_helper'

describe 'http_connection_ext_spec' do

  EM::Synchrony.init_fiber_pool

  before do
    @timeout_url = 'http://127.0.0.1:9870/timeout'
    @good_url = 'http://www.baidu.com'
    EM::Udns.clear_nameservers
  end

  it 'should handle http timeout' do
    EM.synchrony do
      begin
        start_time = Time.now
        EventMachine.heartbeat_interval = 0.1
        http1 = EventMachine::HttpRequest.new(@timeout_url, :inactivity_timeout => 0.1).get
        http1.response.length.should eql 0
        (Time.now - start_time).should <= 2
        http2 = EventMachine::HttpRequest.new(@good_url, :inactivity_timeout => 60).get
        http2.response.length.should be > 0
      ensure
        EM.stop
        Resolv.detach_udns
      end
    end
  end

end