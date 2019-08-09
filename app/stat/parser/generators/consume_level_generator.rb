class ViewGenerator
  def gen_consume_level_view_by_zone(zone_id)
    sql = %Q{
      create or replace view #{zone_id}区各系统消费等级分布 as
        select  date as 日期,
                sys_name as 消费系统,
                cost_type as 货币品种,
                players as 消费人数,
                consume as 消费量,
                level_rgn as 等级段
        from consume_levels
        where zone_id = #{zone_id}
        order by date desc, sys_name asc, level_rgn asc
    }
    ActiveRecord::Base.connection.execute(sql)
  end
end