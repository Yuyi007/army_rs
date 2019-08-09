require_relative 'stats_req'

class StatsorignController < ApplicationController

  def total_active
  end

  def get_date(date)
    t = date
    wday = t.wday
    while wday != 1 do
      t = Time.at(t.to_i - 24 * 60 * 60)
      wday = t.wday
    end

    [t.to_date.to_time.to_i, (Time.now.to_date + 1).to_time.to_i]
  end

  def get_total_active
    return ng('verify fail') if !check_session

    str_date = params[:date]
    date = Time.parse(str_date)
    counts_user = 0
    counts_account = 0

    week_start_date, week_end_date = get_date(date)

    sql = %Q{
              select count(sid) as counts from zone_users
              where unix_timestamp(last_login_at) >=  #{week_start_date} and unix_timestamp(last_login_at) < #{week_end_date}
            }
    rcs = execSql(sql)
    if !rcs.nil?
      rchs = rcs.to_hash
      rc = rchs[0]
      counts_user = rc["counts"]
    end

    sql = %Q{
              select count(sid) as counts from zone_accounts
              where unix_timestamp(last_login_at) >=  #{week_start_date} and unix_timestamp(last_login_at) < #{week_end_date}
            }
    rcs = execSql(sql)
    if !rcs.nil?
      rchs = rcs.to_hash
      rc = rchs[0]
      counts_account = rc["counts"]
    end
    puts ">>>>counts_user:#{counts_user} counts_account:#{counts_account}"
    sendc({'success' => 'ok', 'counts_user' => counts_user, 'counts_account' => counts_account })
  end

  def get_sdk_plats
    return ng('verify fail') if !check_session

    res = {}
    sdks = StatsModels::Sdk.where("sdk is not null").select("distinct sdk").order(:sdk)
    if sdks.length > 0
      ss = []
      sdks.each do |sdk|
        ss << Mysql.escape_string(sdk.sdk) unless sdk.sdk.nil? || sdk.sdk == ''
      end
      res['sdks'] = ss
    end

    platforms = StatsModels::Platform.where("platform is not null").select("distinct platform").order(:platform)
    if platforms.length > 0
      plats = []
      platforms.each do |platform|
        plats << Mysql.escape_string(platform.platform)  unless platform.platform.nil? or platform.platform == ''
      end
      res['platforms'] = plats
    end
    
    markets = StatsModels::Market.where("market is not null").select("distinct market").order(:market)
    if markets.length > 0
      mks = []
      markets.each do |market|
        unless market.market.nil? or market.market == ''
          m = market.market.gsub(/\"/, '')
          mks << Mysql.escape_string(m)
        end
      end
      res['markets'] = mks
    end

    zones = []
    cfg_zones.each do |z|
      zones << z["name"]
    end
    res['zones'] = zones

    sendc({'success' => 'ok', 'res' => res })
  end

  def get_active_report
    return ng('verify fail') if !check_session
    start_date = params[:start_date]
    end_date = params[:end_date]
    cat_sp = params[:cat_sp]
    cat_act = params[:cat_act]
    return ng('invalid args') if cat_act.nil? || cat_sp.nil? || start_date.nil? || end_date.nil?

    
    start_date = DateTime.parse(start_date).to_date
    start_date = start_date.strftime('%Y-%m-%d')

    end_date = DateTime.parse(end_date).to_date
    end_date = end_date.strftime('%Y-%m-%d')

    cat_act = Mysql.escape_string(cat_act)

    arr = cat_sp.split('#')
    key_type = arr[0].to_sym
    key_value = Mysql.escape_string(arr[1])

    table_name = "#{cat_act}_" << (key_type == :all ? "" : "#{key_type}_")<< "activity_reports"
    condition = (key_type == :all) ? "" : "where a.#{key_type} = #{key_type == :zone_id ? key_value : "'#{key_value}'"}"
    condition += (key_type == :all) ? "where " : " and "
    condition += " a.date>='#{start_date}' and a.date<='#{end_date}'"

    sql = %Q{
          select  a.date as date,
                  a.total as total_count,
                  a.num_m5 as m5,
                  a.num_m10 as m10,
                  a.num_m15 as m15,
                  a.num_m20 as m20,
                  a.num_m25 as m25,
                  a.num_m30 as m30,
                  a.num_m35 as m35,
                  a.num_m40 as m40,
                  a.num_m45 as m45,
                  a.num_m50 as m50,
                  a.num_m55 as m55,
                  a.num_m60 as m60,
                  a.num_m120 as m120 ,
                  a.num_m180 as m180,
                  a.num_m300 as m300,
                  a.m300plus as m300plus
          from #{table_name} a #{condition}
          order by a.date desc
      }
    puts ">>>>sql:#{sql}"
    rcs = execSql(sql)
    res = {'success' => 'ok'}
    res['res'] = {}
    res['res'] = rcs.to_hash if !rcs.nil?
    sendc(res)
  end

  def get_retention_report
    return ng('verify fail') if !check_session
    cat_sp = params[:cat_sp]
    cat_act = params[:cat_act]
    return ng('invalid args') if cat_act.nil? || cat_sp.nil?

    cat_act = Mysql.escape_string(cat_act)
    arr = cat_sp.split('#')
    key_type = arr[0].to_sym
    key_value = Mysql.escape_string(arr[1])

    table_name = "#{cat_act}_" << (key_type == :all ? "" : "#{key_type}_") << "retention_reports"
    condition = (key_type == :all) ?  "" : "where a.#{key_type} = #{key_type == :zone_id ? key_value : "'#{key_value}'"}"

    sql = %Q{
          select a.date as date,
                 a.num_d0 as total_count,
                 concat(TRUNCATE(((a.num_d1 / a.num_d0) * 100), 2), '%') as d1,
                 concat(TRUNCATE(((a.num_d2 / a.num_d0) * 100), 2), '%') as d2,
                 concat(TRUNCATE(((a.num_d3 / a.num_d0) * 100), 2), '%') as d3,
                 concat(TRUNCATE(((a.num_d4 / a.num_d0) * 100), 2), '%') as d4,
                 concat(TRUNCATE(((a.num_d5 / a.num_d0) * 100), 2), '%') as d5,
                 concat(TRUNCATE(((a.num_d6 / a.num_d0) * 100), 2), '%') as d6,
                 concat(TRUNCATE(((a.num_d7 / a.num_d0) * 100), 2), '%') as w1,
                 concat(TRUNCATE(((a.num_d14 / a.num_d0) * 100), 2), '%') as w2,
                 concat(TRUNCATE(((a.num_d30 / a.num_d0) * 100), 2), '%') as m1,
                 concat(TRUNCATE(((a.num_d90 / a.num_d0) * 100), 2), '%') as m3
          from #{table_name} a
          #{condition}
          order by a.date desc
      }
    puts ">>>>sql:#{sql}"
    rcs = execSql(sql)
    res = {'success' => 'ok'}
    res['res'] = {}
    res['res'] = rcs.to_hash if !rcs.nil?
    sendc(res)
  end

  def get_chief_level_report
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
          from chief_level_report
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

end