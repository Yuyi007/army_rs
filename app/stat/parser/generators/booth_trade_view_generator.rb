class ViewGenerator
  def gen_booth_trade_view_by_zone(zone_id)
    sql = %Q{
      create or replace view #{zone_id}区交易行流水 as
        select  date as 日期,
                seller_id as 卖家id,
                buyer_id as 买家id,
                tid as 物品,
                count as 数量,
                price as 价格,
                time  as 具体时间 
        from booth_trade
        where zone_id = #{zone_id}
        order by date desc
    }
    ActiveRecord::Base.connection.execute(sql)
  end
end