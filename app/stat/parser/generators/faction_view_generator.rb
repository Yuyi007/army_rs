class ViewGenerator
  def gen_factions_view_by_zone(zone_id)
    args = {
      :zone_id => zone_id,
      :view_name  => "#{zone_id}区职业人数分布",
      :categories => {'tao' => '道士',
                      'dem' => '狐妖',
                      'pol' => '杀马特',
                      'qigong' => '御剑',
                      'rune' => '灵符',
                      'shadow' => '利刃',
                      'fire' => '幻术',
                      'fighter' => '街霸',
                      'sanda' => '舞者'},
      :type_col => 'faction',
      :src_table => "factions",
      :columns => {'count' => '人数'}
    }
    tmp_gen_view_by_category_zone(args)
  end

end