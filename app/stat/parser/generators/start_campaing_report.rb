module Stats
	module StartCampaignGenerator
		def gen_start_campaign_report
			date = @options[:date].to_date
			records = StatsModels::StartCampaign.all.to_a
			gen_start_campaign_report_by_records(records, date)

			records = StatsModels::CityCampaign.all.to_a
			gen_campaign_city_report_by_records(records, date)
		end

		def gen_start_campaign_report_by_records(records, date)
			each_zone_sdk_platform do |zone_id, sdk, platform|
				gen_start_campaign_sum_report(date, zone_id, sdk, platform, records)
				gen_boss_practice_report(date, zone_id, sdk, platform, records)
				gen_campaign_level_report(date, zone_id, sdk, platform, records)
			end
			puts "[ReportGenerator.gen_start_campaign_report]".color(:green)+" complete"
		end

		def gen_campaign_city_report_by_records(records, date)
			each_zone_sdk_platform do |zone_id, sdk, platform|
				gen_campaign_city_report(date, zone_id, sdk, platform, records)
			end
			puts "[ReportGenerator.gen_campaign_city_report]".color(:green)+" complete"
		end

		def gen_campaign_city_report(date, zone_id, sdk, platform, records)
			data = {}
			records.each do |rc|
				data[zone_id] ||= {}
				next if rc.zone_id != zone_id && zone_id != 0
				
				data[zone_id][sdk] ||= {}
				next if rc.sdk != sdk && sdk != 'all'

				data[zone_id][sdk][platform] ||= {}
				next if rc.platform != platform && platform != 'all'

				data[zone_id][sdk][platform][rc.city_id] ||= {}
				data[zone_id][sdk][platform][rc.city_id][rc.kind] ||= {:players => 0, :count => 0}
				
				tdata = data[zone_id][sdk][platform][rc.city_id][rc.kind]

				tdata[:players] += rc.players
				tdata[:count] += rc.count
			end

			data.each do |zone_id, zdata|
				zdata.each do |sdk, sdata|
					sdata.each do |platform, pdata|
						pdata.each do |cid, cdata|
							cdata.each do |kind, kdata|
								record = StatsModels::CityCampaignReport.new
								record.date = date
								record.platform = platform
								record.sdk = sdk
								record.zone_id = zone_id
								record.kind = kind 
								record.players = kdata[:players]
								record.count = kdata[:count]
								record.city_id = cid
								record.save
							end
						end
					end
				end
			end
		end

		def gen_campaign_level_report(date, zone_id, sdk, platform, records)
			data = {}
			records.each do |rc|
				next if rc.kind != 'leader' && rc.kind != 'practice'

				data[zone_id] ||= {}
				next if rc.zone_id != zone_id && zone_id != 0
				
				data[zone_id][sdk] ||= {}
				next if rc.sdk != sdk && sdk != 'all'

				data[zone_id][sdk][platform] ||= {}
				next if rc.platform != platform && platform != 'all'

				data[zone_id][sdk][platform][rc.kind] ||= {}
				data[zone_id][sdk][platform][rc.kind][rc.level_rgn] ||= {:count => 0, :players => 0}

				tdata = data[zone_id][sdk][platform][rc.kind][rc.level_rgn]
				tdata[:players] += 1
				tdata[:count] += rc.count
			end

			data.each do |zone_id, zdata|
				zdata.each do |sdk, sdata|
					sdata.each do |platform, pdata|
						pdata.each do |kind, kdata|
							kdata.each do |level_rgn, ldata|
								cond = {
									:sdk => sdk,
									:platform => platform,
									:date => date, 
									:zone_id => zone_id, 
									:kind => kind, 
									:level_rgn => level_rgn
								}	
								record = StatsModels::LevelCampaignReport.where(cond).first_or_initialize
								record.count = ldata[:count]
								record.players = ldata[:players]
								record.save
							end
						end
					end
				end
			end
		end

		def gen_boss_practice_report(date, zone_id, sdk, platform, records)
			data = {}
			records.each do |rc|
				next if rc.kind != 'leader' && rc.kind != 'practice'

				data[zone_id] ||= {}
				next if rc.zone_id != zone_id && zone_id != 0
				
				data[zone_id][sdk] ||= {}
				next if rc.sdk != sdk && sdk != 'all'

				data[zone_id][sdk][platform] ||= {}
				next if rc.platform != platform && platform != 'all'

				data[zone_id][sdk][platform][rc.kind] ||= {:players => {}, :accounts => {}}

				players = data[zone_id][sdk][platform][rc.kind][:players]
				accounts = data[zone_id][sdk][platform][rc.kind][:accounts]

				pid, cid = Util.split_uid(rc.pid)
				players[pid] ||= rc.count

				accounts[cid] ||= 0
				accounts[cid] += rc.count
			end

			result = {}
			data.each do |zone_id, zdata|
				result[zone_id] ||= {}

				zdata.each do |sdk, sdata|
					result[zone_id][sdk] ||= {}

					sdata.each do |platform, pdata|
						result[zone_id][sdk][platform] ||= {}

						pdata.each do |kind, kdata|
							next if kind != 'leader' && kind != 'practice'
							result[zone_id][sdk][platform][kind] ||= {}

							kdata.each do |pa, paData|
								result[zone_id][sdk][platform][kind][pa] ||= {:count1 => 0,
																                              :count2 => 0,
																                              :count3 => 0,
																                              :count4 => 0,
																                              :count5 => 0,
																                              :count6 => 0,
																                              :count7 => 0,
																                              :count8 => 0,
																                              :count_more => 0}		

                d = result[zone_id][sdk][platform][kind][pa]																		                              	
								paData.each do |paid, count|
									if count == 1
				            d[:count1] += 1
				          elsif count == 2
				            d[:count2] += 1
				          elsif count == 3
				            d[:count3] += 1
				          elsif count == 4
				            d[:count4] += 1
				          elsif count == 5
				            d[:count5] += 1
				          elsif count == 6
				            d[:count6] += 1
				          elsif count == 7
				            d[:count7] += 1
				          elsif count == 8
				            d[:count8] += 1
				          elsif count > 8
				            d[:count_more] += 1
				          end
								end
							end
						end
					end
				end
			end

			map_kind_attr = {
				'leader' => 'boss',
				'practice' => 'practice'
			}

			result.each do |zone_id, zdata|
				zdata.each do |sdk, sdata|
					sdata.each do |platform, pdata|
						pdata.each do |kind, kdata|
							kdata.each do |pa, paData|
								cond = {
									:date => date, 
									:zone_id => zone_id,
									:sdk => sdk,
									:platform => platform
								}

								p = (pa == :players) && 'p' || ''
								cat = map_kind_attr[kind]
								record = StatsModels::BossPracticeReport.where(cond).first_or_initialize
								paData.each do |k, count|
									key = "#{k}#{p}_#{cat}="
									# puts ">>>key:#{key} pa:#{pa} count:#{count}"
									record.send(key, count)
								end
								record.save
							end
						end
					end
				end
			end
		end

		def gen_start_campaign_sum_report(date, zone_id, sdk, platform, records)
			data = {}
			players = {}
			accounts = {}

			records.each do |rc|
				data[zone_id] ||= {}
				players[zone_id] ||= {}
				accounts[zone_id] ||= {}
				next if rc.zone_id != zone_id && zone_id != 0

				data[zone_id][sdk] ||= {}
				players[zone_id][sdk] ||= {}
				accounts[zone_id][sdk] ||= {}
				next if rc.sdk != sdk && sdk != 'all'

				data[zone_id][sdk][platform] ||= {}
				players[zone_id][sdk][platform] ||= {}
				accounts[zone_id][sdk][platform] ||= {}
				next if rc.platform != platform && platform != 'all'

				data[zone_id][sdk][platform][rc.kind] ||= {:count => 0, :players => 0, :accounts => 0}
				players[zone_id][sdk][platform][rc.kind] ||= {}
				accounts[zone_id][sdk][platform][rc.kind] ||= {}

				kdata = data[zone_id][sdk][platform][rc.kind]
				kplayer = players[zone_id][sdk][platform][rc.kind]
				kaccount = players[zone_id][sdk][platform][rc.kind]

				kdata[:count] += rc.count

				pid, cid = Util.split_uid(rc.pid)
				if !kplayer[pid]
					kdata[:players] += 1
					kplayer[pid] = true
				end

				if !kaccount[cid]
					kdata[:accounts] += 1
					kaccount[cid] = true
				end
			end

			data.each do |zone_id, zdata|
				zdata.each do |sdk, sdata|
					sdata.each do |platform, pdata|
						pdata.each do |kind, kdata|
							cond = {
								:date => date, 
								:zone_id => zone_id, 
								:sdk => sdk, 
								:platform => platform, 
								:kind => kind
							}
							record = StatsModels::StartCampaignSumReport.where(cond).first_or_initialize
							record.players = kdata[:players]
							record.accounts = kdata[:accounts]
							record.count = kdata[:count]
							record.save
						end
					end
				end
			end
		end
	end
end
