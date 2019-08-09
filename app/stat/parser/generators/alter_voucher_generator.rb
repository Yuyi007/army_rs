module Stats
	module AlterVoucherGenerator
		def gen_alter_voucher_report
			gen_voucher_consume_report
			gen_voucher_gain_report
		end

		def gen_voucher_consume_report
			date = @options[:date].to_date
			records = StatsModels::RemoveItem.all.to_a
			gen_voucher_consume_report_by_records(records, date)
		end

		def gen_voucher_consume_report_by_records(records, date)
			each_zone_sdk_platform do |zone_id, sdk, platform|
				gen_voucher_consume_sys_report(date, zone_id, sdk, platform, records)
				gen_voucher_consume_level_report(date, zone_id, sdk, platform, records)
			end
			puts "[ReportGenerator.gen_voucher_consume_report]".color(:green)+" complete"
		end

		def gen_voucher_consume_sys_report(date, zone_id, sdk, platform, records)
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

				reason = rc.reason
				data[zone_id][sdk][platform][reason] ||= {:voucher => 0, :players => 0, :accounts => 0}
				players[zone_id][sdk][platform][reason] ||= {}
				accounts[zone_id][sdk][platform][reason] ||= {}

				tdata = data[zone_id][sdk][platform][reason]
				tplayer = players[zone_id][sdk][platform][reason]
				taccount = accounts[zone_id][sdk][platform][reason]

				
				tdata[:voucher] += rc.count
				pid, cid = Util.split_uid(rc.pid)

				if tplayer[pid].nil?
					tdata[:players] += 1
					tplayer[pid] = true
				end


				if taccount[cid].nil?
					tdata[:accounts] += 1
					taccount[cid] = true
				end
			end

			data.each do |zone_id, zdata|
				zdata.each do |sdk, sdata|
					sdata.each do |platform, pdata|
						pdata.each do |reason, rdata|
							record = StatsModels::AlterVoucherSys.where(:date => date, :zone_id => zone_id, 
																	 												:sdk => sdk, :platform => platform, :reason => reason).first_or_initialize
							record.voucher = -rdata[:voucher]
				      record.players = rdata[:players]
				      record.accounts = rdata[:accounts]
				      record.save
				    end
					end
				end
			end
		end

		def gen_voucher_consume_level_report(date, zone_id, sdk, platform, records)
			data = {}
			players = {}
			records.each do |rc|
				data[zone_id] ||= {}
				players[zone_id] ||= {}
				next if rc.zone_id != zone_id && zone_id != 0

				data[zone_id][sdk] ||= {}
				players[zone_id][sdk] ||= {}
				next if rc.sdk != sdk && sdk != 'all'

				data[zone_id][sdk][platform] ||= {}
				players[zone_id][sdk][platform] ||= {}
				next if rc.platform != platform && platform != 'all'

				reason = rc.reason
				data[zone_id][sdk][platform][reason] ||= {}
				players[zone_id][sdk][platform][reason] ||= {}

				level_rgn = 10
				level = rc.level
	      if level <= 20
	        level_rgn = (level.to_f/10).ceil*10
	      else
	        level_rgn = (level.to_f/5).ceil*5
	      end

	      data[zone_id][sdk][platform][reason][level_rgn] ||= { :sys_name => reason,
																	                            :players => 0,
																	                            :consume => 0}
				players[zone_id][sdk][platform][reason][level_rgn] ||= {}

				tdata = data[zone_id][sdk][platform][reason][level_rgn]
				tplayer = players[zone_id][sdk][platform][reason][level_rgn]

				
				tdata[:consume] += rc.count
				if tplayer[rc.pid].nil?
					tdata[:players] += 1
					tplayer[rc.pid] = true
				end
			end

			data.each do |zone_id, zdata|
				zdata.each do |sdk, sdata|
					sdata.each do |platform, pdata|
						pdata.each do |reason, rdata|
							rdata.each do |level_rgn, ldata|
								conditions ={
				            :date => date, 
				            :zone_id => zone_id, 
										:sdk => sdk, 
										:platform => platform,
				            :cost_type => 'voucher', 
				            :sys_name => ldata[:sys_name],
				            :level_rgn => level_rgn,
				          } 
				        record = StatsModels::ConsumeLevels.where(conditions).first_or_initialize
				        record.date = date
			          record.players = ldata[:players]
			          record.consume = -ldata[:consume]
			          record.save
							end
						end
					end
				end
			end
		end

		def gen_voucher_gain_report_by_records(records, date)
			each_zone_sdk_platform do |zone_id, sdk, platform|
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

					reason = rc.reason
					data[zone_id][sdk][platform][reason] ||= {:voucher => 0, :players => 0, :accounts => 0}
					players[zone_id][sdk][platform][reason] ||= {}
					accounts[zone_id][sdk][platform][reason] ||= {}

					tdata = data[zone_id][sdk][platform][reason]
					tplayer = players[zone_id][sdk][platform][reason]
					taccount = accounts[zone_id][sdk][platform][reason]

					tdata[:voucher] += rc.count
					pid, cid = Util.split_uid(rc.pid)

					if tplayer[pid].nil?
						tdata[:players] += 1
						tplayer[pid] = true
					end


					if taccount[cid].nil?
						tdata[:accounts] += 1
						taccount[cid] = true
					end
				end

				data.each do |zone_id, zdata|
					zdata.each do |sdk, sdata|
						sdata.each do |platform, pdata|
							pdata.each do |reason, rdata|
								record = StatsModels::GainVoucherSys.where(:date => date, :zone_id => zone_id, 
																	 												:sdk => sdk, :platform => platform, :reason => reason).first_or_initialize
				        record.voucher = rdata[:voucher]
				        record.players = rdata[:players]
				        record.accounts = rdata[:accounts]
				        record.save
							end
						end
					end
				end
			end
			puts "[ReportGenerator.gen_voucher_gain_report]".color(:green)+" complete"
		end

		def gen_voucher_gain_report
			date = @options[:date].to_date
			records = StatsModels::AddItem.all.to_a
			gen_voucher_gain_report_by_records(records, date)
		end
	end
end