class TeamMatch1V1
	attr_accessor :begin_score      
	attr_accessor :end_score
	attr_accessor :team_infos

	attr_accessor :team_groups

	attr_accessor :item_left
	attr_accessor :item_right
	attr_accessor :res

	attr_accessor :wait_tick
	attr_accessor :new_request

	PAIR_LEFT = 0
	PAIR_RIGHT = 1

	def initialize(begin_score, end_score)
		@begin_score = begin_score
		@end_score = end_score
		@team_infos = {}
		@wait_tick = 0
		@new_request = {}

		(1..1).each do |member_count|
			@team_infos[member_count] = []
		end

		@item_left = []
		@item_right = []

		@team_groups = {}

		# puts "init", @team_infos
	end

	def add_team(team_id, team_score, members_info, ch_id, robot=false)
		remove_team(team_id)
		#return false if @team_groups[team_id]

		if robot == false
			@new_request[team_id] = team_score
		end

		member_count = members_info.length
		return false  if !@team_infos[member_count]

		@team_infos[member_count] << {:team_id => team_id, :team_score => team_score, :members_info => members_info, :ch_id => ch_id}

		@team_groups[team_id] = member_count

		# puts "@ 1v1 POOL", @team_infos
	end

	def remove_team(team_id)
		#return if !@team_groups.has_key?(team_id)  
		@new_request.delete(team_id)

		groupid = @team_groups[team_id] 
		@team_infos.each do |k, v|
			v.delete_if {|item| item[:team_id] == team_id}
		end

		@team_groups.delete(team_id)

		# puts "@ 1v1 POOL", @team_infos
	end

	def team_count()
		@new_request.size
	end

	def do_match() #return [  {:left=>[team_item, team_item, ......], :right=>[team_item, team_item, ......] },  ......   ]		
		@wait_tick = @wait_tick + 1 if @new_request.size > 0 and RobotManager.apply_flag
		@res = []

		if @team_infos[1] .size > 0 

			#@item_left = []
		#	@item_left << @team_infos[1].shift
			#@item_right = []

			#push_team_pair()

			match_Pair_I(1, 1)

			#puts "match pairs", @res
		end

		# puts "@ 1v1 POOL", @team_infos

		if RobotManager.apply_flag and @res.size == 0 and @new_request.size > 0 and @wait_tick >= 8
			tm = TeamManager.new_rb_team(0, 500)
			add_team(tm.team_id, tm.team_score, tm.members_info, true)

			@wait_tick = 0
		end
		
		@res
	end

	##################################################################################################################
	private

	def pick_team_part_I(container, groupid, count)		
		if container == PAIR_LEFT
			@item_left = []
		else
			@item_right = []
		end

		if @team_infos[groupid].size >= count 
			remaincount = @team_infos[groupid].size - count
			while @team_infos[groupid].size > remaincount 

				item = @team_infos[groupid].shift
				@team_groups.delete(item[:team_id])

				if container == PAIR_LEFT
					@item_left << item
				else
					@item_right << item
				end
			end

			return true
		end

		false
	end
	
	def match_Pair_I(groupid, count)
		@item_left = []
		@item_right = []

		while @team_infos[groupid] and @team_infos[groupid].size >= count 
			#puts @team_infos[groupid]
			pick_team_part_I(PAIR_LEFT, groupid, count) 

			if pick_team_part_I(PAIR_RIGHT, 1, 1) 				# 3
				push_team_pair()	

			else
				while @item_left.empty? == false
					@team_infos[groupid] << @item_left.shift  
				end

				break
			end 			
		end
	end

	def push_team_pair()
		itemPair = {}
		itemPair[:left] = @item_left
		itemPair[:right] = @item_right 
		@res << itemPair

		@item_left.each do |item|
			TeamManager.set_team_status(item[:team_id], 2)
			@new_request.delete(item[:team_id])
		end
		@item_right.each do |item|
			TeamManager.set_team_status(item[:team_id], 2)
			@new_request.delete(item[:team_id])
		end

		@item_left = []
		@item_right = []
	end

end