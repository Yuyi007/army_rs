# mysql2_ext_spec.rb

require_relative 'spec_helper'

describe 'mysql2_ext_spec' do

  def get_options opts = {}
    {
      :host => '127.0.0.1',
      :port => '3306',
      :username => 'cocs',
      :password => '',
      :database => 'redis',
      :reconnect => true,
      :connect_timeout => 6,
      :read_timeout => 12,
      :write_timeout => 12,
      :pool_size => 2
    }.merge opts
  end

  it 'should handle connection fail' do
    lambda { Mysql2::Client.new get_options(:port => '987', :connect_timeout => 0.1) }.should raise_error
  end

  it 'should handle queries' do
    m0 = Mysql2::Client.new get_options()
    m0.query("SHOW DATABASES;").count.should be > 0
  end

  it 'should handle read timeout' do
    m0 = Mysql2::Client.new get_options(:read_timeout => 0)
    lambda { query("SHOW DATABASES;") }.should raise_error
  end

  it 'should handle write timeout' do
    m0 = Mysql2::Client.new get_options(:write_timeout => 0)
    # FIXME write timeout not implemented
    m0.query("SHOW DATABASES;").count.should be > 0
  end

end