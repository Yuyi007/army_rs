module Stats
	module MainCampaignGenerator
		def gen_main_campaign_report
			date = @options[:date].to_date
			records = StatsModels::FinishCampaign.all.to_a
			gen_main_campaign_report_by_records(records, date)
		end

		def gen_main_campaign_report_by_records(records, date)
			each_zone_sdk_platform do |zone_id, sdk, platform|
				data = {}
				records.each do |rc|
					data[zone_id] ||= {}
					next if rc.zone_id != zone_id && zone_id != 0
					
					data[zone_id][sdk] ||= {}
					next if rc.sdk != sdk && sdk != 'all'

					data[zone_id][sdk][platform] ||= {}
					next if rc.platform != platform && platform != 'all'


					data[zone_id][sdk][platform][rc.cid] ||= 0
					data[zone_id][sdk][platform][rc.cid] += 1
				end

				data.each do |zone_id, zdata|
					zdata.each do |sdk, sdata|
						sdata.each do |platform, pdata|
							pdata.each do |cid, num|
								cond = {
									:date => date, 
									:zone_id => zone_id, 
									:sdk => sdk,
									:platform => platform,
									:cid => cid
								}
								record = StatsModels::FinishCampaignSum.where(cond).first_or_initialize
				  			record.players = num
				  			record.save
							end
						end
					end
				end
			end

			puts "[ReportGenerator.gen_main_campaign_report]".color(:green)+" complete"
		end
	end
end