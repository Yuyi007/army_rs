class AddItemParser
  include Stats::StatsParser
  include Stats::ExcludePlayers
  include Stats::GeneratorHelper    
  include Stats::AlterVoucherGenerator

  public

  def on_start
    @stats = {}
    @players_map = {}
    @gain_sys = {}  #by chief id

    @gain_sys_by_pid = {} #by pid
  end

  def parse_command(record_time, command, param)
    reason, tid, count, total_count, pid, zone_id, hero_level = param.split(",").map{|x| x.strip}
    reason = get_reason(reason, tid)
    zone_id = zone_id.to_i
    pid = pid.downcase

    return  if player_exclude?(pid)

    consume = count.to_i
    return if tid != 'ite1990001' 
    @stats[zone_id] ||= []
    zdata = @stats[zone_id]

    zdata << {:count => count.to_i,
               :zone_id => zone_id,
               :reason => reason,
               :pid => pid,
               :level => hero_level.to_i}

  end

  def on_finish
    date = @options[:date].to_date
    counter = 0

    all = []
    # StatsModels::AddItem.delete_all
    @stats.each do |zone_id, zdata|
      zdata.each do |data|
        player = StatsModels::ZoneUser.where(:sid => data[:pid].downcase).first
        next if player.nil? || player.sdk.nil? || player.platform.nil? 

        counter += 1
        if counter % 1000 == 0
          # StatsModels::AddItem.import(all)
          # all = []
          puts "#{Time.now} [AddItemParser] #{counter} ".color(:cyan) + "records has been saved" 
        end
        record = StatsModels::AddItem.new
        record.date = date
        record.zone_id = zone_id
        record.sdk = player.sdk
        record.platform = player.platform
        record.reason = data[:reason]
        record.count = data[:count]
        record.pid = data[:pid]
        record.level = data[:level]
        all << record
      end
    end
    # StatsModels::AddItem.import(all)
    gen_voucher_gain_report_by_records(all, date)
    puts "#{Time.now} [AddItemParser] #{counter}".color(:cyan) + " records has been saved, commit finished"
  end

  def get_reason(reason, tid)
    if tid == 'ite1990001' #代金券
      case reason
      when 'yueli_overflow'
        return 'city_event'
      when 'npc_dialog'
        return 'city_event'
      else
        return reason
      end
    end
    return reason
  end
end