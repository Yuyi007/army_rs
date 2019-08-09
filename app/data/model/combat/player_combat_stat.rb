class PlayerCombatStat
  attr_accessor :pid 				  #玩家id
  attr_accessor :name 				#玩家名字
  attr_accessor :icon 				#头像
  attr_accessor :icon_frame		#头像框
  attr_accessor :tid

  attr_accessor :death				#死亡数
  attr_accessor :kill				  #杀敌数
  attr_accessor :assist 			#助攻数
  attr_accessor :goal 				#进球数
  attr_accessor :wl 				  #乌龙球数
  attr_accessor :heal 				#治疗数
  attr_accessor :dmg				  #造成伤害数
  attr_accessor :tdmg 				#承受伤害
  attr_accessor :series_kill 	#连杀
  attr_accessor :team 			  #是否组队
  attr_accessor :mvp_score 		#mvp评分

  attr_accessor :cs           #超神次数
  attr_accessor :txws         #天下无双次数
  attr_accessor :zzbs         #主宰比赛次数
  attr_accessor :fmbl         #锋芒必漏次数
  attr_accessor :wjbc         #无坚不摧次数
  attr_accessor :hsqj         #横扫千军次数


  include Loggable
  include Jsonable

  gen_to_hash
  gen_from_hash

  def initialize(pid = nil)
		@pid			 		= pid
		@name			 		||= ''
		@icon			 		||= ''
		@icon_frame		||= ''
    @tid          ||= ''
		@death				||= 0				
		@kill					||= 0
		@assist				||= 0
		@goal					||= 0
		@wl					  ||= 0
		@heal					||= 0
		@dmg					||= 0
		@tdmg					||= 0
		@series_kill  ||= 0
		@team			    ||= 0
		@mvp_score		||= 0
  end
end


class PlayerSideStats
  attr_accessor :side 
  attr_accessor	:mvp
  attr_accessor :pstats

  include Loggable
  include Jsonable

  json_array :pstats, :PlayerCombatStat

  gen_to_hash
  gen_from_hash

  def initialize(side = nil)
  	@side = side
  	@mvp 	= nil
  	@pstats ||= []
  end
end