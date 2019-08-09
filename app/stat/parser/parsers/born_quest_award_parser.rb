class BornQuestAwardParser
  include Stats::StatsParser
  include Stats::ExcludePlayers
  include Stats::GeneratorHelper 
  include Stats::BornQuestGenerator 


  public

  def on_start
    @stats_evt = {}
    @stats_rec = {}
	end

	def parse_command(record_time, command, param)
		cat, pid, zone_id, arg = param.split(",").map{|x| x.strip}
		zone_id = zone_id.to_i

		return if player_exclude?(pid)

		case cat
		when 'evt'
			parse_evt(pid, zone_id, arg)
		when 'rec'
			parse_rec(pid, zone_id, arg)
		end
	end

	def parse_evt(pid, zone_id, tid)
		@stats_evt[zone_id] ||= {}
		@stats_evt[zone_id][pid] ||= {}

		@stats_evt[zone_id][pid][tid] ||= 0
	end

	def parse_rec(pid, zone_id, percent)
		@stats_rec[zone_id] ||= {}
		@stats_rec[zone_id][pid] ||= {}

		percent = (percent.to_i / 10).floor
		@stats_rec[zone_id][pid][percent.to_s] ||= 0
	end

	def on_finish
		date = @options[:date].to_date
    counter = 0
    # StatsModels::BornQuest.delete_all
    all = []
		@stats_evt.each do |zone_id, zdata|
			zdata.each do |pid, pdata|
				player = StatsModels::ZoneUser.where(:sid => pid.downcase).first
        next if player.nil? || player.sdk.nil? || player.platform.nil? 

				pdata.each do |tid, num|
					counter += 1
					puts "#{Time.now} [BornQuestAwardParser] #{counter}".color(:cyan) + " records has been saved" if counter %500 == 0
					record = StatsModels::BornQuest.new
					record.zone_id = zone_id
					record.sdk = player.sdk
					record.platform = player.platform
					record.date = date
					record.tid = tid
					record.pid = pid
					# record.save
					all << record
				end
			end
		end


		@stats_rec.each do |zone_id, zdata|
			zdata.each do |pid, pdata|
				player = StatsModels::ZoneUser.where(:sid => pid.downcase).first
        next if player.nil? || player.sdk.nil? || player.platform.nil? 

        pdata.each do |percent, num|
					tid = "Percent_#{percent}"
					counter += 1
					puts "#{Time.now} [BornQuestAwardParser] #{counter}".color(:cyan) + " records has been saved" if counter %500 == 0
					record = StatsModels::BornQuest.new	
					record.zone_id = zone_id
					record.sdk = player.sdk
					record.platform = player.platform
					record.date = date
					record.tid = tid
					record.pid = pid
					# record.save
					all << record
				end
			end
		end

		gen_born_quest_report_by_records(all, date)
		puts "#{Time.now} [BornQuestAwardParser] #{counter}".color(:cyan) + " records has been saved, commit finished"
	end

end