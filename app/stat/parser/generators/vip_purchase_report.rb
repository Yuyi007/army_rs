module Stats
	module VipPurchaseGenerator
		def gen_vip_purchase_report_by_records(records, date)
			each_zone_sdk_platform do |zone_id, sdk, platform|
				data = {}
				records.each do |rc|
					data[zone_id] ||= {}
					next if rc.zone_id != zone_id && zone_id != 0
					
					data[zone_id][sdk] ||= {}
					next if rc.sdk != sdk && sdk != 'all'

					data[zone_id][sdk][platform] ||= {}
					next if rc.platform != platform && platform != 'all'

					data[zone_id][sdk][platform][rc.tid] ||= {:players => 0, :num => 0, :consume => 0}
					tdata = data[zone_id][sdk][platform][rc.tid]

					tdata[:players] += rc.players
					tdata[:num] += rc.num
					tdata[:consume] += rc.consume
				end
			
				data.each do |zone_id, zdata|
					zdata.each do |sdk, sdata|
						sdata.each do |platform, pdata|
							pdata.each do |tid, tdata|
								cond = {
									:date => date, 
									:zone_id => zone_id, 
									:sdk => sdk, 
									:platform => platform, 
									:tid => tid
								}
								record = StatsModels::VipPurchaseReport.where(cond).first_or_initialize
								record[:players] = tdata[:players]
								record[:num] = tdata[:num]
								record[:consume] = tdata[:consume]
								record.save
							end
						end
					end
				end
			end
			puts "[ReportGenerator.gen_vip_purchase_report]".color(:green)+" complete"
		end

		def gen_vip_purchase_report
			date = @options[:date].to_date
			records = StatsModels::VipPurchase.all.to_a
			
			gen_vip_purchase_report_by_records(records, date)
		end
	end
end