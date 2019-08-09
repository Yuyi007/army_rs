# resolv_ext_spec.rb

require_relative 'spec_helper'

describe 'resolv_ext_spec' do

  EM::Synchrony.init_fiber_pool

  before do
    @dns_error_url1 = 'http://nonexist1.firevale.com:9870/test'
    @dns_error_url2 = 'http://nonexist2.firevale.com:9870/test'
    @fv_web_domain = 'www.firevale.com'
    EM::Udns.clear_nameservers
  end

  it 'should handle async resolve' do
    counter = 0
    EM.synchrony do
      begin
        EM::Synchrony.next_tick { counter += 1 }

        lambda { EventMachine::HttpRequest.new(@dns_error_url1).get }.should raise_error
        lambda { EventMachine::HttpRequest.new(@dns_error_url2).get }.should raise_error
      ensure
        EM.stop
        Resolv.detach_udns
        counter.should be 1
      end
    end
  end

  it 'should handle resolve timeout' do
    counter = 0
    EM.synchrony do
      begin
        EM::Udns.nameservers = '192.168.199.178'
        EventMachine.heartbeat_interval = 0.1
        Resolv.set_udns_timeout 0.01
        EM::Synchrony.next_tick { counter += 1 }
        lambda { Resolv.getaddress @fv_web_domain }.should raise_error
      ensure
        EM.stop
        Resolv.detach_udns
        counter.should be 1
      end
    end
  end

end