	# TeamInfo => {
	# 							:team_id => id,
	# 							:members_info => [
	# 																	{  
	# 																		:pid => pid,
	# 																		:ready => ready,
	# 																		:zone => zone,
	# 																		:pdata => CombatPlayerData
	# 																	}
	# 															 ]
	# 							}
class TeamInfo
	attr_accessor :team_id
	attr_accessor :creator
	attr_accessor :team_score
	attr_accessor :members_info
	attr_accessor :team_type	# member max count
	attr_accessor :status  #  0 - idle;	1 - in match pool;	 2 - match ok & not confirm; 3 - create combatroom
	attr_accessor :ch_id  #chat_id

	include Jsonable
	include Loggable

	gen_from_hash
	gen_to_hash

	def initialize(team_id, tcreator, ch_id, team_type=1)
		@team_id = team_id
		@creator = tcreator
		@team_score = 0
		@status = 0
		@team_type = team_type
		@members_info = []
		@ch_id = ch_id
	end

	def team_type
		@team_type
	end

	def add_member(pid, zone, pdata)
		return -1 if in_team?(pid)
		return -2 if @members_info.size == 5

		isready = false
		isready = true if pid == @creator
		@members_info << {:pid => pid, :zone => zone, :pdata => pdata, :ready => isready, :team => false}
		calc_score
		
		return 1
	end

	def calc_score
		@team_score = 0
		@members_info.each{ |x|  @team_score += x[:pdata].score}
		@team_score /= @members_info.length
		@team_score.round
	end

	def set_ready(pid, ready)
		@members_info.each do |mi|
			if mi[:pid] == pid and pid != @creator
				mi[:ready] = ready
			end
		end
	end

	def membercount
		return @members_info.size
	end

	def check_addready?
		@members_info.each do |mi|
			if mi[:ready] == false and mi[:pid] != @creator
				return false
			end
		end

		true
	end

	def set_status(sta)
		@status = sta

		if sta == 0
			@members_info.each do |mi|
				if mi[:pid] != @creator
					mi[:ready] = false
				end
			end
		end
	end

	def status
		@status
	end

	def member_pids
		pids = []
		@members_info.each do |mi|
	      pids << mi[:pid]
	    end

	    pids
	end

	def get_pidsandzones
		pids = []
		zones = []
		@members_info.each do |mi|
	      pids << mi[:pid]
	      zones << mi[:zone]
	    end

	    return pids, zones
	end

	def set_score(score)
		@team_score = score
	end

	def remove_member(pid)
		@members_info.delete_if {|item|
			item[:pid] == pid
		}
	end

	def in_team?(pid)
		@members_info.each do |mi|
		  return true if mi[:pid] == pid
		end
		false
	end

	def creator?(pid)
		@creator == pid
	end

	def form_team
		if @members_info.size > 1
	    @members_info.each do |mi|
	      mi[:team] = true
	    end
	  else
      @members_info.each do |mi|
	      mi[:team] = false
	    end
	  end
	end

end