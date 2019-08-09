class ViewGenerator
  def gen_main_quest_combat_view_by_zone(zone_id)
    conditions = ' and ('

    cfg = StatCommands.game_config
    cams = cfg["campaigns"]
    mq_cams = []
    cams.each do |tid, c|
        mq_cams << tid if c['display_type'] == 'main'
    end

    mq_cams.each_with_index do |tid, i|
        if i > 0 then
            conditions += ' or '
        end
        conditions += " cid = '#{tid}' "
    end
    conditions += ")"

    sql = %Q{
      create or replace view #{zone_id}区主线战斗通过人数 as
        select  date as 日期,
                cid as  战斗ID,
                players as 人数
        from finish_campaign_sum
        where zone_id = #{zone_id} #{conditions}
        order by date desc, cid asc
    }
    ActiveRecord::Base.connection.execute(sql)
  end
end