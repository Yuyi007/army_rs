class ViewGenerator

  def gen_voucher_sys_consume_view(zone_id)
    gen_voucher_sys_consume_view_by_zone(zone_id)
    gen_voucher_sys_gain_view_by_zone(zone_id)
  end

  def gen_voucher_sys_gain_view_by_zone(zone_id)
    args = {
      :zone_id => zone_id,
      :view_name  => "#{zone_id}区代金券各系统获得",
      :categories => { 'delay_drop' => '朋友圈',
                      'bq_drop_wanted' => '通讯录委托',
                      'city_event' => '市井事件'},
      :type_col => 'reason',
      :src_table => "gain_voucher_sys",
      :columns => {'voucher' => '获得', 'players' => '人数'}
    }
    tmp_gen_view_by_category_zone(args)
  end

  def gen_voucher_sys_consume_view_by_zone(zone_id)
    args = {
      :zone_id => zone_id,
      :view_name  => "#{zone_id}区代金券各系统消耗",
      :categories => {'buy_goods' => '商城免费'},
      :type_col => 'reason',
      :src_table => "alter_voucher_sys",
      :columns => {'voucher' => '消费', 'players' => '人数'}
    }
    tmp_gen_view_by_category_zone(args)

  end
  
end