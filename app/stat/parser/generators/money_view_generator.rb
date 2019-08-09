class ViewGenerator

  def gen_money_sys_consume_view(zone_id)
    gen_money_sys_consume_view_by_zone(zone_id)
    gen_money_sys_gain_view_by_zone(zone_id)
  end

  def gen_money_sys_gain_view_by_zone(zone_id)
    args = {
      :zone_id => zone_id,
      :view_name  => "#{zone_id}区纸币各系统获得",
      :categories => {'take_photo' => '都市摄影',
                      'npc_repo' => '纸币急购',
                      'finish_job' => '应聘打工',
                      'bq_drop_wanted' => '通讯录委托',
                      'currency_exchange_credits' => '黄金兑换'},
      :type_col => 'reason',
      :src_table => "gain_money_sys",
      :columns => {'money' => '获得', 'players' => '人数'}
    }
    tmp_gen_view_by_category_zone(args)
  end

  def gen_money_sys_consume_view_by_zone(zone_id)
    args = {
      :zone_id => zone_id,
      :view_name  => "#{zone_id}区纸币各系统消耗",
      :categories => {'currency_exchange_coins' => '兑换硬币',
                      'booth_buy' => '交易行',
                      'buy_goods' => '商城限购'},
      :type_col => 'reason',
      :src_table => "alter_money_sys",
      :columns => {'money' => '消费', 'players' => '人数'}
    }
    tmp_gen_view_by_category_zone(args)
  end
end