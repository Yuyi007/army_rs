
class  PurchaseVipParser
  include Stats::StatsParser
  include Stats::ExcludePlayers
  include Stats::GeneratorHelper 
  include Stats::VipPurchaseGenerator
   
  public

  def on_start
    @stats = {}
    @players = {}
  end

  def parse_command(record_time, command, param)
    zone, pid, tid, consume, platform, sdk = param.split(",").map{|x| x.strip}
    zone_id = zone.to_i
    return if player_exclude?(pid)
    
    @stats[zone_id] ||= {}
    @stats[zone_id][sdk] ||= {}
    @stats[zone_id][sdk][platform] ||= {}
    data = @stats[zone_id][sdk][platform]

    @players[zone_id] ||= {}
    @players[zone_id][sdk] ||= {}
    @players[zone_id][sdk][platform] ||= {}
    pdata = @players[zone_id][sdk][platform]


    data[tid] ||= {:num => 0, :players => 0, :consume => 0}
    tdata = data[tid]

    pdata[tid] ||= {}
    pdata = pdata[tid]

    tdata[:consume] += consume.to_i
    tdata[:num] += 1
    tdata[:players] += 1  if !pdata[pid]  

    pdata[pid] = true    
  end

  def on_finish
    counter = 0
    all = []
    date = @options[:date].to_date
    @stats.each do |zone_id, zdata|
      zdata.each do |sdk, sdata|
        sdata.each do |platform, pdata|
          pdata.each do |tid, data|
            counter += 1
            puts "#{Time.now} [PurchaseVipParser] #{counter}".color(:cyan) + " records has been saved" if counter % 1000 == 0
            cond = {
              :date => date, 
              :sdk => sdk,
              :platform => platform,
              :zone_id => zone_id, 
              :tid => tid
            }
            rc = StatsModels::VipPurchase.where(cond).first_or_initialize
            rc.num = data[:num]
            rc.players = data[:players]
            rc.consume = data[:consume]
            # rc.save
            all << rc
          end
        end
      end
    end
    gen_vip_purchase_report_by_records(all, date)
    puts "#{Time.now} [PurchaseVipParser] #{counter}".color(:cyan) + " records has been saved, commit finished" 
  end
end
