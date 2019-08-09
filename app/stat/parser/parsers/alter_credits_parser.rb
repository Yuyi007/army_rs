require 'activerecord-import'
class AlterCreditParser
  include Stats::StatsParser
  include Stats::ExcludePlayers
  include Stats::GeneratorHelper
  include Stats::AlterCreditGenerator

  public

  def on_start
    @stats = {}
    @user_consume = {}
  end

  def parse_command(record_time, command, param)
    reason, value, credits, cid, pid, zone_id, hero_level = param.split(",").map{|x| x.strip}
    zone_id = zone_id.to_i
    hero_level = hero_level.to_i
    consume = value.to_i
    if consume < 0
      reason = get_reason_consume(reason)
    else
      reason = get_reason_gain(reason)
    end
    pid = pid.downcase

    return if player_exclude?(pid)

    #基础数据
    @stats[zone_id] ||= []
    zdata = @stats[zone_id]
    zdata << {  :credits => value.to_i, 
                :zone_id => zone_id,
                :reason => reason,
                :pid => pid,
                :level => hero_level}

    #玩家消费总计
    if consume < 0 
      @user_consume[zone_id] ||= {}
      zdata = @user_consume[zone_id]
      zdata[pid] ||= {}
      pdata = zdata[pid]
      pdata[reason] ||= { :zone_id => zone_id,
                            :sys_name => reason,
                            :cost_type => 'credits',
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
          puts "#{Time.now} [AlterCreditParser] user_consume  #{counter} ".color(:cyan) + "records has been saved"  if counter % 1000 == 0
          data = {
            :zone_id => zone_id, 
            :sdk => player.sdk,
            :platform => player.platform,
            :sys_name => sys_name, 
            :pid => pid, 
            :cost_type => 'credits'
          }
          record = StatsModels::UserConsume.where(data).first_or_initialize
          record.cid = rdata[:cid]
          record.consume += rdata[:consume]
          record.save
        end
      end
    end
    puts "#{Time.now} [AlterCreditParser] user_consume  #{counter} ".color(:cyan) + "records has been saved" 

    #每天的基础数据太多需要删除前一天的
    counter = 0
    all_consume = []
    all_gain = []
    # StatsModels::AlterCredits.delete_all
    @stats.each do |zone_id, zdata|
      zdata.each do |data|
        player = StatsModels::ZoneUser.where(:sid => data[:pid].downcase).first
        next if player.nil? || player.sdk.nil? || player.platform.nil? 

        counter += 1
        if counter % 1000 == 0
          # StatsModels::AlterCredits.import(all)
          # all = []
          puts "#{Time.now} [AlterCreditParser] #{counter} ".color(:cyan) + "records has been saved" 
        end
        record = StatsModels::AlterCredits.new
        record.date = date
        record.zone_id = zone_id
        record.sdk = player.sdk
        record.platform = player.platform
        record.reason = data[:reason]
        record.credits = data[:credits]
        record.pid = data[:pid]
        record.level = data[:level]
        # all << record
        if record.credits < 0  
          all_consume << record
        else
          all_gain << record
        end
      end
    end
    # StatsModels::AlterCredits.import(all)
    gen_credits_consume_report_by_records(all_consume, date)
    gen_credits_gain_report_by_records(all_gain, date)
    puts "#{Time.now} [AlterCreditParser] consume_levels  #{counter} ".color(:cyan) + "records has been saved"  
  end

  def get_reason_gain(reason)
    reason
  end

  def get_reason_consume(reason)
    case reason
    when /^buy_goods_/
      return "buy_goods"
    when /^guild_unlock_banner/
      return 'guild_banner'
    when /^guild_donate/
      return 'guild_donate'
    when 'buy_taxi_stop'
      return 'taxi'
    when 'begin_taxi'
      return 'taxi'
    else
      return reason
    end
  end
end