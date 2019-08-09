require_relative 'stats_req'

class StatshelperController < ApplicationController
  include EnumLevel

  def _workable
    rc = StatsModels::SysFlags.where(:flag => 'today_gen_task').first_or_initialize
    return false if rc.nil?
    return true if rc.value == 'idle'
    return false
  end

  def _set_working
    rc = StatsModels::SysFlags.where(:flag => 'today_gen_task').first_or_initialize
    rc.value = 'working'
    rc.save
    puts ">>>>set gen today stats working!!!"
  end

  def get_lv_consume
    return ng('verify fail') if !check_session

    zone_id = params[:zone_id]
    cost_type = params[:cost_type]
    sys_name = params[:sys_name]
    date = params[:date]
    return ng('invalid args') if cost_type.nil? || sys_name.nil? || date.nil? || zone_id.nil?

    date = DateTime.parse(date).to_date
    date = date.strftime('%Y-%m-%d')
    sql = %Q{select * from consume_levels where zone_id=#{zone_id} and date='#{date}' and cost_type='#{cost_type}' and sys_name='#{sys_name}'}
    rcs = execSql(sql)
    # rcs = StatsModels::ConsumeLevels.where(:date => date, :cost_type => cost_type, :sys_name => sys_name)
    res = {'success' => 'ok'}
    res['res'] = {}
    res['res'] = rcs.to_hash if !rcs.nil?

    sendc(res)
  end

  def get_consume_report
    return ng('verify fail') if !check_session

    zone_id = params[:zone_id]
    sdk = params[:sdk]
    platform = params[:platform]
    cost_type = params[:cost_type]
    date = params[:date]
    return ng('invalid args') if cost_type.nil? || date.nil? || zone_id.nil?

    date = DateTime.parse(date).to_date
    date = date.strftime('%Y-%m-%d')
    sql = %Q{select * from consume_levels where
            zone_id=#{zone_id} and sdk='#{sdk}' and platform='#{platform}'
            and date='#{date}' and cost_type='#{cost_type}'}
    rcs = execSql(sql)

    res = {'success' => 'ok'}
    res['res'] = {}
    res['res'] = rcs.to_hash if !rcs.nil?
    sendc(res)
  end


  def get_city_level_report
    return ng('verify fail') if !check_session

    zone_id = params[:zone_id]
    date = params[:date]
    return ng('invalid args') if zone_id.nil? || date.nil?

    date = DateTime.parse(date).to_date
    date = date.strftime('%Y-%m-%d')

    sql = %Q{
        select  date as date,
                num as count,
                level as level
        from city_event_level_report
        where zone_id = #{Mysql.escape_string(zone_id)} and date = '#{date}'
        order by date desc
    }

    puts ">>>>sql:#{sql}"
    rcs = execSql(sql)
    res = {'success' => 'ok'}
    res['res'] = {}
    res['res'] = rcs.to_hash if !rcs.nil?
    sendc(res)
  end

  # args = {
  #     :zone_id => zone_id,
  #     :sdk  => sdk,
  #     :platform => platform,
  #     :categories => {'manual_reborn',
  #                     'buy_goods',
  #                     'taxi',
  #                     'currency_exchange_coins',
  #                     'currency_exchange_money'},
  #     :type_col => 'reason',
  #     :src_table => "alter_credits_sys",
  #     :columns => {'credits', 'players'}
  #   }
  def get_currency_report(args)
    zone_id = args["zone_id"]
    sdk = args["sdk"]
    platform = args["platform"]
    categories = args["categories"]
    type_col = Mysql.escape_string(args["type_col"])
    src_table = Mysql.escape_string(args["src_table"])
    columns = args["columns"]
    date_start = args["date_start"]
    date_end = args["date_end"]

    date_start = DateTime.parse(date_start).to_date
    date_end = DateTime.parse(date_end).to_date

    start_day = date_start.to_time.to_i
    end_day = date_end.to_time.to_i
    days = (end_day - start_day) / (24 * 60 * 60) + 1

    return {} if days > 100

    date_start = date_start.strftime('%Y-%m-%d')
    date_end = date_end.strftime('%Y-%m-%d')

    arg_cols = ""
    columns.each do |col|
      col = Mysql.escape_string(col)
      arg_cols += ", #{col}"
    end

    extra_cond = ''
    if !sdk.nil? && !platform.nil?
      extra_cond = "and sdk = '#{sdk}' and platform = '#{platform}'"
    end

    data = {}
    categories.each do |cat|
      cat = Mysql.escape_string(cat)
      sql = %Q{
                select date #{arg_cols} from #{src_table}
                where #{type_col} = '#{cat}' and zone_id = #{zone_id} #{extra_cond}
                and date >= '#{date_start}' and date <= '#{date_end}' order by date desc
              }
      rcs = execSql(sql)
      if !rcs.nil?
        data[cat] = rcs.to_hash
      end
    end

    ret = []
    date = end_day
    (0...days).each do |i|
      str_date = Time.at(date).to_date.strftime('%Y-%m-%d')
      record = {'date' => str_date}
      data.each do |cat, rcs|
        rc = nil
        rcs.each do |x|
          str = x["date"].strftime('%Y-%m-%d')
          if str == str_date
            rc = x
            break
          end
        end

        columns.each do |col|
          value = 0
          value = rc[col] if !rc.nil? && rc[col]
          record["#{cat}_#{col}"] = value
        end
      end
      ret << record
      date -= 24 * 60 * 60
    end

    puts ">>>ret:#{ret}"
    ret
  end





  def get_all_factions_report
    return ng('verify fail') if !check_session
    zone_id = params[:zone_id]
    sdk = params["sdk"]
    platform = params["platform"]
    date = params[:date]
    return ng('invalid args') if zone_id.nil? || date.nil?

    sql = %Q{
      select *
      from all_factions_report
      where zone_id = #{zone_id} and date <= '#{date}' and sdk = '#{sdk}' and platform = '#{platform}'
    }
    rcs = execSql(sql)
    
    res = {'success' => 'ok'}
    res['res'] = rcs.to_hash if !rcs.nil?
    sendc(res)
  end

  def get_currency_records
    return ng('verify fail') if !check_session
    args = params[:args]

    puts ">>>>args:#{args}"
    args = JSON.parse(args)

    ret = get_currency_report(args)

    res = {'success' => 'ok'}
    res['res'] = ret || {}
    sendc(res)
  end

  def get_main_quest_user_report
    return ng('verify fail') if !check_session
    args = params[:args]

    puts ">>>>args:#{args}"
    args = JSON.parse(args)

    zone_id = args["zone_id"]
    sdk = args["sdk"]
    platform = args["platform"]
    date = args["date"]

    date = DateTime.parse(date).to_date


    date = date.strftime('%Y-%m-%d')

    arg_cols = ""

    data = {}
    sql = %Q{
              select * from main_quest_users_report
              where zone_id = #{zone_id} and sdk = '#{sdk}' and platform = '#{platform}'
              and date = '#{date}' order by qid desc
            }
    rcs = execSql(sql)


    res = {'success' => 'ok'}
    res['res'] = rcs.to_hash if !rcs.nil?
    sendc(res)    
  end

  def get_chapter_request_report
    return ng('verify fail') if !check_session
    zone_id = params[:zone_id]
    sdk = params["sdk"]
    platform = params["platform"]
    date_start = params[:start_date]
    date_end = params[:end_date]

    return ng('invalid args') if zone_id.nil? || date_start.nil? || date_end.nil?

    date_end = DateTime.parse(date_end).to_date
    date_end = date_end.strftime('%Y-%m-%d')

    date_start = DateTime.parse(date_start).to_date
    date_start = date_start.strftime('%Y-%m-%d')


    sql = %Q{
        select  date as date,
                tid as tid,
                count as count
        from branch_quest_finish_report
        where zone_id = #{zone_id} and date >= '#{date_start}' and date <= '#{date_end}' and category ='chapterevent'
         and sdk = '#{sdk}' and platform = '#{platform}'
        order by date desc
    }
    rcs = execSql(sql)

    sql = %Q{
        select  date as date,
                tid as tid,
                count as count
        from create_branch_quest_report
        where zone_id = #{zone_id} and date >= '#{date_start}' and date <= '#{date_end}' and category ='chapterevent'
         and sdk = '#{sdk}' and platform = '#{platform}'
        order by date desc
    }
    create_branch_quest = execSql(sql)

    temp1 = []
    temp2 = []
    temp3 = {}
    temp4 = {}
    temp5 = {}
    temp6 = []

    if !rcs.nil?
      temp1 = rcs.to_hash
      temp2 = create_branch_quest.to_hash

      temp1.each do |v|
        key1 = v.date.to_s + "^" + v.tid
        temp3[key1] = v['count']
      end

      temp2.each do |v|
        key2 = v.date.to_s + "^" + v.tid
        temp4[key2] = v['count']
      end

      temp3.each do |k, v|
        temp5[k] = {}
        temp5[k]['finish_count'] = v
        create_branch_count = 0
        if temp4[k]
          create_branch_count = temp4[k]
        end

        temp5[k]['create_count'] = create_branch_count
      end

      temp4.each do |k, v|
        finish_count = 0
        if not temp5[k]
          temp5[k] = {}
          temp5[k]['finish_count'] = finish_count
          temp5[k]['create_count'] = v
        end
      end

      temp5.each do |k, v|
        value_array = k.split("^")
        temp_hash = {}
        temp_hash['date'] = value_array[0].to_date
        temp_hash['tid'] = value_array[1]
        temp_hash['create_count'] = v['create_count']
        temp_hash['finish_count'] = v['finish_count']
        temp6 << temp_hash
      end

    end
  # 用数据库操作会更好些，忘记怎么做数据库操作了。。。
    res = {'success' => 'ok'}
    res['res'] = {}
    res['res'] = temp6
    sendc(res)
  end


  def get_shop_consume
    return ng('verify fail') if !check_session
    zone_id = params[:zone_id]
    sdk = params[:sdk]
    platform = params[:platform]
    date = params[:date]
    date = DateTime.parse(date).to_date
    date = date.strftime('%Y-%m-%d')
    sql = %Q{
        select date as date, tid as goods, shop_id as shop, cost_type as cost, count as count, consume as consume, players as players from shop_consume_sum
        where zone_id = #{zone_id} and date = '#{date}' and sdk = '#{sdk}' and platform = '#{platform}'
        order by date desc, shop_id asc
    }
    rcs = execSql(sql)
    res = {'success' => 'ok'}
    res['res'] = {}
    res['res'] = rcs.to_hash if !rcs.nil?
    sendc(res)
  end

  def get_main_quest_cam
    return ng('verify fail') if !check_session
    zone_id = params[:zone_id]
    sdk = params[:sdk]
    platform = params[:platform]
    date_start = params[:start_date]
    date_end = params[:end_date]

    return ng('invalid args') if zone_id.nil? || date_start.nil? || date_end.nil?

    date_end = DateTime.parse(date_end).to_date
    date_end = date_end.strftime('%Y-%m-%d')

    date_start = DateTime.parse(date_start).to_date
    date_start = date_start.strftime('%Y-%m-%d')

    cfg = game_config
    cams = cfg['campaigns']
    mq_cams = []
    cams.each do |tid, c|
        mq_cams << tid if c['display_type'] == 'main'
    end

    conditions = ' and ('

    mq_cams.each_with_index do |tid, i|
        if i > 0 then
            conditions += ' or '
        end
        conditions += " cid = '#{tid}' "
    end
    conditions += ")"

    sql = %Q{
        select  date as date,
                cid as  campaign,
                players as count
        from finish_campaign_sum
        where zone_id = #{zone_id} and date >= '#{date_start}' and date <= '#{date_end}'  and sdk = '#{sdk}' and platform = '#{platform}' #{conditions}
        order by date desc, cid asc
    }
    rcs = execSql(sql)
    res = {'success' => 'ok'}
    res['res'] = {}
    res['res'] = rcs.to_hash if !rcs.nil?
    sendc(res)
  end

  def get_booth_trade
    return ng('verify fail') if !check_session
    zone_id = params[:zone_id]
    date_start = params[:start_date]
    date_end = params[:end_date]

    return ng('invalid args') if zone_id.nil? || date_start.nil? || date_end.nil?

    date_end = DateTime.parse(date_end).to_date
    date_end = date_end.strftime('%Y-%m-%d')

    date_start = DateTime.parse(date_start).to_date
    date_start = date_start.strftime('%Y-%m-%d')


    sql = %Q{
      select  date as date,
              seller_id as seller,
              buyer_id as buyer,
              tid as name,
              count as count,
              price as price,
              time  as time,
              grade as grade,
              level as level,
              star  as star
        from booth_trade
        where zone_id = #{zone_id} and date >= '#{date_start}' and date <= '#{date_end}'
        order by date desc
    }
    rcs = execSql(sql)
    res = {'success' => 'ok'}
    res['res'] = {}
    res['res'] = rcs.to_hash if !rcs.nil?
    sendc(res)
  end

  def get_boss_practice_report
    return ng('verify fail') if !check_session
    zone_id = params[:zone_id]
    date_start = params[:start_date]
    date_end = params[:end_date]
    sdk = params[:sdk]
    platform = params[:platform]

    return ng('invalid args') if zone_id.nil? || date_start.nil? || date_end.nil?

    date_end = DateTime.parse(date_end).to_date
    date_end = date_end.strftime('%Y-%m-%d')

    date_start = DateTime.parse(date_start).to_date
    date_start = date_start.strftime('%Y-%m-%d')


    sql = %Q{
        select *
        from boss_practice_report
        where zone_id = #{zone_id} and date >= '#{date_start}' and date <= '#{date_end}'
              and sdk = '#{sdk}' and platform = '#{platform}'
        order by date desc
    }
    rcs = execSql(sql)
    res = {'success' => 'ok'}
    res['res'] = {}
    res['res'] = rcs.to_hash if !rcs.nil?
    sendc(res)
  end



  def get_guild_level_record
    return ng('verify fail') if !check_session
    zone_id = params[:zone_id]
    date_start = params[:start_date]
    date_end = params[:end_date]

    return ng('invalid args') if zone_id.nil? || date_start.nil? || date_end.nil?

    date_end = DateTime.parse(date_end).to_date
    date_end = date_end.strftime('%Y-%m-%d')

    date_start = DateTime.parse(date_start).to_date
    date_start = date_start.strftime('%Y-%m-%d')


    sql = %Q{
        select *
        from guild_level_record
        where zone = #{zone_id} and record_date >= '#{date_start}' and record_date <= '#{date_end}'
        order by record_date desc
    }
    rcs = execSql(sql)
    res = {'success' => 'ok'}
    res['res'] = {}
    res['res'] = rcs.to_hash if !rcs.nil?
    sendc(res)
  end

  def get_guild_skill_record
    return ng('verify fail') if !check_session
    zone_id = params[:zone_id]
    sdk = params[:sdk]
    platform = params[:platform]
    date_start = params[:start_date]
    date_end = params[:end_date]

    return ng('invalid args') if zone_id.nil? || date_start.nil? || date_end.nil?

    date_end = DateTime.parse(date_end).to_date
    date_end = date_end.strftime('%Y-%m-%d')

    date_start = DateTime.parse(date_start).to_date
    date_start = date_start.strftime('%Y-%m-%d')


    sql = %Q{
        select *
        from guild_skill_report
        where zone_id = #{zone_id} and date >= '#{date_start}' and date <= '#{date_end}' 
        and sdk = '#{sdk}' and platform='#{platform}'
        order by date desc, skill_id asc
    }
    rcs = execSql(sql)
    res = {'success' => 'ok'}
    res['res'] = {}
    res['res'] = rcs.to_hash if !rcs.nil?
    sendc(res)
  end


  def get_guild_active_record
    return ng('verify fail') if !check_session
    zone_id = params[:zone_id]
    sdk = params[:sdk]
    platform = params[:platform]
    date_start = params[:start_date]
    date_end = params[:end_date]

    return ng('invalid args') if zone_id.nil? || date_start.nil? || date_end.nil?

    date_end = DateTime.parse(date_end).to_date
    date_end = date_end.strftime('%Y-%m-%d')

    date_start = DateTime.parse(date_start).to_date
    date_start = date_start.strftime('%Y-%m-%d')


    sql = %Q{
        select *
        from guild_active_report
        where zone_id = #{zone_id} and date >= '#{date_start}' and date <= '#{date_end}' and sdk = '#{sdk}' and platform='#{platform}' 
        order by date desc, guild_id asc
    }
    rcs = execSql(sql)
    res = {'success' => 'ok'}
    res['res'] = rcs.to_hash if !rcs.nil?
    sendc(res)
  end


  def get_level_campaign_report
    return ng('verify fail') if !check_session

    zone_id = params[:zone_id]
    date = params[:date]
    date = DateTime.parse(date).to_date
    date = date.strftime('%Y-%m-%d')

    sql = %Q{
      select * from level_campaign_report
      where zone_id = #{zone_id} and date = '#{date}'
      order by kind desc
    }
    rcs = execSql(sql)
    data = {}
    if !rcs.nil?
      rcs.each do |rc|
        data[rc.kind] ||= empty
        kdata = data[rc.kind]
        kdata[:kind] = rc.kind

        ldata = kdata[rc.level_rgn.to_s]
        ldata[:num] = rc['count']
        ldata[:players] = rc.players
      end
    end

    ret = []
    data.each{ |_, x| ret << x }

    res = {'success' => 'ok'}
    puts ">>>ret:#{ret}"
    res['res'] = ret
    sendc(res)
  end

  def get_city_campaign_report
    return ng('verify fail') if !check_session
    sdk = params[:sdk]
    platform = params[:platform]
    zone_id = params[:zone_id]
    date = params[:date]
    date = DateTime.parse(date).to_date
    date = date.strftime('%Y-%m-%d')

    sql = %Q{
      select * from city_campaign_report
      where zone_id = #{zone_id} and date = '#{date}' and sdk='#{sdk}' and platform='#{platform}'
      order by kind desc
    }
    rcs = execSql(sql)
    ret = []
    if !rcs.nil?
      rcs.each do |rc|
        d = {:kind => nil, :num => 0, :players => 0, :city => nil }
        d[:kind] = rc.kind
        d[:city] = rc.city_id
        d[:num] = rc['count']
        d[:players] = rc.players
        ret << d
      end
    end

    res = {'success' => 'ok'}
    puts ">>>ret:#{ret}"
    res['res'] = ret
    sendc(res)
  end

  def get_add_equip_report
    return ng('verify fail') if !check_session

    zone_id = params[:zone_id]
    date = params[:date]
    grade = params[:grade]
    star = params[:star]
    return ng('invalid_args') if zone_id.nil? || date.nil? || grade.nil? || star.nil?

    grade = grade.to_i
    star = star.to_i
    zone_id = zone_id.to_i

    date = DateTime.parse(date).to_date
    date = date.strftime('%Y-%m-%d')

    sql = %Q{
      select * from add_equip_report
      where zone_id = #{zone_id} and date = '#{date}' and grade = #{grade} and star = #{star}
    }
    rcs = execSql(sql)
    res = {'success' => 'ok'}
    res['res'] = {}
    res['res'] = rcs.to_hash if !rcs.nil?
    sendc(res)
  end

  def get_all_player_level_report
    return ng('verify fail') if !check_session
    zone_id = params[:zone_id]
    sdk = params[:sdk]
    platform = params[:platform]
    date = params[:end_date]

    return ng('invalid_args') if zone_id.nil? || date.nil?

    date = DateTime.parse(date).to_date
    date = date.strftime('%Y-%m-%d')

    sql = %Q{
      select * from all_player_level
      where zone_id = #{zone_id} and date = '#{date}' and sdk = '#{sdk}' and platform = '#{platform}'
    }
    rcs = execSql(sql)
    res = {'success' => 'ok'}
    res['res'] = {}
    res['res'] = rcs.to_hash if !rcs.nil?
    sendc(res)
  end

  def get_all_player_city_event_level_report

    return ng('verify fail') if !check_session
    zone_id = params[:zone_id]
    sdk = params[:sdk]
    platform = params[:platform]
    date = params[:end_date]

    return ng('invalid_args') if zone_id.nil? || date.nil?

    date = DateTime.parse(date).to_date
    date = date.strftime('%Y-%m-%d')

    sql = %Q{
      select * from all_city_event_level
      where zone_id = #{zone_id} and date = '#{date}' and sdk = '#{sdk}' and platform = '#{platform}'
    }
    rcs = execSql(sql)
    res = {'success' => 'ok'}
    res['res'] = {}
    res['res'] = rcs.to_hash if !rcs.nil?
    sendc(res)
  end

  def get_campaign_report
    return ng('verify fail') if !check_session
    zone_id = params[:zone_id]
    date = params[:date]  
    cat = params[:cat]
    cid = params[:cid]
    return ng('invalid_args') if zone_id.nil? || date.nil? || cat.nil? 

    date = DateTime.parse(date).to_date
    date = date.strftime('%Y-%m-%d')

    if cid.nil? || cid.empty?
      sql = %Q{
        select * from campaign_report
        where zone_id = #{zone_id} and date = '#{date}' and cat = '#{cat}'
      }
    else
      sql = %Q{
        select * from campaign_report
        where zone_id = #{zone_id} and date = '#{date}' and cat = '#{cat}' and cid = '#{cid}'
      }
    end

    rcs = execSql(sql)
    res = {'success' => 'ok'}
    res['res'] = {}
    res['res'] = rcs.to_hash if !rcs.nil?
    sendc(res)
  end

  def get_main_quest_report
    return ng('verify fail') if !check_session
    zone_id = params[:zone_id]
    date = params[:date]

    return ng('invalid_args') if zone_id.nil? || date.nil?
    
    date = DateTime.parse(date).to_date
    date = date.strftime('%Y-%m-%d')

    sql = %Q{
      select * from main_quest_report
      where zone_id = #{zone_id} and date = '#{date}'
    }
    rcs = execSql(sql)
    res = {'success' => 'ok'}
    res['res'] = {}
    res['res'] = rcs.to_hash if !rcs.nil?
    sendc(res)
  end

  def get_vip_level_report
    return ng('verify fail') if !check_session

    zone_id = params[:zone_id]
    sdk = params[:sdk]
    platform = params[:platform]
    date = params[:date]
    return ng('invalid args') if zone_id.nil? || date.nil?

    date = DateTime.parse(date).to_date
    date = date.strftime('%Y-%m-%d')

    sql = %Q{
          select  date as date,
                  num as count,
                  level as level
          from vip_level_report
          where zone_id = #{Mysql.escape_string(zone_id)} and sdk = '#{sdk}' and platform = '#{platform}' and date = '#{date}'
          order by level desc
      }

    puts ">>>>sql:#{sql}"
    rcs = execSql(sql)
    res = {'success' => 'ok'}
    res['res'] = {}
    res['res'] = rcs.to_hash if !rcs.nil?
    sendc(res)
  end

  def get_vip_purchase_report
    return ng('verify fail') if !check_session

    zone_id = params[:zone_id]
    sdk = params[:sdk]
    platform = params[:platform]
    date = params[:date]

    return ng('invalid args') if zone_id.nil? || date.nil?

    date = DateTime.parse(date).to_date
    date = date.strftime('%Y-%m-%d')

    sql = %Q{
          select * from vip_purchase_report
          where zone_id = #{Mysql.escape_string(zone_id)} and sdk = '#{sdk}' and platform = '#{platform}' and date = '#{date}'
          order by date desc
      }
    puts ">>>>sql:#{sql}"
    rcs = execSql(sql)
    res = {'success' => 'ok'}
    res['res'] = {}
    res['res'] = rcs.to_hash if !rcs.nil?
    sendc(res)
  end

  def get_share_award_report
    return ng('verify fail') if !check_session
    zone_id = params[:zone_id]
    sdk = params[:sdk]
    platform = params[:platform]

    date_start = params[:date_start]
    date_end = params[:date_end]

    date_start = DateTime.parse(date_start).to_date
    date_end = DateTime.parse(date_end).to_date

    date_start = date_start.strftime('%Y-%m-%d')
    date_end = date_end.strftime('%Y-%m-%d')

    sql = %Q{
          select * from share_award_report
          where zone_id = #{Mysql.escape_string(zone_id)} and date >= '#{date_start}' and date <= '#{date_end}'  and sdk = '#{sdk}' and platform = '#{platform}' 
          order by date desc
      }

    rcs = execSql(sql)
    res = {'success' => 'ok'}
    res['res'] = {}
    res['res'] = rcs.to_hash if !rcs.nil?
    sendc(res)
  end

  def get_born_quest_report
    return ng('verify fail') if !check_session
    zone_id = params[:zone_id]
    sdk = params[:sdk]
    platform = params[:platform]
    date = params[:date]
    date = DateTime.parse(date).to_date
    date = date.strftime('%Y-%m-%d')

    sql = %Q{
          select * from born_quest_report
          where zone_id = #{Mysql.escape_string(zone_id)} and date = '#{date}'  and sdk = '#{sdk}' and platform = '#{platform}'  
          order by date desc
      }

    rcs = execSql(sql)
    res = {'success' => 'ok'}
    res['res'] = {}
    res['res'] = rcs.to_hash if !rcs.nil?
    sendc(res)
  end
end