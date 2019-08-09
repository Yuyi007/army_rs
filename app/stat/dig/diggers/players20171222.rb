require 'json'
# require 'simple_xlsx'

class  Players20171222
  include Stats::StatsParser

  protected

  def on_start
    @players = {}

    gen_targets()
  end

  def gen_targets()
    @targets = {}

    File.open('input.csv').each do |line|
      pid, sdk = line.split(',')

      raise "no pid or sdk: #{line}" if not pid or not sdk
      raise "invalid sdk: #{sdk}" if not sdk.is_a? String
      raise "duplicate pid: #{pid} #{sdk}" if @targets[pid]

      @targets[pid] = sdk
    end rescue nil
  end

  def check_targets(pid, sdk, platform)
    raise "invalid pid #{pid}!" if pid.nil?
    return false if pid == ''

    return true if @targets.size == 0
    raise "invalid sdk! #{sdk} #{@targets[pid]}" if sdk != nil and sdk != @targets[pid]

    raise "invalid platform! #{platform}" if platform != nil and platform != 'android'

    return false if not @targets[pid]
    return true
  end

  def parse_command(record_time, command, param)
    case command
    when 'login'
      parse_login(record_time, param)
    when 'logout'
      parse_logout(record_time, param)
    when 'game_data'
      parse_game_data(record_time, param)
    when 'levelup'
      parse_levelup(record_time, param)
    when 'payment'
      parse_payment(record_time, param)
    end
  end

  def parse_login(record_time, param)
    pid, zone_id, sid, platform, sdk, device_model, mem, gpu_model = param.split(",").map{|x| x.strip}

    return unless check_targets(pid, sdk, platform)

    @players[pid] ||= {}
    @players[pid][:sdk] = sdk
    @players[pid][:device_model] = device_model
    @players[pid][:mem] = mem
    @players[pid][:gpu_model] = gpu_model
  end

  def parse_logout(record_time, param)
    pid, zone_id, platform, active_secs, sid = param.split(",").map{|x| x.strip}

    return unless check_targets(pid, nil, platform)

    @players[pid] ||= {}
    @players[pid][:active_secs] ||= 0
    @players[pid][:active_secs] += active_secs.to_i
  end

  def parse_levelup(record_time, param)
    level, pid = param.split(",").map{|x| x.strip}
    level = level.to_i

    return unless check_targets(pid, nil, nil)

    @players[pid] ||= {}
    if @players[pid][:level] == nil || @players[pid][:level] < level
      @players[pid][:level] = level
    end
  end

  def parse_game_data(record_time, param)
    pid, zone_id, device_id, platform, sdk,\
    city_evt_level, faction, level, credits, money, coins,\
    vip_level, login_days_count, continuous_login_days = param.split(",").map{|x| x.strip}
    level = level.to_i

    return unless check_targets(pid, sdk, platform)

    @players[pid] ||= {}
    if @players[pid][:level] == nil || @players[pid][:level] < level
      @players[pid][:level] = level
    end
  end

  def parse_payment(record_time, param)
    cid, pid, zone_id, goods_id, _, price, sdk, platform = param.split(",").map{|x| x.strip}
    price = price.to_f

    return unless check_targets(pid, sdk, platform)

    @players[pid] ||= {}
    @players[pid][:recharge_count] ||= 0
    @players[pid][:recharge_count] += 1
    @players[pid][:recharge_amount] ||= 0
    @players[pid][:recharge_amount] += price
  end


  def on_finish
    File.open('output.csv', 'w+') do |f|
      @players.each do |pid, hash|
        c1 = hash[:sdk]
        c2 = hash[:level] || 0
        c3 = (hash[:active_secs] || 0) / 60
        c4 = hash[:recharge_count] || 0
        c5 = hash[:recharge_amount] || 0
        c6 = hash[:device_model]
        f.puts "#{pid}, #{c1}, #{c2}, #{c3}, #{c4}, #{c5}, #{c6}"
      end
    end

    # SimpleXlsx::Serializer.new("/users/wenjie/Downloads/Players20171122H1.xlsx") do |doc|
    #   rgns.each_with_index do |r, i|
    #     rdata = @data[i]
    #     doc.add_sheet("players_#{r}") do |sheet|
    #       sheet.add_row(%w{区 角色ID 等级 钞票 金砖 硬币 入市等级 职业 时间})
    #       rdata.each do |d|
    #         sheet.add_row([d[:zone], d[:pid], d[:level], d[:money], d[:credits], d[:coins], d[:city_evt_level], d[:faction], d[:mins], d[:sdk] ])
    #       end
    #     end
    #   end
    # end

  end

end