class ViewGenerator

  def gen_credits_sys_consume_view(zone_id)
    gen_credits_sys_consume_view_by_zone(zone_id)
    gen_credits_sys_gain_view_by_zone(zone_id)
  end



  def gen_credits_sys_gain_view_by_zone(zone_id)
    args = {
      :zone_id => zone_id,
      :view_name  => "#{zone_id}区金砖各系统获得",
      :categories => {'item_drop' => '礼包掉落'},
      :type_col => 'reason',
      :src_table => "gain_credits_sys",
      :columns => {'credits' => '获得', 'players' => '人数'}
    }
    tmp_gen_view_by_category_zone(args)
  end


  def gen_credits_sys_consume_view_by_zone(zone_id)
    args = {
      :zone_id => zone_id,
      :view_name  => "#{zone_id}区金砖各系统消耗",
      :categories => {'manual_reborn' => '复活', 
                      'buy_goods' => '商城',
                      'taxi' => '打车',
                      'currency_exchange_coins' => '兑换硬币',
                      'currency_exchange_money' => '兑换纸币'},
      :type_col => 'reason',
      :src_table => "alter_credits_sys",
      :columns => {'credits' => '消费', 'players' => '人数'}
    }
    tmp_gen_view_by_category_zone(args)

  end

  # def gen_total_credits_view
  #   zones = StatsModels::Zone.select("distinct zone_id").order(:zone_id)
  #   # zones.each_with_index do |zone, i|
  #   #   sql = %Q{drop table  if exists tmp_credits_#{i}}
  #   #   ActiveRecord::Base.connection.execute(sql)
  #   # end

  #   #生成一个0消耗的全表
  #   sql = %Q{
  #     create table if not exists tmp_credits(
  #         zone_id int(4), 
  #         date datetime, 
  #         credits int(4) not null default '0',
  #         players int(4) not null default '0'
  #         )
  #     }
  #   ActiveRecord::Base.connection.execute(sql)
  #   str_date = @date.strftime("%Y-%m-%d")
  #   zones.each_with_index do |zone, i|
  #     sql = "delete from tmp_credits where date = '#{str_date}'"
  #     ActiveRecord::Base.connection.execute(sql)
  #     sql = "insert into tmp_credits values (#{zone.zone_id}, '#{str_date}', 0, 0)"
  #     ActiveRecord::Base.connection.execute(sql)
  #   end

  #   zones.each_with_index do |zone, i|
  #     sql = %Q{
  #       create table if not exists tmp_credits_#{i} (
  #         zone_id int(4), 
  #         date datetime, 
  #         credits int(4) not null default '0',
  #         players int(4) not null default '0'
  #       ) 
  #     }
  #     ActiveRecord::Base.connection.execute(sql)

  #     sql = "delete from tmp_credits_#{i} where date = '#{str_date}'"
  #     ActiveRecord::Base.connection.execute(sql)

  #     sql = "insert into tmp_credits_#{i} select zone_id, date, credits, players from alter_credits_sum where zone_id = #{zone.zone_id} and date = '#{str_date}'"
  #     ActiveRecord::Base.connection.execute(sql)
  #   end


  #   columns = ' tb_x.date as date'
  #   zones.each_with_index do |zone, i|
  #     columns += ", ifnull(tb_#{i}.credits, 0) as #{zone.zone_id}区总消费, ifnull(tb_#{i}.players, 0) as #{zone.zone_id}区总人数 "
  #   end

  #   tbs  = ' tmp_credits tb_x '
  #   zones.each_with_index do |zone, i|
  #     tbs += " left join tmp_credits_#{i} tb_#{i} on tb_#{i}.date = tb_x.date "
  #   end

  #   sql = %Q{create or replace view 各区金砖消费总计 as
  #               select #{columns} from #{tbs} order by date desc
  #             }
  #   puts ">>>>>sql:#{sql}"
  #   ActiveRecord::Base.connection.execute(sql)   


  #   columns = ' tb_x.date as date, (tb_x.credits '
  #   zones.each_with_index do |zone, i|
  #     columns += "+ ifnull(tb_#{i}.credits, 0) "
  #   end
  #   columns += ") as 总消费, (tb_x.players "
  #   zones.each_with_index do |zone, i|
  #     columns += "+ ifnull(tb_#{i}.players, 0) "
  #   end
  #   columns += ") as 总人数 "
  #   sql = %Q{create or replace view 金砖消费各区求和 as
  #               select #{columns} from #{tbs} order by date desc
  #             }
  #   puts ">>>>>sql:#{sql}"
  #   ActiveRecord::Base.connection.execute(sql)   
  # end
end