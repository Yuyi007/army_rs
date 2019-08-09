class RemoveItemParser
  include Stats::StatsParser
  include Stats::ExcludePlayers
  include Stats::GeneratorHelper    
  include Stats::AlterVoucherGenerator

  public  

  def on_start
    @stats = {}
    @user_consume = {}
  end

  def parse_command(record_time, command, param)
    reason, tid, count, total_count, cid, pid, zone_id, hero_level = param.split(",").map{|x| x.strip}
    return if player_exclude?(pid)
      
    reason = get_reason(reason, tid)
    zone_id = zone_id.to_i
    consume = count.to_i
    hero_level = hero_level.to_i
    pid = pid.downcase

    return if tid != 'ite1990001' 
    
    @stats[zone_id] ||= []
    zdata = @stats[zone_id]
    zdata << {
      :reason => reason,
      :zone_id => zone_id,
      :tid => tid,
      :count => consume,
      :pid => pid,
      :level => hero_level
    }

    if consume > 0
      @user_consume[zone_id] ||= {}
      zdata = @user_consume[zone_id]
      zdata[pid] ||= {}
      pdata = zdata[pid]
      pdata[reason] ||= { :zone_id => zone_id,
                            :sys_name => reason,
                            :cost_type => 'voucher',
                            :pid => pid,
                            :cid => cid,
                            :consume => 0}
      rdata = pdata[reason]
      rdata[:consume] += consume
    end
  end

  def on_finish
    date = @options[:date].to_date

    counter = 0
    @user_consume.each do |zone_id, zdata|
      zdata.each do |pid, pdata|
        pdata.each do |sys_name, rdata|
          player = StatsModels::ZoneUser.where(:sid => pid.downcase).first
          next if player.nil? || player.sdk.nil? || player.platform.nil? 

          counter += 1
          if counter % 1000 == 0
            puts "#{Time.now} [RemoveItemParser] user_consume  #{counter} ".color(:cyan) + "records has been saved"
          end
          data = {
            :zone_id => zone_id, 
            :sdk => player.sdk,
            :platform => player.platform,
            :sys_name => sys_name, 
            :pid => pid, 
            :cost_type => 'voucher'
          }
          record = StatsModels::UserConsume.where(data).first_or_initialize
          record.cid = rdata[:cid]
          record.consume += rdata[:consume]
          record.save
        end
      end
    end
    puts "#{Time.now} [RemoveItemParser] user_consume  #{counter} ".color(:cyan) + "records coimmit finished"


    all = []
    # StatsModels::RemoveItem.delete_all
    @stats.each do |zone_id, zdata|
      zdata.each do |data|
        player = StatsModels::ZoneUser.where(:sid => data[:pid].downcase).first
        next if player.nil? || player.sdk.nil? || player.platform.nil? 

        counter += 1
        if counter % 1000 == 0
          # StatsModels::RemoveItem.import(all)
          # all = []
          puts "#{Time.now} [RemoveItemParser] #{counter} ".color(:cyan) + "records has been saved" 
        end

        record = StatsModels::RemoveItem.new
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
    # StatsModels::RemoveItem.import(all)
    gen_voucher_consume_report_by_records(all, date)
    puts "#{Time.now} [RemoveItemParser] alter_voucher_sys  #{counter} ".color(:cyan) + "records has been saved" 

  end

  def get_reason(reason, tid)
    if tid == 'ite1990001' #代金券
      case reason
      when /^buy_goods_/
        return 'buy_goods'
      else
        return reason
      end
    end
    return reason
  end

end
