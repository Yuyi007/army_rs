# coding:utf-8
# record.rb

class Record
  attr_accessor :last_login_time 	#上次登陆时间
  attr_accessor :register_time		#实例建立的时间

  include Loggable
  include Jsonable

  json_object :recharge, :RechargeRecord

  gen_from_hash
  gen_to_hash

  def initialize
    @last_login_time ||= 0
    @register_time ||= Time.now.to_i
    @win_rate ||= {}
  end

  
end
