module Stats
	module ShareAwardGenerator
		def gen_share_award_report_by_records(records, date)
			each_zone_sdk_platform do |zone_id, sdk, platform|
				data = {}
				records.each do |rc|
					data[zone_id] ||= {}
					next if rc.zone_id != zone_id && zone_id != 0
					
					data[zone_id][sdk] ||= {}
					next if rc.sdk != sdk && sdk != 'all'

					data[zone_id][sdk][platform] ||= {}
					next if rc.platform != platform && platform != 'all'

					data[zone_id][sdk][platform][rc.tid] ||= 0
					data[zone_id][sdk][platform][rc.tid] += 1
				end

				data.each do |zone_id, zdata|
					zdata.each do |sdk, sdata|
						sdata.each do |platform, pdata|
							pdata.each do |tid, num|
								cond = {
									:date => date, 
									:zone_id => zone_id, 
									:sdk => sdk,
									:platform => platform,
									:tid => tid
								}
								record = StatsModels::ShareAwardReport.where(cond).first_or_initialize
				  			record.num = num
				  			record.save
							end
						end
					end
				end
			end

			puts "[ReportGenerator.gen_share_award_report]".color(:green)+" complete"
		end

		def gen_share_award_report
			date = @options[:date].to_date
			records = StatsModels::ShareAward.all.to_a
			gen_share_award_report_by_records(records, date)
		end
	end
end
