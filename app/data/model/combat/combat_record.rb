#单场战斗数据，记录最近20场匹配战斗数据
class CombatRecord
	attr_accessor :token 				#战斗房间token
	attr_accessor :mtype 				#地图类型
	attr_accessor :ctype 				#战斗类型 3v3 etc
	attr_accessor :winner				#胜出方
	attr_accessor :duration 		#战斗时长
	attr_accessor :stats				#玩家战报
	attr_accessor :begintime    #游戏开始时间
	attr_accessor :enter_type 	#匹配进入，还是开房间进入

	include Loggable
  include Jsonable

  json_array :stats, :PlayerSideStats

  gen_to_hash
  gen_from_hash

  def initialize(token = nil)
  	@token 		= token		
		@mtype 		||= -1
		@ctype 		||= -1
		@winner		||= -1
		@duration ||= 0
		@stats		||= []
		@begintime ||= 0
		@enter_type ||= 0
  end
end