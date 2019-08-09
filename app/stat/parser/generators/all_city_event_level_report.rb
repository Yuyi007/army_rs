module Stats
	module AllCityEventLevelGenerator
		def gen_all_city_event_level_report
			date = @options[:date].to_date
			records = StatsModels::AllPlayerLevelAndCityEventLevelReport.all.to_a
			
			each_zone_sdk_platform do |zone_id, sdk, platform|
				data = {}
				records.each do |rc|
					data[zone_id] ||= {}
					next if rc.zone_id != zone_id && zone_id != 0

					data[zone_id][sdk] ||= {}
					next if rc.sdk != sdk && sdk != 'all'

					data[zone_id][sdk][platform] ||= {}
					next if rc.platform != platform && platform != 'all'

					data[zone_id][sdk][platform][rc.city_event_level] ||= 0
					data[zone_id][sdk][platform][rc.city_event_level] += 1 
				end

				data.each do |zone_id, zdata|
					zdata.each do |sdk, sdata|
						sdata.each do |platform, pdata|
							pdata.each do |level, num|
								cond = {
									:date => date, 
									:zone_id => zone_id, 
									:sdk => sdk, 
									:platform => platform, 
									:level => level
								}
								record = StatsModels::AllCityEventLevelReport.where(cond).first_or_initialize
								record.num = num
								record.save
							end
						end
					end
				end
			end
			puts "[ReportGenerator.gen_all_city_event_level_report]".color(:green)+" complete"
		end
	end
end