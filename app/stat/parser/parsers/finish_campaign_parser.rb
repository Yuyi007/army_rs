class FinishCampaignParser
  include Stats::StatsParser
  include Stats::ExcludePlayers
  include Stats::GeneratorHelper
  include Stats::MainCampaignGenerator

  public

  def on_start
    @stats = {}
    @players = {}

    @main_cids = {}
  end

  def parse_command(record_time, command, param)
    cid, win, type, pid, level, zone = param.split(",").map{|x| x.strip}
    return if player_exclude?(pid)
    
    win = (win == 'true')
    zone_id = zone.to_i
    @stats[zone_id] ||= {}
    @stats[zone_id][cid] ||= []

    @players[cid] ||= {}
    if win && @players[cid][pid].nil?     
      @stats[zone_id][cid] << pid
      @players[cid][pid] = true        
    end


    @main_cids[zone_id] ||= {}
    @main_cids[zone_id][pid] = cid
  end


  def on_finish
    date = @options[:date].to_date
    counter = 0

    batch = []
    @stats.each do |zone_id, zdata|
      zdata.each do |cid, pids|
        pids.each do |pid|
          player = StatsModels::ZoneUser.where(:sid => pid.downcase).first
          next if player.nil? || player.sdk.nil? || player.platform.nil? 

          counter += 1
          if counter % 1000 == 0
            # StatsModels::FinishCampaign.import(batch)
            # batch = []
            puts "#{Time.now} [FinishCampaignParser][FinishCampaign] #{counter} ".color(:cyan) + "records has been saved" 
          end

          record = StatsModels::FinishCampaign.new
          record.date = date
          record.zone_id = zone_id
          record.sdk = player.sdk
          record.platform = player.platform
          record.cid = cid
          batch << record
        end
      end
    end
    # StatsModels::FinishCampaign.import(batch)
    gen_main_campaign_report_by_records(batch, date)
    puts "#{Time.now} [FinishCampaignParser][FinishCampaign] #{counter}".color(:cyan) + " records has been saved, commit finished"     


    @main_cids.each do |zone_id, zdata|
      zdata.each do |pid, cid|
        #玩家记录提供流失查询
        #main quest campaign
        cfg = StatCommands.game_config
        profile = cfg['campaigns'][cid]
        if profile && profile['display_type'] == 'main' 
          player_record = StatsModels::PlayerRecord.where(:pid => pid.downcase, :kind => 'main_quest_campaign').first_or_initialize
          player_record.data = cid
          player_record.save
        end
      end
    end

    puts "#{Time.now} [FinishCampaignParser][PlayerRecord] #{counter}".color(:cyan) + " records has been saved, commit finished" 
  end
end