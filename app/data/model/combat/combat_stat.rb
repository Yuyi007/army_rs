#战斗统计数据
class CombatStat
  attr_accessor :score              #积分
	#prefix 't_' means total
	attr_accessor :t_combat_count 		#所有比赛场次和
	attr_accessor :t_win_count				#总胜场次

	attr_accessor :t_win_mvp 					#总的胜场mvp数
	attr_accessor :t_lose_mvp 				#总的失败mvp数
	
	attr_accessor :t_cs			 					#总的超神次数
	attr_accessor :t_txws			 				#总的天下无双次数
	attr_accessor :t_zzbs			 				#总的主宰比赛次数
	attr_accessor :t_fmbl			 				#总的锋芒必漏次数
	attr_accessor :t_wjbc			 				#总的无坚不摧次数
	attr_accessor :t_hsqj			 				#总的横扫千军次数
	attr_accessor :t_kill 						#总杀敌数

	attr_accessor :t_dmg 							#总伤害数
	attr_accessor :t_tdmg 						#总承受伤害数
	attr_accessor :t_assist 					#总助攻数
	attr_accessor :t_goal 						#总进球数
	attr_accessor :t_heal 						#总治疗数
	attr_accessor :t_death 						#总死亡数

  include Loggable
  include Jsonable

  gen_to_hash
  gen_from_hash

  def initialize
		@t_combat_count = {}
		@t_win_count = {}

		@t_win_mvp = {}
		@t_lose_mvp = {}

		@t_cs = {}
		@t_txws = {}
		@t_zzbs = {}
		@t_fmbl = {}
		@t_wjbc = {}
		@t_hsqj = {}
		@t_kill = {}

		@t_dmg = {}
		@t_tdmg = {}
		@t_assist = {}
		@t_goal = {}
		@t_heal = {}
		@t_death = {}
    @score = 0
  end

  def calc_stat(instance, rc)
    #找到stat 和 side
    # puts ">>>>>>rc:#{rc}"
    return if rc.enter_type == 0
    pstat = nil
    side = nil

    rc.stats.each do |sideStats|
      sideStats.pstats.each do |stat|
        if stat.pid == instance.pid
          pstat = stat
          side = sideStats.side
          break
        end
      end

      break if !pstat.nil?
    end

    mtype = rc.mtype.to_s
    ctype = rc.ctype.to_s

    #所有比赛场次和
    @t_combat_count[mtype] ||= {}
    # puts ">>>>>>t_combat_count222:#{@t_combat_count[mtype][ctype]}"
    @t_combat_count[mtype][ctype] ||= 0
    @t_combat_count[mtype][ctype] += 1
    #总胜场次
    @t_win_count[mtype] ||= {}
    @t_win_count[mtype][ctype] ||= 0
    @t_win_count[mtype][ctype] += 1 if side == rc.winner  

    #总的胜场mvp数
    @t_win_mvp[mtype] ||= {}
    @t_win_mvp[mtype][ctype] ||= 0
    sideStats = rc.stats[side]

    @t_win_mvp[mtype][ctype] += 1 if (sideStats.mvp == instance.pid && side == rc.winner)
    if side == rc.winner
      @score += 50 
    else
      @score -= 50 
    end
    @score = 0 if @score < 0

    #总的失败mvp数
    @t_lose_mvp[mtype] ||= {}
    @t_lose_mvp[mtype][ctype] ||= 0
    @t_lose_mvp[mtype][ctype] += 1 if (sideStats.mvp == instance.pid && side != rc.winner)

    #总的超神次数
    @t_cs[mtype] ||= {}
    @t_cs[mtype][ctype] ||= 0
    @t_cs[mtype][ctype] 	+= pstat.cs   

    #总的天下无双次数     
    @t_txws[mtype] ||= {}
    @t_txws[mtype][ctype] ||= 0      
    @t_txws[mtype][ctype] += pstat.txws  

    #总的主宰比赛次数   
    @t_zzbs[mtype] ||= {}
    @t_zzbs[mtype][ctype] ||= 0        
    @t_zzbs[mtype][ctype] += pstat.zzbs     

    #总的锋芒必漏次数       
    @t_fmbl[mtype] ||= {}
    @t_fmbl[mtype][ctype] ||= 0    
    @t_fmbl[mtype][ctype] += pstat.fmbl   

    #总的无坚不摧次数     
    @t_wjbc[mtype] ||= {}
    @t_wjbc[mtype][ctype] ||= 0        
    @t_wjbc[mtype][ctype] += pstat.wjbc            

    #总的横扫千军次数
    @t_hsqj[mtype] ||= {}
    @t_hsqj[mtype][ctype] ||= 0   
    @t_hsqj[mtype][ctype] += pstat.hsqj             

    #总杀敌数
    @t_kill[mtype] ||= {}
    @t_kill[mtype][ctype] ||= 0   
    @t_kill[mtype][ctype]  += pstat.kill    

    #总伤害数       	
    @t_dmg[mtype] ||= {}
    @t_dmg[mtype][ctype] ||= 0   
    @t_dmg[mtype][ctype]   += pstat.dmg    

    #总承受伤害数
    @t_tdmg[mtype] ||= {}
    @t_tdmg[mtype][ctype] ||= 0  
    @t_tdmg[mtype][ctype]  += pstat.tdmg          	
    
    #总助攻数
    @t_assist[mtype] ||= {}
    @t_assist[mtype][ctype] ||= 0   
    @t_assist[mtype][ctype]	+= pstat.assist          
    
    #总进球数
    @t_goal[mtype] ||= {}
    @t_goal[mtype][ctype] ||= 0   
    @t_goal[mtype][ctype]  += pstat.goal		
    
    #总治疗数				
    @t_heal[mtype] ||= {}
    @t_heal[mtype][ctype] ||= 0   
    @t_heal[mtype][ctype]  += pstat.heal           	
    
    #总死亡数
    @t_death[mtype] ||= {}
    @t_death[mtype][ctype] ||= 0   
    @t_death[mtype][ctype] += pstat.death           
  end
end