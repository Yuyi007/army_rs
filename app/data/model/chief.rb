
class Chief
  attr_accessor :id                         #账号id
  attr_accessor :zone                       #区
  attr_accessor :cur_inst_id                #当前instance id
  attr_accessor :device_id, :sdk, :platform #客户端相关数据
  attr_accessor :credits                    #充值钻石
  attr_accessor :vip_level                  #vip 等级
  attr_accessor :user_id # the id got from platform
  attr_accessor :max_friends_num            #好友上限人数

  MaxLevel = 65
  MinLevel = 1

  include Loggable
  include Jsonable

  gen_from_hash
  gen_to_hash

  def initialize
    @credits ||= 0
    @vip_level ||= 0
    @max_friends_num = 100
  end

  #消耗/获取钻石必须通过此接口
  def alter_credits(num)
    @credits += num
    @credits
  end
end
