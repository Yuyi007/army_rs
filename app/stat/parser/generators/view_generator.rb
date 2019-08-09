class ViewGenerator
  def initialize(options={})
    @options = options
    @config = options[:config]
    @date = nil
  end

  def gen_date_table
    sql = %Q{
      create table if not exists tmp_date( 
          date datetime
          )
      }
    ActiveRecord::Base.connection.execute(sql)
    str_date = @date.strftime("%Y-%m-%d")
    sql = "delete from tmp_date where date = '#{str_date}'"
    ActiveRecord::Base.connection.execute(sql)
    sql = "insert into tmp_date values ('#{str_date}')"
    ActiveRecord::Base.connection.execute(sql)
  end

  def gen_views
    @date = @options[:date].to_date
    gen_date_table

    zones = StatsModels::Zone.select("distinct zone_id").order(:zone_id)
    zones.each do |zone|
      gen_views_by_zone zone.zone_id
    end

    gen_views_by_all_zone

    sdks = StatsModels::Sdk.where("sdk is not null").select("distinct sdk").order(:sdk)
    if sdks.length > 1
      sdks.each do |sdk|
        unless sdk.sdk.nil? or sdk.sdk == ''
          puts "generating views for sdk: " << "#{sdk.sdk}".color(:cyan) << " ....."
          gen_activity_report_view(:sdk, Mysql.escape_string(sdk.sdk))
          gen_retention_report_view(:sdk, Mysql.escape_string(sdk.sdk))
        end
      end
    end

    platforms = StatsModels::Platform.where("platform is not null").select("distinct platform").order(:platform)

    if platforms.length > 1
      platforms.each do |platform|
        unless platform.platform.nil? or platform.platform == ''
          puts "generating views for platform: " << "#{platform.platform}".color(:cyan) << " ....."
          gen_activity_report_view(:platform, Mysql.escape_string(platform.platform))
          gen_retention_report_view(:platform, Mysql.escape_string(platform.platform)) 
        end
      end
    end

    markets = StatsModels::Market.where("market is not null").select("distinct market").order(:market)

    if markets.length > 1
      markets.each do |market|
        unless market.market.nil? or market.market == ''
          m = market.market.gsub(/\"/, '')
          puts "generating views for market: " << "#{market.market}".color(:cyan) << " ....."
          gen_activity_report_view(:market, Mysql.escape_string(m))
          gen_retention_report_view(:market, Mysql.escape_string(m))
        end
      end
    end
  end

  def drop_views
    records = ActiveRecord::Base.connection.execute("select table_name from information_schema.views;")

    records.each do |fields|
      ActiveRecord::Base.connection.execute("drop view if exists #{fields[0]}")
    end
  end

private
  def gen_views_by_all_zone
    gen_activity_report_view
    gen_retention_report_view
    gen_week_all_zone_active_user
    gen_week_old_user_lost
  end

  def gen_views_by_zone(zone_id)
    puts "generating views for zone: " << "#{zone_id}".color(:cyan) << " ....."
    gen_activity_report_view(:zone_id, zone_id)
    gen_retention_report_view(:zone_id, zone_id)

    gen_current_chief_level_reports_view(zone_id)
    gen_current_city_event_level_reports_view(zone_id)

    gen_credits_sys_consume_view(zone_id)
    gen_coins_sys_consume_view(zone_id)
    gen_money_sys_consume_view(zone_id)
    gen_voucher_sys_consume_view(zone_id)
    gen_shop_consume_views(zone_id)
    gen_start_campaign_view_by_zone(zone_id)
    gen_factions_view_by_zone(zone_id)
    gen_consume_level_view_by_zone(zone_id)
    gen_booth_trade_view_by_zone(zone_id)
    gen_main_quest_combat_view_by_zone(zone_id)
  end

  #每周老用户流失
  def gen_week_old_user_lost()

      date = @options[:date].wday

      # 每个星期一开始统计
      if date == 1 
        week_start_date = (@options[:date] - 24 * 60 * 60 * 7).to_i
        last_week_start_date = (@options[:date] - 24 * 60 * 60 * 14).to_i

        sql = %Q{
          create or replace view 每周老用户流失 as
            select  count(game_users.sid) as 老用户流失用户数
            from game_users
            where unix_timestamp(game_users.last_login_at) <  #{week_start_date} and unix_timestamp(game_users.last_login_at) >= #{last_week_start_date}
        }
        ActiveRecord::Base.connection.execute(sql)   
      end  
      
    end

  # 每周活跃用户数
  def gen_week_all_zone_active_user()
      view_name_prefix = "总体"

      date_1 = @options[:date].wday
      
      # puts "date_1 is ==== #{date_1}"
      # puts "***********************************************************"

      # 每个星期一开始统计上个星期的活跃用户数
      if date_1 == 1 
        week_start_date = (@options[:date] - 24 * 60 * 60 * 7).to_i
        week_end_date = @options[:date].to_i

        # start_date = (@options[:date] - 24 * 60 * 60 * 7).to_date
        # end_date = (@options[:date]).to_date
        # puts "week_start_date is === #{start_date}"
        # puts "week_end_date is === #{end_date}"
        # puts "week_start_date is === #{week_start_date}"
        # puts "week_end_date is === #{week_end_date}"

        sql = %Q{
          create or replace view #{view_name_prefix}每周活跃用户 as
            select  count(sid) as 当周活跃用户数量
            from zone_users
            where unix_timestamp(last_login_at) >=  #{week_start_date} and unix_timestamp(last_login_at) < #{week_end_date}
        }
        ActiveRecord::Base.connection.execute(sql)   
      end
    end

  def gen_activity_report_view(key_type = nil, key_value = nil)
    return if key_type == :zone_id and key_value == 999

    {:user => '玩家', :device => '设备', :new_user => '新玩家', :new_device => '新设备'}.each do |type, name|
      view_name = "#{"%d" % key_value}区#{name}" if key_type == :zone_id
      view_name = "#{key_value}_#{name}" unless key_type == :zone_id
      view_name = "#{name}总体" if key_type.nil? 
      table_name = "#{type}_" << (key_type.nil? ? "" : "#{key_type}_")<< "activity_reports"
      condition = key_type.nil? ? "" : "where a.#{key_type} = #{key_type == :zone_id ? key_value : "'#{key_value}'"}"

      sql = %Q{
        create or replace view #{view_name}活跃度报表 as
          select  a.date as date,
                  a.total as #{name}总数,
                  a.num_m5 as 5分钟以内,
                  a.num_m10 as 10分钟以内,
                  a.num_m15 as 15分钟以内,
                  a.num_m20 as 20分钟以内,
                  a.num_m25 as 25分钟以内,
                  a.num_m30 as 30分钟以内,
                  a.num_m35 as 35分钟以内,
                  a.num_m40 as 40分钟以内,
                  a.num_m45 as 45分钟以内,
                  a.num_m50 as 50分钟以内,
                  a.num_m55 as 55分钟以内,
                  a.num_m60 as 一小时以内,
                  a.num_m120 as 两小时以内,
                  a.num_m180 as 三小时以内,
                  a.num_m300 as 五小时以内,
                  a.m300plus as 五小时以上
          from #{table_name} a
          #{condition}
          order by a.date desc
      }

      ActiveRecord::Base.connection.execute(sql)
    end
  end

  def gen_retention_report_view(key_type = nil, key_value = nil)
    return if key_type == :zone_id and key_value == 999

    {:user => '玩家', :device => '设备'}.each do |type, name|
      view_name = "#{"%d" % key_value}区#{name}" if key_type == :zone_id
      view_name = "#{key_value}_#{name}" unless key_type == :zone_id
      view_name = "#{name}总体" if key_type.nil? 
      table_name = "#{type}_" << (key_type.nil? ? "" : "#{key_type}_") << "retention_reports"
      condition = key_type.nil? ? "" : "where a.#{key_type} = #{key_type == :zone_id ? key_value : "'#{key_value}'"}"

      sql = %Q{
        create or replace view #{view_name}留存率报表 as
          select a.date as 日期,
                 a.num_d0 as #{name}总数,
                 concat(TRUNCATE(((a.num_d1 / a.num_d0) * 100), 2), '%') as 次日留存率,
                 concat(TRUNCATE(((a.num_d2 / a.num_d0) * 100), 2), '%') as 二日留存率,
                 concat(TRUNCATE(((a.num_d3 / a.num_d0) * 100), 2), '%') as 三日留存率,
                 concat(TRUNCATE(((a.num_d4 / a.num_d0) * 100), 2), '%') as 四日留存率,
                 concat(TRUNCATE(((a.num_d5 / a.num_d0) * 100), 2), '%') as 五日留存率,
                 concat(TRUNCATE(((a.num_d6 / a.num_d0) * 100), 2), '%') as 六日留存率,
                 concat(TRUNCATE(((a.num_d7 / a.num_d0) * 100), 2), '%') as 七日留存率,
                 concat(TRUNCATE(((a.num_d14 / a.num_d0) * 100), 2), '%') as 十四日留存率,
                 concat(TRUNCATE(((a.num_d30 / a.num_d0) * 100), 2), '%') as 一月留存率,
                 concat(TRUNCATE(((a.num_d90 / a.num_d0) * 100), 2), '%') as 三月留存率
          from #{table_name} a
          #{condition}
          order by a.date desc
      }

      ActiveRecord::Base.connection.execute(sql)
    end
  end

   def gen_current_chief_level_reports_view(zone_id)
      view_name_prefix = "#{"%d" % zone_id}区"
      view_name_prefix = "总体" if zone_id == 999
      sql = %Q{
        create or replace view #{view_name_prefix}玩家等级人数分布报表 as
          select  date as 日期,
                  num as 玩家数量,
                  level as 玩家等级
          from chief_level_report
          where zone_id = #{zone_id}
          order by date desc
      }
      ActiveRecord::Base.connection.execute(sql)
    end

end