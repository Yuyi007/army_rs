
class GenderType < Enum
  include EnumEachable
  enum_attr :MALE, 0
  enum_attr :FREMALE, 1
  enum_attr :UNKNOWN, 2
end


class Instance
  include RedisHelper

  attr_accessor :id          #实例id
  attr_accessor :name        #昵称
  attr_accessor :gender      #性别
  attr_accessor :icon        #头像资源id
  attr_accessor :level       #玩家等级
  attr_accessor :beans       #欢乐豆
  attr_accessor :exp         #经验

  attr_accessor :cur_room_id #当前所在的房间id 针对开房间业务
  attr_accessor :record      #所有跟玩家行为有关的记录数据 存放在这个对象实例中

  attr_accessor :online       #是否在线

  



  include Loggable
  include Jsonable
  include InstanceAlter
  
  json_object :record, :Record
  
  gen_to_hash
  gen_from_hash


  def initialize(options = nil)
    if options
      @id = options.id 
    end
    @record       ||= Record.new
    @cur_room_id  = nil
    @name         = nil 
    @icon         = nil
    @level        = 1
    @gender       ||= GenderType::UNKNOWN
    @coins        ||= 1000
    @exp          ||= 0
  end

  def refresh
    @record ||= Record.new
    @name   ||= @id
    @icon   = Array(1..9).sample if @icon.nil?
    @level  = 1 if @level.nil?
    @online = true
  end

  def self.spawn(id)
    Instance.new('id' => id)
  end

  def model
    __owner__
  end

  def zone
    model.chief.zone
  end

  def chief_id
    model.chief.id
  end

  def player_id
    "#{zone}_#{model.chief.id}_#{id}" if model  
  end

  def pid
    player_id
  end

  def cid
    model.chief.id
  end

  def user_id
    model.chief.user_id
  end

  def set_cur_combat_room(id)
    @cur_room_id = id
  end

  def mailbox
    Mailbox.one_cached(player_id)
  end
  
  def update_player
    Player.update(player_id, zone, Player.from_instance(self))
  end

  #消耗/获取欢乐豆通过此接口
  def alter_beans(num)
    @beans += num
    @beans
  end
end