module Stats
	module ShopConsumeGenerator
		def gen_shop_consume_report_by_records(records, date)
			each_zone_sdk_platform do |zone_id, sdk, platform|
				data = {}
				records.each do |rc|
					data[zone_id] ||= {}
					next if rc.zone_id != zone_id && zone_id != 0
					
					data[zone_id][sdk] ||= {}
					next if rc.sdk != sdk && sdk != 'all'

					data[zone_id][sdk][platform] ||= {}
					next if rc.platform != platform && platform != 'all'

					data[zone_id][sdk][platform][rc.tid] ||= {:shop_id => rc.shop_id, :cost_type => rc.cost_type, :consume => 0, :count => 0, :players => 0}
					tdata = data[zone_id][sdk][platform][rc.tid]
					tdata[:count] += rc.count
					tdata[:consume] += rc.consume
					tdata[:players] += 1 
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
									:shop_id => tdata[:shop_id], 
									:tid => tid	
								}
								
								record = StatsModels::ShopConsumeSum.where(cond).first_or_initialize
          			record.count = tdata[:count]
          			record.consume = tdata[:consume]
          			record.players = tdata[:players]
          			record.save
							end
						end
					end
				end
			end
			puts "[ReportGenerator.gen_shop_consume_report]".color(:green)+" complete"
		end

		def gen_shop_consume_report
			date = @options[:date].to_date
			records = StatsModels::ShopConsume.all.to_a
			gen_shop_consume_report_by_records(records, date)
		end
	end
end

