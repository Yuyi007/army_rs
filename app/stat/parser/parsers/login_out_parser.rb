class  LoginoutParser
  include Stats::StatsParser
  include Stats::ExcludePlayers

   public

  def on_start
    @users = {}
    @accounts = {}
    @devices = {}

    @user_flag = {}
    @account_flag = {}
    @device_flag = {}

    @stats = {}
    @players = {}
    @accounts_counter = {}

    @players1 = {}
    @stats1 = {}
    @players_level_info = {}
  end

  def parse_command(record_time, command, param)
    case command
    when 'login'
      parse_login(record_time, param)
    when 'logout'
      parse_logout(record_time, param)
    when 'game_data'
      parse_game_data(record_time, param)
    end
  end


  def parse_login(record_time, param)
    pid, zone_id, sid, platform, sdk, market = param.split(",").map{|x| x.strip}
    zone_id = zone_id.to_i
    market = nil #market.tr('"', '') unless market.nil?
    if player_exclude?(pid)
      return 
    end

    pid, cid = parse_pid(pid)
    # puts ">>>>cid:#{cid} pid:#{pid} zone_id:#{zone_id}, sid:#{sid}, platform:#{platform}, sdk:#{sdk}, market:#{market} "
    ### users
    @users[zone_id] ||= {}
    @users[zone_id][pid] ||= {}

    if not @users[zone_id][pid][:login_time] or record_time > @users[zone_id][pid][:login_time]
      @users[zone_id][pid][:login_time] = record_time
    end

    @users[zone_id][pid][:platform] ||= platform
    @users[zone_id][pid][:sdk] ||= sdk
    @users[zone_id][pid][:market] ||= market

    @users[zone_id][pid][:login_times] ||= 0
    @users[zone_id][pid][:login_times] += 1

    ### accounts
    @accounts[zone_id] ||= {}
    @accounts[zone_id][cid] ||= {}

    if not @accounts[zone_id][cid][:login_time] or record_time > @accounts[zone_id][cid][:login_time]
      @accounts[zone_id][cid][:login_time] = record_time
    end

    @accounts[zone_id][cid][:platform] ||= platform
    @accounts[zone_id][cid][:sdk] ||= sdk
    @accounts[zone_id][cid][:market] ||= market

    @accounts[zone_id][cid][:login_times] ||= 0
    @accounts[zone_id][cid][:login_times] += 1


    ### devices
    @devices[zone_id] ||= {}
    @devices[zone_id][sid] ||= {}

    if not @devices[zone_id][sid][:login_time] or record_time > @devices[zone_id][sid][:login_time]
      @devices[zone_id][sid][:login_time] = record_time
    end

    @devices[zone_id][sid][:platform] ||= platform
    @devices[zone_id][sid][:sdk] ||= sdk
    @devices[zone_id][sid][:market] ||= market

  end

  def parse_logout(record_time, param)
    pid, zone_id, platform, active_secs, sid = param.split(",").map{|x| x.strip}
    if player_exclude?(pid)
      return 
    end
    pid, cid = parse_pid(pid)
    zone_id = zone_id.to_i
    active_secs = active_secs.to_i


    if pid == cid 
      pid = nil
      [1,2,3].each do |i|
        pid = "#{zone_id}_#{cid}_i#{i}"
        break if @users[zone_id] && @users[zone_id][pid] 
      end
      return if pid.nil?
    end

    ### users
    @users[zone_id] ||= {}
    @users[zone_id][pid] ||= {}

    if (not @users[zone_id][pid][:logout_time] or record_time > @users[zone_id][pid][:logout_time])
      @users[zone_id][pid][:logout_time] = record_time
    end


    @users[zone_id][pid][:active_secs] ||= 0
    @users[zone_id][pid][:active_secs] += active_secs.to_i

    ### accounts
    @accounts[zone_id] ||= {}
    @accounts[zone_id][cid] ||= {}

    if (not @accounts[zone_id][cid][:logout_time] or record_time > @accounts[zone_id][cid][:logout_time])
      @accounts[zone_id][cid][:logout_time] = record_time
    end


    @accounts[zone_id][cid][:active_secs] ||= 0
    @accounts[zone_id][cid][:active_secs] += active_secs.to_i

    ### devices
    @devices[zone_id] ||= {}
    @devices[zone_id][sid] ||= {}

    if (not @devices[zone_id][sid][:logout_time] or record_time > @devices[zone_id][sid][:logout_time])
      @devices[zone_id][sid][:logout_time] = record_time
    end

    @devices[zone_id][sid][:active_secs] ||= 0
    @devices[zone_id][sid][:active_secs] += active_secs.to_i

  end

  def parse_game_data(record_time, param)
    uid, zone_id, device_id, platform, sdk,\
    city_evt_level, faction, level, credits, money, coins,\
    vip_level, login_days_count, continuous_login_days = param.split(",").map{|x| x.strip}
    # puts ">>>>vip_level:#{vip_level}"
    return if player_exclude?(uid)
      
    zone_id = zone_id.to_i
    uid, cid = parse_pid(uid)

    @users[zone_id] ||= {}
    @users[zone_id][uid] ||= {}
    usr = @users[zone_id][uid]

    usr[:level] = level.to_i
    usr[:money] = money.to_i
    usr[:credits] = credits.to_i
    usr[:coins] = coins.to_i
    usr[:vip_level] = vip_level.to_i
    usr[:login_days_count] = login_days_count.to_i
    usr[:continuous_login_days] = continuous_login_days.to_i
    usr[:faction] = faction

    @accounts[zone_id] ||= {}
    @accounts[zone_id][cid] ||= {}
    account = @accounts[zone_id][cid]

    account[:level] = level.to_i
    account[:money] = money.to_i
    account[:credits] = credits.to_i
    account[:coins] = coins.to_i
    account[:vip_level] = vip_level.to_i
    account[:login_days_count] = login_days_count.to_i
    account[:continuous_login_days] = continuous_login_days.to_i

    @players[zone_id] ||= {}
    pdata = @players[zone_id]
    pdata[uid] = faction

    @accounts_counter[zone_id] ||= {}
    pdata = @accounts_counter[zone_id]
    pdata[cid] = faction

    @players1[zone_id] ||= {}
    [@players1[zone_id]].each do |zdata|
      zdata ||= {}
      zdata[uid] ||= {:level => city_evt_level.to_i}
      if city_evt_level.to_i > zdata[uid][:level]
        zdata[uid][:level] = city_evt_level.to_i
      end
    end

    @players_level_info[zone_id] ||= {}
    @players_level_info[zone_id][sdk] ||= {}
    @players_level_info[zone_id][sdk][platform] ||= {}
    @players_level_info[zone_id][sdk][platform][uid] ||= {:level => 1, :city_event_level => 1}
    playe_data = @players_level_info[zone_id][sdk][platform][uid] 
    playe_data[:level] = level.to_i
    playe_data[:vip_level] = vip_level.to_i
    playe_data[:city_event_level] = city_evt_level
  end

  def each_user
    @users.each do |zone_id, data|
      next if zone_id <= 0

      data.each do |sid, user|
        next if sid.nil? or sid.strip.empty?
        yield(zone_id, sid, user)
      end
    end
  end

  def each_account
    @accounts.each do |zone_id, data|
      next if zone_id <= 0
      # puts ">>>>data:#{data}"
      data.each do |sid, account|
        next if sid.nil? or sid.strip.empty?
        yield(zone_id, sid, account)
      end
    end
  end

  def each_device
    @devices.each do |zone_id, data|
      next if zone_id < 0
      data.each do |sid, device|
        next if sid.nil? or sid.strip.empty?
        yield(zone_id, sid, device)
      end
    end
  end

  def on_finish
    date = @options[:date].to_date
    counter = 0
    each_user do |zone_id, sid, user|
      counter += 1
      if counter % 1000 == 0
        puts "#{Time.now} [LoginoutParser][ZoneUser] #{counter} ".color(:cyan) + "user records has been saved" 
      end

      batch(StatsModels::ZoneUser, {:sid => sid.downcase, :zone_id => zone_id}) do |zone_user|
        zone_user.reg_date ||= @options[:date]
        zone_user.last_login_at = user[:login_time] unless user[:login_time].nil?
        zone_user.last_logout_at = user[:logout_time] unless user[:logout_time].nil?
        zone_user.market = user[:market] unless user[:market].nil?
        zone_user.sdk = user[:sdk] unless user[:sdk].nil?
        zone_user.platform = user[:platform] unless user[:platform].nil?

        zone_user.active_days ||= 0
        zone_user.active_days += 1
        zone_user.login_times = user[:login_times] unless user[:login_times].nil?
        zone_user.total_login_times += user[:login_times] unless user[:login_times].nil?
        zone_user.active_secs = user[:active_secs] unless user[:active_secs].nil?
        zone_user.active_days = user[:active_days]
        zone_user.total_active_secs += user[:active_secs] unless user[:active_secs].nil?

        zone_user.level = user[:level] unless user[:level].nil?
        zone_user.money = user[:money] unless user[:money].nil?
        zone_user.credits = user[:credits] unless user[:credits].nil?
        zone_user.money = user[:money] unless user[:money].nil?
        zone_user.vip_level = user[:vip_level] unless user[:vip_level].nil?
        zone_user.login_days_count = user[:login_days_count] unless user[:login_days_count].nil?
        zone_user.continuous_login_days = user[:continuous_login_days] unless user[:continuous_login_days].nil?

        if zone_user.level
          #给用户按等级分组
          user_level = zone_user.level
          temp_1 = user_level/5
          temp_2 = user_level%5
          lower = 1
          upper = 5
          if temp_2 == 0
            upper = temp_1 * 5
            lower = upper - 4
          elsif temp_2 != 0
            lower = temp_1 * 5 + 1
            upper = lower + 4
          end
          group = "level:" + lower.to_s + "-" + upper.to_s
          zone_user.level_group = group
        end
      end
    end
    batch_commit(StatsModels::ZoneUser)
    puts "#{Time.now} [LoginoutParser][ZoneUser] #{counter}".color(:cyan) + " records has been saved, commit finished"

    counter  = 0 
    each_user do |zone_id, sid, user|
      counter += 1
      if counter % 1000 == 0
        puts "#{Time.now} [LoginoutParser][GameUser] #{counter} ".color(:cyan) + "user records has been saved" 
      end
      batch(StatsModels::GameUser, {:sid => sid.downcase}) do |game_user|
        game_user.reg_date ||= @options[:date]
        game_user.last_login_at = user[:login_time] unless user[:login_time].nil?
        game_user.last_logout_at = user[:logout_time] unless user[:logout_time].nil?

        if @user_flag[sid]
            game_user.active_secs += user[:active_secs] unless user[:active_secs].nil?
        else
            @user_flag[sid] = true
            game_user.active_secs = user[:active_secs] unless user[:active_secs].nil?
        end

        game_user.total_active_secs += user[:active_secs] unless user[:active_secs].nil?
        game_user.market ||= user[:market] unless user[:market].nil?
        game_user.sdk ||= user[:sdk] unless user[:sdk].nil?
        game_user.platform ||= user[:platform] unless user[:platform].nil?
      end
    end
    batch_commit(StatsModels::GameUser)
    puts "#{Time.now} [LoginoutParser][GameUser] #{counter}".color(:cyan) + " records has been saved, commit finished"
    
    counter = 0
    #玩家记录提供流失查询
    each_user do |zone_id, sid, user|
      #level
      if !user[:level].nil?
        counter += 1
        batch(StatsModels::PlayerRecord, {:pid => sid.downcase, :kind => 'hero_level'}) do |player_record|
          player_record.data = user[:level].to_s 
        end
      end
      #facton
      if !user[:faction].nil?
        counter += 1
        batch(StatsModels::PlayerRecord, {:pid => sid.downcase, :kind => 'faction'}) do |player_record|
          player_record.data = user[:faction] 
        end
      end
      if counter % 1000 == 0
        puts "#{Time.now} [LoginoutParser][PlayerRecord] #{counter} ".color(:cyan) + "player records has been saved" 
      end
    end
    batch_commit(StatsModels::PlayerRecord)
    puts "#{Time.now} [LoginoutParser][PlayerRecord] #{counter}".color(:cyan) + " records has been saved, commit finished"

    ### accounts
    counter_account = 0
    each_account do |zone_id, sid, account|
      counter_account += 1
      if counter_account % 1000 == 0
        puts "#{Time.now} [LoginoutParser][ZoneAccount] #{counter_account} ".color(:cyan) + "account records has been saved" 
      end

      zone_account = StatsModels::ZoneAccount.where(:sid => sid.downcase, :zone_id => zone_id).first_or_initialize
      zone_account.reg_date ||= @options[:date]
      zone_account.last_login_at = account[:login_time] unless account[:login_time].nil?
      zone_account.last_logout_at = account[:logout_time] unless account[:logout_time].nil?
      zone_account.market = account[:market] unless account[:market].nil?
      zone_account.sdk = account[:sdk] unless account[:sdk].nil?
      zone_account.platform = account[:platform] unless account[:platform].nil?

      zone_account.active_days ||= 0
      zone_account.active_days += 1
      zone_account.login_times = account[:login_times] unless account[:login_times].nil?
      zone_account.total_login_times += account[:login_times] unless account[:login_times].nil?
      zone_account.active_secs = account[:active_secs] unless account[:active_secs].nil?
      zone_account.active_days = account[:active_days]
      zone_account.total_active_secs += account[:active_secs] unless account[:active_secs].nil?

      zone_account.level = account[:level] unless account[:level].nil?
      zone_account.money = account[:money] unless account[:level].nil?
      zone_account.credits = account[:credits] unless account[:level].nil?
      zone_account.money = account[:money] unless account[:level].nil?
      zone_account.vip_level = account[:vip_level] unless account[:vip_level].nil?
      zone_account.login_days_count = account[:login_days_count] unless account[:level].nil?
      zone_account.continuous_login_days = account[:continuous_login_days] unless account[:level].nil?

      if zone_account.level
        #给用户按等级分组
        account_level = zone_account.level
        temp_1 = account_level/5
        temp_2 = account_level%5
        lower = 1
        upper = 5
        if temp_2 == 0
          upper = temp_1 * 5
          lower = upper - 4
        elsif temp_2 != 0
          lower = temp_1 * 5 + 1
          upper = lower + 4
        end
        group = "level:" + lower.to_s + "-" + upper.to_s
        zone_account.level_group = group
      end

      zone_account.save
    end
    puts "#{Time.now} [LoginoutParser][ZoneAccount] #{counter_account}".color(:cyan) + " records has been saved, commit finished"

    counter_account = 0
    each_account do |zone_id, sid, account|
      counter_account += 1
      if counter_account % 1000 == 0
        puts "#{Time.now} [LoginoutParser][GameAccount] #{counter_account} ".color(:cyan) + "account records has been saved" 
      end
      game_account = StatsModels::GameAccount.where(:sid => sid.downcase).first_or_initialize

      game_account.reg_date ||= @options[:date]
      game_account.last_login_at = account[:login_time] unless account[:login_time].nil?
      game_account.last_logout_at = account[:logout_time] unless account[:logout_time].nil?

      if @device_flag[sid]
          game_account.active_secs += account[:active_secs] unless account[:active_secs].nil?
      else
          @device_flag[sid] = true
          game_account.active_secs = account[:active_secs] unless account[:active_secs].nil?
      end

      game_account.total_active_secs += account[:active_secs] unless account[:active_secs].nil?
      game_account.market ||= account[:market] unless account[:market].nil?
      game_account.sdk ||= account[:sdk] unless account[:sdk].nil?
      game_account.platform ||= account[:platform] unless account[:platform].nil?

      game_account.save
    end
    puts "#{Time.now} [LoginoutParser][GameAccount] #{counter_account}".color(:cyan) + " records has been saved, commit finished"

    counter_device = 0
    each_device do |zone_id, sid, device|
      counter_device += 1
      if counter_device % 1000 == 0
        puts "#{Time.now} [LoginoutParser][ZoneDevice] #{counter_device} ".color(:cyan) + "device records has been saved" 
      end

      zone_device = StatsModels::ZoneDevice.where(:sid => sid, :zone_id => zone_id).first_or_initialize

      zone_device.reg_date ||= @options[:date]
      zone_device.last_login_at = device[:login_time] unless device[:login_time].nil?
      zone_device.last_logout_at = device[:logout_time] unless device[:logout_time].nil?
      zone_device.market = device[:market] unless device[:market].nil?
      zone_device.sdk = device[:sdk] unless device[:sdk].nil?
      zone_device.platform = device[:platform] unless device[:platform].nil?

      zone_device.active_days ||= 0
      zone_device.active_days += 1
      zone_device.active_secs = device[:active_secs] unless device[:active_secs].nil?
      zone_device.total_active_secs += device[:active_secs] unless device[:active_secs].nil?

      zone_device.save
    end
    puts "#{Time.now} [LoginoutParser][ZoneDevice] #{counter_device}".color(:cyan) + " records has been saved, commit finished"
      
    counter_device = 0
    each_device do |zone_id, sid, device|
      counter_device += 1
      if counter_device % 1000 == 0
        puts "#{Time.now} [LoginoutParser][GameDevice] #{counter_device} ".color(:cyan) + "device records has been saved" 
      end
      game_device = StatsModels::GameDevice.where(:sid => sid).first_or_initialize

      game_device.reg_date ||= @options[:date]
      game_device.last_login_at = device[:login_time] unless device[:login_time].nil?
      game_device.last_logout_at = device[:logout_time] unless device[:logout_time].nil?
      game_device.market ||= device[:market] unless device[:market].nil?
      game_device.sdk ||= device[:sdk] unless device[:sdk].nil?
      game_device.platform ||= device[:platform] unless device[:platform].nil?


      if @device_flag[sid]
        game_device.active_secs += device[:active_secs] unless device[:active_secs].nil?
      else
        @device_flag[sid] = true
        game_device.active_secs = device[:active_secs] unless device[:active_secs].nil?
      end

      game_device.save
    end
    puts "#{Time.now} [LoginoutParser][GameDevice] #{counter_device}".color(:cyan) + " records has been saved, commit finished"
    
    # puts ">>>>@players:#{@players}"
    @players.each do |zone_id, pdata|
      @stats[zone_id] ||= {}
      zdata = @stats[zone_id]
      pdata.each do |uid, faction|
        zdata[faction] ||= {:pnum => 0, :anum => 0}
        d = zdata[faction]
        d[:pnum] += 1
      end
    end

    @accounts_counter.each do |zone_id, pdata|
      @stats[zone_id] ||= {}
      zdata = @stats[zone_id]
      pdata.each do |cid, faction|
        zdata[faction] ||= {:pnum => 0, :anum => 0}
        d = zdata[faction]
        d[:anum] += 1
      end
    end

    counter = 0
    @stats.each do |zone_id, zdata|
      zdata.each do |faction, count|
        counter += 1
        if counter_device % 1000 == 0
          puts "#{Time.now}  [LoginoutParser][ActiveFactionReport]  #{counter} ".color(:cyan) + "records has been saved" 
        end
        record = StatsModels::ActiveFactionReport.where(:date => date, :zone_id => zone_id, :faction => faction).first_or_initialize
        record.date = date
        record.zone_id = zone_id
        record.count_by_player = count[:pnum]
        record.count_by_account = count[:anum]
        record.faction = faction
        record.save
      end
    end
    puts "#{Time.now} [LoginoutParser][ActiveFactionReport] #{counter}".color(:cyan) + "has been saved, commit finished"

    
    @players1.each do|zid, zdata|
      @stats1[zid] ||= {}
      zdata.each do|uid, udata|
        @stats1[zid][udata[:level]] ||= {:num => 0}
        @stats1[zid][udata[:level]][:num] += 1
      end
    end

    counter = 0
    @stats1.each do |zone_id, zdata|
      zdata.each do |level, data|
        counter += 1
        if counter % 1000 == 0
          puts "#{Time.now} [LoginoutParser][CityEventLevelReport] #{counter} ".color(:cyan) + "records has been saved" 
        end
        record = StatsModels::CityEventLevelReport.where(:date => date, :zone_id => zone_id, :level => level).first_or_initialize
        record.num = data[:num]
        record.save
      end
    end
    puts "#{Time.now} [LoginoutParser][CityEventLevelReport] #{counter}".color(:cyan) + " records has been saved, commit finished"

    #统计所有玩家等级 区别上面的活跃的等级
    counter = 0
    @players_level_info.each do |zone_id, zdata|
      zdata.each do |sdk, sdata|
        sdata.each do |platform, pdata|
          pdata.each do |pid, data|
            counter += 1
            if counter % 1000 == 0
              puts "#{Time.now} [LoginoutParser][AllPlayerLevelAndCityEventLevelReport] #{counter} ".color(:cyan) + "records has been saved" 
            end
            cond = {
              :pid => pid,
              :zone_id => zone_id,
              :sdk => sdk,
              :platform => platform
            }
            record = StatsModels::AllPlayerLevelAndCityEventLevelReport.where(cond).first_or_initialize
            record.level = data[:level]
            record.vip_level = data[:vip_level]
            record.city_event_level = data[:city_event_level]
            record.save
          end
        end
      end
    end

    puts "#{Time.now} [LoginoutParser][AllPlayerLevelAndCityEventLevelReport] #{counter}".color(:cyan) + " records has been saved, commit finished"
  end

end