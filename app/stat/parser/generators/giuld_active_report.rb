module Stats
	module GuildActiveGenerator
		def gen_giuld_active_report_by_records(records, date)
			each_zone_sdk_platform do |zone_id, sdk, platform|
				data = {}	
				records.each do |rc|
					data[zone_id] ||= {}
					next if rc.zone_id != zone_id && zone_id != 0
					
					data[zone_id][sdk] ||= {}
					next if rc.sdk != sdk && sdk != 'all'

					data[zone_id][sdk][platform] ||= {}
					next if rc.platform != platform && platform != 'all'

					data[zone_id][sdk][platform][rc.guild_id] ||= {}
					data[zone_id][sdk][platform][rc.guild_id][rc.active_type] ||= 0
					data[zone_id][sdk][platform][rc.guild_id][rc.active_type] += 1
				end

				data.each do |zone_id, zdata|
					zdata.each do |sdk, sdata|
						sdata.each do |platform, pdata|
							pdata.each do |guild_id, gdata|
								gdata.each do |active_type, num|
									cond = {
										:date => date, 
										:zone_id => zone_id, 
										:sdk => sdk,
										:platform => platform,
										:guild_id => guild_id,
										:active_type => active_type
									}
									record = StatsModels::GuildActiveReport.where(cond).first_or_initialize
					  			record.num = num
					  			record.save
								end
							end
						end
					end
				end
			end
			
			puts "[ReportGenerator.gen_giuld_active_report]".color(:green)+" complete"
		end

		def gen_giuld_active_report
			date = @options[:date].to_date
			records = StatsModels::GuildActive.all.to_a

			each_zone_sdk_platform do |zone_id, sdk, platform|
				data = {}	
				records.each do |rc|
					data[zone_id] ||= {}
					next if rc.zone_id != zone_id && zone_id != 0
					
					data[zone_id][sdk] ||= {}
					next if rc.sdk != sdk && sdk != 'all'

					data[zone_id][sdk][platform] ||= {}
					next if rc.platform != platform && platform != 'all'

					data[zone_id][sdk][platform][rc.guild_id] ||= {}
					data[zone_id][sdk][platform][rc.guild_id][rc.active_type] ||= 0
					data[zone_id][sdk][platform][rc.guild_id][rc.active_type] += 1
				end

				data.each do |zone_id, zdata|
					zdata.each do |sdk, sdata|
						sdata.each do |platform, pdata|
							pdata.each do |guild_id, gdata|
								gdata.each do |active_type, num|
									cond = {
										:date => date, 
										:zone_id => zone_id, 
										:sdk => sdk,
										:platform => platform,
										:guild_id => guild_id,
										:active_type => active_type
									}
									record = StatsModels::GuildActiveReport.where(cond).first_or_initialize
					  			record.num = num
					  			record.save
								end
							end
						end
					end
				end
			end
			
			puts "[ReportGenerator.gen_giuld_active_report]".color(:green)+" complete"
		end
	end

end

    