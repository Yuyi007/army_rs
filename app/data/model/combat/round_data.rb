class CombatData
  attr_accessor :cur_room_id         
	attr_accessor :weight 				      #权值
	attr_accessor :card_length 			    #牌的长度
	attr_accessor :biggest_player 		  #上一回合的玩家
  attr_accessor :cur_player           #这个回合的玩家
  attr_accessor :card_type            #当前出牌的类型

	include Loggable
  include Jsonable


  gen_to_hash
  gen_from_hash
	
  def initialize(id = nil)
    @cur_room_id   = id
    @weight        = -1
    @card_length   = -1
    @biggest_player= 4
    @cur_player    = 4
    @card_type     = 0
  end

end


##hash存储  -key , field = uid, value = room_id