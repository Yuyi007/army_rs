require 'activerecord-import'
class AlterCoinsParser
  include Stats::StatsParser
  include Stats::ExcludePlayers
  include Stats::GeneratorHelper 
  include Stats::AlterCoinsGenerator

  public

  def on_start
    @stats = {}
    @user_consume = {}
  end

  def parse_command(record_time, command, param)
    reason, value, coins, cid, pid, zone_id, hero_level = param.split(",").map{|x| x.strip}
    zone_id = zone_id.to_i
    consume = value.to_i
    hero_level = hero_level.to_i
    pid = pid.downcase

    return if player_exclude?(pid)

    if consume < 0 
      reason = get_reason_consume(reason)
    else
      reason = get_reason_gain(reason)
    end

    #基础数据
    @stats[zone_id] ||= {}
    @stats[zone_id][pid] ||= {}
    @stats[zone_id][pid][reason] ||= {}
    @stats[zone_id][pid][reason][hero_level] ||= 0

    @stats[zone_id][pid][reason][hero_level] += value.to_i

    #玩家消费总计
    if consume < 0 
      @user_consume[zone_id] ||= {}
      zdata = @user_consume[zone_id]
      zdata[pid] ||= {}
      pdata = zdata[pid]
      pdata[reason] ||= { :zone_id => zone_id,
                            :sys_name => reason,
                            :cost_type => 'coins',
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
          puts "#{Time.now} [AlterCoinsParser][UserConsume] #{counter} ".color(:cyan) + "records has been saved" if counter % 1000 == 0
          data = {
            :zone_id => zone_id, 
            :sdk => player.sdk,
            :platform => player.platform,
            :sys_name => sys_name, 
            :pid => pid, 
            :cost_type => 'coins'
          }
          record = StatsModels::UserConsume.where(data).first_or_initialize
          record.cid = rdata[:cid]
          record.consume += rdata[:consume]
          record.save
        end
      end
    end
    puts "#{Time.now} [AlterCoinsParser][UserConsume] #{counter} ".color(:cyan) + "records has been saved"

    counter = 0 
    all_consume = []
    all_gain = []
    # StatsModels::AlterCoins.delete_all
    @stats.each do |zone_id, zdata|
      zdata.each do |pid, pdata|
        player = StatsModels::ZoneUser.where(:sid => pid.downcase).first
        next if player.nil? || player.sdk.nil? || player.platform.nil? 

        pdata.each do |reason, rdata|
          rdata.each do |level, coins|
            counter += 1
            if counter % 1000 == 0
              # StatsModels::AlterCoins.import(all)
              # all = []
              puts "#{Time.now} [AlterCoinsParser][AlterCoins] #{counter} ".color(:cyan) + "records has been saved" 
            end

            record = StatsModels::AlterCoins.new
            record.date = date
            record.zone_id = zone_id
            record.sdk = player.sdk
            record.platform = player.platform
            record.reason = reason
            record.coins = coins
            record.pid = pid
            record.level = level
            # all << record
            if record.coins < 0 
              all_consume << record
            else
              all_gain << record
            end
          end
        end
      end
    end
    # StatsModels::AlterCoins.import(all)
    gen_coins_consume_report_by_records(all_consume, date)
    gen_coins_gain_report_by_records(all_gain, date)
    puts "#{Time.now} [AlterCoinsParser][AlterCoins] consume_levels  #{counter} ".color(:cyan) + "records has been saved"

  end

  def get_reason_gain(reason)
    case reason
    when /^sell_slot_/
      return 'sell_slot'
    when 'enemy_drop_independent'
      return 'drop_chance'
    when 'finish_independent_campaign'
      return 'drop_chance'
    when 'enemy_drop_leader'
      return 'drop_boss'
    when 'finish_boss_cam'
      return 'drop_boss'
    when 'enemy_drop_review'
      return 'drop_review'
    when 'finish_review_campaign'
      return 'drop_review'
    when 'enemy_drop_shadow'
      return 'drop_shadow'
    when 'finish_shadow_cam'
      return 'drop_shadow'
    when 'enemy_drop_shadow_advance'
      return 'drop_shadow_advance'
    when 'finish_shadow_advance_cam'
      return 'drop_shadow_advance'
    when 'yueli_overflow'
      return 'city_event'
    when 'npc_dialog'
      return 'city_event'
    else
      return reason
    end
  end

  def get_reason_consume(reason)
    case reason
    when /^buy_goods_/
      cfg = StatCommands.game_config
      buy, goods, tid = reason.to_s.split('_').map{|x| x.strip}
      cfg_goods = cfg['goods']
      return reason if !cfg_goods 

      items = cfg['items']

      good = cfg_goods['items'][tid]
      return reason if good.nil?
      tid = good['item_tid']
      case tid
      when /^ite/
        cfg_item = items[tid]
        if cfg_item
          return "buy_goods_#{cfg_item['category']}"
        else
          return reason
        end
      when /^eqp/
        return 'buy_goods_eqp'
      when /^bbe/
        return 'buy_goods_bbe'
      else
        return reason
      end
    when /^buy_foods_/
      return 'buy_foods'
    when 'begin_taxi'
      return 'taxi'
    when 'buy_taxi_stop'
      return 'taxi'
    when 'coach_refesh'
      return 'coach'
    when 'pay_coach'
      return 'coach'
    else
      return reason
    end
  end
end