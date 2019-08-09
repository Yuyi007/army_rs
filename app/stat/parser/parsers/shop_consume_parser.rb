class ShopConsumeParser
  include Stats::StatsParser
  include Stats::ExcludePlayers
  include Stats::GeneratorHelper   
  include Stats::ShopConsumeGenerator

  public

  def on_start
    @stats = {}
  end

  def parse_command(record_time, command, param)
    shop_id, tid, cost_type, count, consume, pid, zone_id, level = param.split(",").map{|x| x.strip}
    zone_id = zone_id.to_i
    level = level.to_i
    count = count.to_i
    consume = consume.to_i
    pid = pid.downcase
    return if player_exclude?(pid)

    @stats[zone_id] ||= []
    zdata = @stats[zone_id]
    zdata << {:zone_id => zone_id,
              :pid => pid,
              :tid => tid,
              :cost_type => cost_type,
              :count => count,
              :consume => consume,
              :shop_id => shop_id}
  end

  def on_finish
    date = @options[:date].to_date
    # StatsModels::ShopConsume.delete_all
    counter = 0
    all = []
    @stats.each do |zone_id, zdata|
      zdata.each do |data|
        player = StatsModels::ZoneUser.where(:sid => data[:pid].downcase).first
        next if player.nil? || player.sdk.nil? || player.platform.nil? 

        counter += 1
        puts "#{Time.now} [ShopConsumeParser] #{counter} ".color(:cyan) + "records has been saved" if counter % 1000 == 0
        record = StatsModels::ShopConsume.new

        record.date = date
        record.zone_id = zone_id
        record.sdk = player.sdk
        record.platform = player.platform
        record.shop_id = data[:shop_id]
        record.pid = data[:pid]
        record.tid = data[:tid]
        record.cost_type = data[:cost_type]
        record.count = data[:count]
        record.consume = data[:consume]
        # record.save
        all << record
      end
    end
    gen_shop_consume_report_by_records(all, date)
    puts "#{Time.now} [ShopConsumeParser] #{counter}".color(:cyan) + " records has been saved, commit finished"
  end

  def get_goods_name(tid)
    cfg = StatCommands.game_config
    items = cfg['goods']['items']
    item = items[tid]
    if item.nil? then
      puts "???shop item not exist"
      return tid
    end
    iid = item['item_tid']

    case iid
    when /^ite/
      cfg['items'][iid]['name']
    when /^pro/
      cfg['props'][iid]['name']
    when /^eqp/
      cfg['equips'][iid]['name']
    when /^bbe/
      cfg['garments'][iid]['name']
    else
      iid
    end
  end

  def get_shop_name(sid)
    cfg = StatCommands.game_config
    shops = cfg['shops']
    return sid if shops[sid].nil?
    return shops[sid]['name']
  end

  def get_cost_name(cid)
    cfg = StatCommands.game_config
    items = cfg['items']
    return cid if items[cid].nil?
    items[cid]['name']
  end

end