class StartCampaignParser
  include Stats::StatsParser
  include Stats::ExcludePlayers
  include Stats::GeneratorHelper
  include Stats::StartCampaignGenerator
  
   public

  def on_start
    @stats = {}
    @citycamps = {} 
  end

  def parse_command(record_time, command, param)
    # puts ">>>>param:#{param}"
    cid, kind, pid, level, zone, level, city_id, guild_sid = param.split(",").map{|x| x.strip}
    hero_level = level.to_i
    zone_id = zone.to_i
    return if player_exclude?(pid)
        
    level_rgn = 10
    if hero_level <= 20
      level_rgn = (hero_level.to_f/10).ceil*10
    else
      level_rgn = (hero_level.to_f/5).ceil*5
    end

    @stats[zone_id] ||= {}
    @stats[zone_id][kind] ||= {}
    @stats[zone_id][kind][pid] ||= {}
    @stats[zone_id][kind][pid][level_rgn] ||= 0
    @stats[zone_id][kind][pid][level_rgn] += 1


    city_id = guild_sid if guild_sid && guild_sid != ''
    @citycamps[zone_id] ||= {}
    @citycamps[zone_id][kind] ||= {}
    @citycamps[zone_id][kind][pid] ||= {}
    @citycamps[zone_id][kind][pid][city_id] ||= 0
    @citycamps[zone_id][kind][pid][city_id] += 1
  end

  def on_finish
    date = @options[:date].to_date
    counter = 0
    # StatsModels::StartCampaign.delete_all
    batch = []
    @stats.each do |zone_id, zdata|
      zdata.each do |kind, kdata|
        kdata.each do |pid, pdata|
          player = StatsModels::ZoneUser.where(:sid => pid.downcase).first
          next if player.nil? || player.sdk.nil? || player.platform.nil? 
          

          pdata.each do |lv_rgn, num|
            counter += 1
            if counter % 1000 == 0
              # StatsModels::StartCampaign.import( batch )
              # batch = []
              puts "#{Time.now} [StartCampaignParser] #{counter} ".color(:cyan) + "records has been saved" 
            end
            record = StatsModels::StartCampaign.new
            record.date = date
            record.zone_id = zone_id
            record.sdk = player.sdk
            record.platform = player.platform
            record.pid = pid 
            record.kind = kind
            record.level_rgn = lv_rgn
            record.count = num
            batch << record
          end
        end
      end
    end
    # StatsModels::StartCampaign.import( batch )
    puts "#{Time.now} [StartCampaignParser][StartCampaign] #{counter}".color(:cyan) + " records has been saved, commit finished"
    gen_start_campaign_report_by_records(batch, date)

    # StatsModels::CityCampaign.delete_all
    batch = []
    tmp = {}
    counter = 0
    @citycamps.each do |zone_id, zdata|
      zdata.each do |kind, kdata|
        kdata.each do |pid, pdata|
          player = StatsModels::ZoneUser.where(:sid => pid.downcase).first
          next if player.nil? || player.sdk.nil? || player.platform.nil? 

          pdata.each do |cid, count|
            counter += 1
            if counter % 1000 == 0
              puts "#{Time.now} [StartCampaignParser] #{counter} ".color(:cyan) + "records has been saved" 
            end

            tmp[zone_id] ||= {}
            tmp[zone_id][sdk] ||= {}
            tmp[zone_id][sdk][platform] ||= {}
            tmp[zone_id][sdk][platform][kind] ||= {}
            tmp[zone_id][sdk][platform][kind][cid] ||= {:count => 0, :players => 0}

            tmp[zone_id][sdk][platform][kind][cid][:count]  += count
            tmp[zone_id][sdk][platform][kind][cid][:players] += 1
            cond = {
              :date => date, 
              :sdk => player.sdk, 
              :platform => player.platform,
              :zone_id => zone_id, 
              :kind => kind, 
              :city_id => cid
            }
            record = StatsModels::CityCampaign.where(cond).first_or_initialize
            record.count += count
            record.players += 1
            # record.save
            batch << record
          end
        end
      end
    end
    gen_campaign_city_report_by_records(batch, date)
    puts "#{Time.now} [StartCampaignParser][CityCampaign] #{counter}".color(:cyan) + " records has been saved, commit finished"
  end
end