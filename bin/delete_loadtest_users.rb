#!/usr/bin/env ruby
# Delete load test user keys

$LOAD_PATH.unshift(File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib', 'boot')))

require 'rubygems'
require 'boot/helpers/crc16'
require 'boot/helpers/cluster'

RANGE=(1..5000)
ZONES=(1..1)

r = RedisCluster.new([{:host => '127.0.0.1', :port => 7000}], 1)

RANGE.each do |idx|
  email_key = "e:loadtest#{idx}@fv.com"
  user_id = r.get(email_key)
  if user_id
    user_key = "u:#{user_id}"
    if r.del(user_key).to_i == 1
      puts "deleted user key[#{idx}]: #{user_key}"
    end
    ZONES.each do |zone|
      data_key = "p:#{user_id}:#{zone}"
      if r.del(data_key).to_i == 1
        puts "deleted data key[#{idx}]: #{data_key}"
      end
    end
    if r.del(email_key).to_i == 1
      puts "deleted email key[#{idx}]: #{email_key}"
    end
  end
end