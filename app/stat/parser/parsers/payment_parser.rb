class PaymentParser
  include Stats::StatsParser
  include Stats::ExcludePlayers

   public

  def on_start
    @stats = {}
    @gains = {}
    @gain_players = {}
  end

  def parse_command(record_time, command, param)
    cid, pid, zone, gid, num, price, sdk, platform, market = param.split(",").map{|x| x.strip}
    zone_id = zone.to_i
    if player_exclude?(pid)
       
      return 
    end

    @stats[zone_id] ||= {}
    zdata = @stats[zone_id]
    zdata[pid] ||= {}
    pdata = zdata[pid]
    pdata[gid] ||= {:platform => platform,
                    :sdk => sdk,
                    :market => market,
                    :zone_id => zone_id,
                    :cid => cid,
                    :pid => pid,                          
                    :num => 0,
                    :goods => gid}
    pdata[gid][:num] += price.to_i
  end

  def get_goods_credits(tid)
    cfg = StatCommands.game_config
    t = cfg['chongzhi'][tid]
    t['reward_num']
  end

  def get_goods_name(tid)
    cfg = StatCommands.game_config
    t = cfg['chongzhi'][tid]
    t['name']
  end

  def on_finish
    date = @options[:date].to_date
    counter = 0

    @stats.each do |zone_id, zdata|
      zdata.each do |pid, pdata|
        pdata.each do |tid, data|
          counter += 1
          puts "#{Time.now} [PaymentParser] #{counter} ".color(:cyan) + "records has been saved" if counter % 1000 == 0

          goods = get_goods_name(data[:goods])
          rc_first = StatsModels::RechargeRecord.where(:zone_id => zone_id, :platform => data[:platform],
                                                        :pid => data[:pid], :goods => goods, :isnew => 1).first

          is_new = rc_first.nil?
          record = StatsModels::RechargeRecord.where(:date => date, :zone_id => zone_id, :platform => data[:platform],
                                                            :pid => data[:pid], :goods => goods).first_or_initialize
          record.market = data[:market]
          record.sdk = data[:sdk]
          record.cid = data[:cid]
          record.num += data[:num]
          record.days = (date - rc_first.date).to_i if !rc_first.nil?
          record.isnew = is_new
          record.first_date = date
          record.first_date = rc_first.date if !rc_first.nil?

          if record.total_num == 0 
            rc = StatsModels::RechargeRecord.select("sum(num) as total_num").where(" zone_id = #{data[:zone_id]} and platform = '#{data[:platform]}' 
                                                            and pid = '#{data[:pid]}' and goods = '#{goods}' and  
                                                            date < '#{date}' ").first
            record.total_num = rc.total_num if !rc.total_num.nil?
          end
          record.total_num ||= 0
          record.total_num += data[:num]
          record.save

          #某天某平台的总计报表
          record = StatsModels::RechargeReport.where(:date => date, :platform => data[:platform],
                                                          :goods => goods, :isnew => is_new).first_or_initialize
          record.num += data[:num]
          record.save

          #某天某sdk某平台的报表
          record = StatsModels::RechargeReport.where(:date => date, :sdk => data[:sdk], :platform => data[:platform],
                                                          :goods => goods, :isnew => is_new).first_or_initialize
          record.num += data[:num]
          record.save

          #某天某区某平台的报表                 
          record = StatsModels::RechargeReport.where(:date => date, :zone_id => zone_id, :platform => data[:platform],
                                                          :goods => goods, :isnew => is_new).first_or_initialize
          record.num += data[:num]
          record.save

          if is_new
            #某天某平台的总计报表
            record = StatsModels::RechargeReport.where(:date => date, :platform => data[:platform],
                                                            :goods => goods, :isnew => !is_new).first_or_initialize
            record.num += data[:num]
            record.save

            #某天某sdk某平台的报表
            record = StatsModels::RechargeReport.where(:date => date, :sdk => data[:sdk], :platform => data[:platform],
                                                            :goods => goods, :isnew => !is_new).first_or_initialize
            record.num += data[:num]
            record.save

            #某天某区某平台的报表                 
            record = StatsModels::RechargeReport.where(:date => date, :zone_id => zone_id, :platform => data[:platform],
                                                            :goods => goods, :isnew => !is_new).first_or_initialize
            record.num += data[:num]
            record.save
          end        
        end
      end
    end

    puts "#{Time.now} [PaymentParser] #{counter}".color(:cyan) + " records has been saved, commit finished" 
  end
end