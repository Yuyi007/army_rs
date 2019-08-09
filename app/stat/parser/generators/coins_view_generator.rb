class ViewGenerator

  def gen_coins_sys_consume_view(zone_id)
    gen_coins_sys_consume_view_by_zone(zone_id)
    gen_coins_sys_gain_view_by_zone(zone_id)
  end

  def gen_coins_sys_gain_view_by_zone(zone_id)
    args = {
      :zone_id => zone_id,
      :view_name  => "#{zone_id}区硬币各系统获得",
      :categories => { 'mq_drop' => '主线任务',
                      'bq_drop_chapterevent' => '章节事件',
                      'sell_slot' => '卖道具',
                      'drop_chance' => '机遇副本',
                      'drop_boss' => '危险任务',
                      'dialy_activity' => '每日活跃',
                      'decompose_equip' => '装备分解',
                      'city_event' => '市井事件',
                      'apply_drive' => '试驾',
                      'currency_exchange_money' => '纸币兑换',
                      'currency_exchange_credits' => '黄金兑换'},
      :type_col => 'reason',
      :src_table => "gain_coins_sys",
      :columns => {'coins' => '获得', 'players' => '人数'}
    }
    tmp_gen_view_by_category_zone(args)

  end

  def gen_coins_sys_consume_view_by_zone(zone_id)
    args = {
      :zone_id => zone_id,
      :view_name  => "#{zone_id}区硬币各系统消耗",
      :categories => {'buy_foods' => '健康饮食',
                      'taxi' => '嘟嘟打车',
                      'take_subway' => '地铁',
                      'buy_bus_ticket' => '长途',
                      'hospital_cure' => '医院',
                      'coach' => '强身健体',
                      'absorb_equip' => '装备合魂',
                      'make_forge' => '装备打造',
                      'upgrade_new_talent' => '天赋升级',
                      'buy_goods_eqp' => '装备商店',
                      'buy_goods_gift' => '礼物商店',
                      'buy_goods_wine' => '药品商店',
                      'buy_goods_cooking' => '食物商店',
                      'use_enchant_medica' => '灵符篆刻',
                      'refresh_therion' => '四象觉醒',
                      'buy_goods_gem' => '宝石商店',
                      'buy_goods_drawing' => '灵符商店',
                      'unlock_bag_slot' => '背包空间',
                      'add_inventory' => '银行空间'},
      :type_col => 'reason',
      :src_table => "alter_coins_sys",
      :columns => {'coins' => '消费', 'players' => '人数'}
    }
    tmp_gen_view_by_category_zone(args)

  end
end