class ViewGenerator

  def gen_shop_consume_views(zone_id)
    sql = %Q{
      create or replace view #{zone_id}区商城消费情况 as
        select date as 日期, tid as 商品, shop_id as 商店, cost_type as 消耗类型, count as 数量, consume as 花费 from shop_consume_sum
        where zone_id = #{zone_id} and (shop_id like '%shop0001%' or shop_id like '%shop0002%' or shop_id like '%shop0003%')
        order by date desc, shop_id asc
    }
    ActiveRecord::Base.connection.execute(sql)
  end

  def get_name(tid)
    cfg = StatCommands.game_config
    case tid
    when /^ite/
      t = cfg['items'][tid]
      return t['name'] if !t.nil? 
    when /^pro/
      t = cfg['props'][tid]
      return t['name'] if !t.nil? 
    when /^eqp/
      t = cfg['equips'][tid]
      return t['name'] if !t.nil? 
    when /^bbe/
      t = cfg['garments'][tid]
      return t['name'] if !t.nil? 
    end
    return tid
  end

  def get_goods
    goods = []
    cfg = StatCommands.game_config
    sets = cfg['goods']['sets']
    items = cfg['goods']['items']
    shops = cfg['shops']
    ['sho0001', 'sho0002', 'sho0003'].each do |sid|
      st = shops[sid]
      if !st.nil?
        st['tabs'].each do |tab|
          set = sets[tab['sets'].to_s]
          if !set.nil?
            # puts ">>>>>set:#{set}"
            set.each do |gid|
              it = items[gid]
              if !it.nil?
                name = get_name(it['item_tid'])
                name['_'] = '' if name.include? '_'
                name['-'] = '' if name.include? '-'
                name['('] = '' if name.include? '('
                name[')'] = '' if name.include? ')'
                name[']'] = '' if name.include? ']'
                name['['] = '' if name.include? '['
                goods << {:gid => gid, :name => name }
              end
            end
          end
        end
      end
    end
    puts ">>>>goods:#{goods}"
    return goods
  end
end