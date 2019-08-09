class ShareAwardParser
	include Stats::StatsParser
  include Stats::ExcludePlayers
  include Stats::GeneratorHelper
  include Stats::ShareAwardGenerator

  public

  def on_start
  	@stats = {}
  end

  def parse_command(record_time, command, param)
  	tid, zone, pid = param.split(",").map{|x| x.strip}
  	zone_id = zone.to_i
    return if player_exclude?(pid)
       
  	@stats[zone_id] ||= {}
    zdata = @stats[zone_id]

    zdata[tid] ||= []
    zdata[tid] << pid
  end

  def on_finish
  	date = @options[:date].to_date
    counter = 0

    all = []
    # StatsModels::ShareAward.delete_all

  	@stats.each do |zone_id, zdata|
  		zdata.each do |tid, tdata|
        tdata.each do |pid|
          player = StatsModels::ZoneUser.where(:sid => pid.downcase).first
          next if player.nil? || player.sdk.nil? || player.platform.nil? 
          
          counter += 1
          if counter % 1000 == 0
            # StatsModels::ShareAward.import(all)
            # all = []
            puts "#{Time.now} [ShareAwardParser] #{counter} ".color(:cyan) + "records has been saved" 
          end

    			record = StatsModels::ShareAward.new
          record.date = date
          record.zone_id = zone_id 
          record.sdk = player.sdk
          record.platform = player.platform 
          record.tid = tid

          all << record
        end
  		end
  	end
    # StatsModels::ShareAward.import(all)
    gen_share_award_report_by_records(all, date)
  	puts "#{Time.now} [ShareAwardParser] #{counter}".color(:cyan) + " records has been saved, commit finished" 
  end
end