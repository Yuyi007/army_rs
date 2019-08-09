module Stats
	module GuildSkillLevelGenerator
	def get_guild_skill_level_index(level)
    return -1 if level <= 0
    return ((level - 0.5) / 5).to_i
  end

		def gen_guild_skill_level_report
			date = @options[:date].to_date
			
			records = StatsModels::GuildSkill.all.to_a
			each_zone_sdk_platform do |zone_id, sdk, platform|
				data = {}
				records.each do |rc|
					data[zone_id] ||= {}
					next if rc.zone_id != zone_id && zone_id != 0
					
					data[zone_id][sdk] ||= {}
					next if rc.sdk != sdk && sdk != 'all'

					data[zone_id][sdk][platform] ||= {}
					next if rc.platform != platform && platform != 'all'

					6.times do |i|
						level = rc.send("guild_skill_#{i+1}")
          	lv_rgn = get_guild_skill_level_index(level)
          	if lv_rgn >= 0
          		data[zone_id][sdk][platform][i] ||= {}
          		data[zone_id][sdk][platform][i][lv_rgn] ||= 0
          		data[zone_id][sdk][platform][i][lv_rgn] += 1
          	end
					end
				end

				data.each do |zone_id, zdata|
					zdata.each do |sdk, sdata|
						sdata.each do |platform, pdata|
							pdata.each do |skill_id, skdata|
								skdata.each do |lv_rgn, num|
									cond = {
										:date => date, 
										:sdk => sdk,
										:platform => platform,
										:zone_id => zone_id, 
										:skill_id => skill_id, 
										:lv_rgn => lv_rgn
									}
									record = StatsModels::GuildSkillReport.where(cond).first_or_initialize
									
									record.num = num
									record.save
								end
							end
						end
					end
				end
			end
			
			puts "[ReportGenerator.gen_guild_skill_level_report]".color(:green)+" complete"
		end
	end
end