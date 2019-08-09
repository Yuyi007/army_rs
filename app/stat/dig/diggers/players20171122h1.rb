require 'json'
# require 'simple_xlsx'

class  Players20171122H1
  include Stats::StatsParser

  protected

  def on_start
  	@users = {}
    @data = {}

    @data1 = {}
    @data2 = []
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
  	return if platform != 'android' 

    zone_id = zone_id.to_i
    market = market.tr('"', '') unless market.nil?
    pid, cid = parse_pid(pid)
    return if cid.nil? || pid.nil?

    @users[zone_id] ||= {}
    @users[zone_id][cid] ||= {}
    if not @users[zone_id][cid][:login_time] or record_time > @users[zone_id][cid][:login_time]
      @users[zone_id][cid][:login_time] = record_time
    end
    @users[zone_id][cid][:pid] ||= pid
    @users[zone_id][cid][:sdk] ||= sdk
    @users[zone_id][cid][:platform] ||= platform
    @users[zone_id][cid][:login_times] ||= 0
    @users[zone_id][cid][:login_times] += 1
  end


  def get_pid(x)
    @users.each do |zone, zdata|
      zdata.each do |pid, pdata|
        pid, cid = parse_pid(pid)
        if cid == x 
          return pid
        end
      end
    end
    return nil
  end

  def parse_logout(record_time, param)
  	pid, zone_id, platform, active_secs, sid = param.split(",").map{|x| x.strip}
    pid, cid = parse_pid(pid)
    zone_id = zone_id.to_i
    active_secs = active_secs.to_i

    @users[zone_id] ||= {}

    # full_pid = get_pid(pid)
    # if full_pid.nil?
    #   puts "cid cant not find login time:#{pid}"
    #   return 
    # end
    return if cid.nil? 
    return if @users[zone_id][cid].nil?

    @users[zone_id][cid] ||= {}
    if (not @users[zone_id][cid][:logout_time] or record_time > @users[zone_id][cid][:logout_time])
      @users[zone_id][cid][:logout_time] = record_time
    end

    @users[zone_id][cid][:active_secs] ||= 0
    @users[zone_id][cid][:active_secs] += active_secs.to_i
    # puts ">>>>full_pid:#{full_pid} active_secs:#{@users[zone_id][full_pid][:active_secs]}"
  end

  def parse_game_data(record_time, param)
    pid, zone_id, device_id, platform, sdk,\
    city_evt_level, faction, level, credits, money, coins,\
    vip_level, login_days_count, continuous_login_days = param.split(",").map{|x| x.strip}

    zone_id = zone_id.to_i
    pid, cid = parse_pid(pid)

    return if cid.nil? || pid.nil?

    @users[zone_id] ||= {}
    return if @users[zone_id][cid].nil?
    usr = @users[zone_id][cid]

    usr[:level] = level.to_i
    usr[:money] = money.to_i
    usr[:credits] = credits.to_i
    usr[:coins] = coins.to_i
    usr[:city_evt_level] = city_evt_level.to_i
    usr[:faction] = faction
  end


  def on_finish
    rgns = [5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55, 60]
    @users.each do |zone_id, zdata|
      zdata.each do |cid, pdata|
        #10级之内的详细用户，按级分
        lv = pdata[:level]
        if lv and lv <= 10
          @data1[lv] ||= []
          rdata = @data1[lv]

          d = {:zone => zone_id, :cid => cid, :mins => pdata[:active_secs]}
          pdata.each{|k,v| d[k] = v}

          rdata << d
        end

        #一个小时之内的详细用户
        if pdata[:active_secs].nil?
          puts "active seconds nil cid:#{cid}"
          next
        end

        #uc的详细用户
        d = {:zone => zone_id, :cid => cid, :mins => pdata[:active_secs]}
        pdata.each{|k,v| d[k] = v}
        @data2 << d 

        rgn_index = ((pdata[:active_secs] / 60).ceil/ 5).ceil
        puts ">>rgn_index:#{rgn_index} pdata[:active_secs]:#{pdata[:active_secs]}"
        if rgn_index < rgns.length
          @data[rgn_index] ||= []
          rdata = @data[rgn_index]

          d = {:zone => zone_id, :cid => cid, :mins => pdata[:active_secs]}
          pdata.each{|k,v| d[k] = v}

          rdata << d
        end
      end
    end

    
    # rgns.each_with_index do |r, i|
    #   rdata = @data[i]
    #   f=File.new(File.join("/users/wenjie/Downloads", "h1_#{r}.txt"), "w+")
    #   f.puts("区   角色ID    等级    钞票    金砖    硬币    入市等级    职业   时间")
    #   rdata.each do |d|
    #     f.puts("#{d[:zone]} #{d[:pid]}   #{d[:level]}  #{d[:money]}  #{d[:credits]}  #{d[:coins]}  #{d[:city_evt_level]}  #{d[:faction]}  #{d[:mins]}")
    #   end
    # end
    SimpleXlsx::Serializer.new("/users/wenjie/Downloads/Players20171122lv10.xlsx") do |doc|
      @data1.each do |lv, ldata|
        doc.add_sheet("players_#{lv}") do |sheet|
          sheet.add_row(%w{区 角色ID 等级 钞票 金砖 硬币 入市等级 职业 时间 平台})
          ldata.each do |d|
            sheet.add_row([d[:zone], d[:pid], d[:level], d[:money], d[:credits], d[:coins], d[:city_evt_level], d[:faction], d[:mins], d[:sdk] ])
          end
        end
      end
    end

    SimpleXlsx::Serializer.new("/users/wenjie/Downloads/Players20171122uc.xlsx") do |doc|
      doc.add_sheet("players_uc") do |sheet|
        sheet.add_row(%w{区 角色ID 等级 钞票 金砖 硬币 入市等级 职业 时间})
        @data2.each do |d|
          sheet.add_row([d[:zone], d[:pid], d[:level], d[:money], d[:credits], d[:coins], d[:city_evt_level], d[:faction], d[:mins], d[:sdk] ])
        end
      end
    end

    
    SimpleXlsx::Serializer.new("/users/wenjie/Downloads/Players20171122H1.xlsx") do |doc|
      rgns.each_with_index do |r, i|
        rdata = @data[i]
        doc.add_sheet("players_#{r}") do |sheet|
          sheet.add_row(%w{区 角色ID 等级 钞票 金砖 硬币 入市等级 职业 时间})
          rdata.each do |d|
            sheet.add_row([d[:zone], d[:pid], d[:level], d[:money], d[:credits], d[:coins], d[:city_evt_level], d[:faction], d[:mins], d[:sdk] ])
          end
        end
      end
    end

  end
end