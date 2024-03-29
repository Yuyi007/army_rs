class CreateQuestBranchParser
  include Stats::StatsParser
  include Stats::ExcludePlayers
  include Stats::GeneratorHelper    
  include Stats::CreateBranchQuestGenerator

  public

  def on_start
    @stats = {}
  end

  def parse_command(record_time, command, param)
    tid, category, sub_cat, pid, uid, zone_id, level = param.split(",").map{|x| x.strip}
    zone_id = zone_id.to_i
    return if player_exclude?(pid)
    
    @stats[zone_id] ||= {}
    @stats[zone_id][pid] ||= {}
    @stats[zone_id][pid][tid] ||= {:cat => sub_cat, :count => 0}
    @stats[zone_id][pid][tid][:count] += 1
  end


  def on_finish
    date = @options[:date].to_date

    data = {}
    @stats.each do |zone_id, zdata|
      data[zone_id] ||= {}
      zdata.each do |pid, pdata|
        player = StatsModels::ZoneUser.where(:sid => pid.downcase).first
        next if player.nil? || player.sdk.nil? || player.platform.nil? 

        data[zone_id][player.sdk] ||= {}
        data[zone_id][player.sdk][player.platform]||= {}

        pdata.each do |tid, tdata|
          data[zone_id][player.sdk][player.platform][tid] ||= {:cat => tdata[:cat], :count => 0}
          data[zone_id][player.sdk][player.platform][tid][:count] += tdata[:count]
        end
      end
    end

    cfg = StatCommands.game_config
    cfg_banch = cfg['branch_quests']['quests']
    counter = 0
    all = []
    data.each do |zone_id, zdata|
      zdata.each do |sdk, sdata|
        sdata.each do |platform, pdata|
          pdata.each do |tid, tdata|
            counter += 1
            if counter % 1000 == 0
              puts "#{Time.now} [CreateQuestBranchParser] #{counter}".color(:cyan) + " records has been saved" 
            end
            
            record = StatsModels::BranchQuestCreate.new
            record.zone_id = zone_id
            record.sdk = sdk
            record.platform = platform
            record.date = date
            
            profile = cfg_banch[tid]
            name = ''
            name = profile['name'] if !profile.nil?
            tid = "#{tid}_#{name}"

            record.tid = tid
            record.category = tdata[:cat]
            record.count = tdata[:count]
            all << record
          end
        end
      end
    end
    gen_create_branch_quest_report_by_records(all, date)
    puts "#{Time.now} [CreateQuestBranchParser] #{counter}".color(:cyan) + " records has been saved, commit finished"
  end
end