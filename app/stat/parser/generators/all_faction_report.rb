module Stats
	module AllFactionGenerator
		def gen_all_faction_report
			date = @options[:date].to_date
			records = StatsModels::AllFaction.all.to_a
			
			each_zone_sdk_platform do |zone_id, sdk, platform|
				data = {}
				accounts = {}
				records.each do |rc|
					data[zone_id] ||= {}
					accounts[zone_id] ||= {}
					next if rc.zone_id != zone_id && zone_id != 0

					data[zone_id][sdk] ||= {}
					accounts[zone_id][sdk] ||= {}
					next if rc.sdk != sdk && sdk != 'all'

					data[zone_id][sdk][platform] ||= {}
					accounts[zone_id][sdk][platform] ||= {}
					next if rc.platform != platform && platform != 'all'

					data[zone_id][sdk][platform][rc.faction] ||= {}
					data[zone_id][sdk][platform][rc.faction][:players] ||= 0
					data[zone_id][sdk][platform][rc.faction][:accounts] ||= 0

					hs = accounts[zone_id][sdk][platform]
					pid, cid = Util.split_uid(rc.pid)
					if hs[cid].nil?
						data[zone_id][sdk][platform][rc.faction][:accounts] += 1 
						hs[cid] = true
					end
				end

				data.each do |zone_id, zdata|
					zdata.each do |sdk, sdata|
						sdata.each do |platform, pdata|
							pdata.each do |faction, fdata|
								cond = {
									:date => date, 
									:zone_id => zone_id, 
									:sdk => sdk, 
									:platform => platform, 
									:faction => faction
								}
								record = StatsModels::AllFactionReport.where(cond).first_or_initialize
								record.players = fdata[:players]
								record.accounts = fdata[:accounts]
								record.save
							end
						end
					end
				end
			end
			
			puts "[ReportGenerator.gen_all_faction_report]".color(:green)+" complete"
		end
	end
end