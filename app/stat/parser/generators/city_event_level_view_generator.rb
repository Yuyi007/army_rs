class ViewGenerator
  def gen_current_city_event_level_reports_view(zone_id)
    view_name_prefix = "#{"%d" % zone_id}区"
    view_name_prefix = "总体" if zone_id == 999
    sql = %Q{
      create or replace view #{view_name_prefix}玩家入市等级人数分布报表 as
        select  date as 日期,
                num as 玩家数量,
                level as 玩家等级
        from city_event_level_report
        where zone_id = #{zone_id}
        order by date desc
    }
    ActiveRecord::Base.connection.execute(sql)
  end
end