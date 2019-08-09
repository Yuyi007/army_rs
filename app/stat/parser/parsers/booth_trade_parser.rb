class BoothTradeParser
  include Stats::StatsParser
  include Stats::ExcludePlayers

   public

  def on_start
    @stats = {}
  end

  def parse_command(record_time, command, param)
    # puts ">>>param:#{param}"
    zone_id, buyer_id, seller_id, tid, count, price, time, level, grade, star = param.split(",").map{|x| x.strip}
    # puts ">>>buyer_id:#{buyer_id} seller_id:#{seller_id} tid:#{tid} count:#{count} price:#{price}"
    level = level.to_i
    grade = grade.to_i
    zone_id = zone_id.to_i
    count = count.to_i
    price = price.to_i

    return if player_exclude?(buyer_id)
    return if player_exclude?(seller_id)

    @stats[zone_id] ||= []
    zdata = @stats[zone_id]

    zdata << { :count => count.to_i, 
               :zone_id => zone_id,
               :buyer_id => buyer_id,
               :seller_id => seller_id,
               :tid => tid,
               :name => get_goods_name(tid),
               :price => price,
               :time => time,
               :level => level,
               :grade => grade,
               :star => star}
  end

  def get_goods_name(tid)
    cfg = StatCommands.game_config
    case tid 
    when /^ite/
      profile = cfg['items'][tid]
    when /^pro/
      profile = cfg['props'][tid]
    when /^eqp/
      profile = cfg['equips'][tid]
    when /^bbe/
      profile = cfg['garments'][tid]
    end

    return tid if profile.nil?
    profile['name']
  end

  def on_finish
    date = @options[:date].to_date
    counter = 0

    #delete 
    rcs = StatsModels::BoothTrades.where(:date => date)
    rcs.destroy_all if !rcs.nil?

    @stats.each do |zone_id, zdata|
      zdata.each do |data|
        counter += 1
        puts "#{Time.now} [BoothTradeParser] #{counter} ".color(:cyan) + "records has been saved" if counter % 1000 == 0
        record = StatsModels::BoothTrades.new
        record.date = date
        record.zone_id = zone_id
        record.seller_id = data[:seller_id]
        record.buyer_id = data[:buyer_id]
        record.name = data[:name]
        record.tid = data[:tid]
        record.count = data[:count]
        record.price = data[:price]
        record.time = data[:time]
        record.level = data[:level]
        record.grade = data[:grade]
        record.star = data[:star]
        record.save
      end
    end
    puts "#{Time.now} [BoothTradeParser] #{counter}".color(:cyan) + " records has been saved, commit finished" 
  end
end