class ViewGenerator
  def gen_start_campaign_view_by_zone(zone_id)
    args = {
      :zone_id => zone_id,
      :view_name  => "#{zone_id}区各类型战斗统计",
      :categories => {'boss' => '首领', 
                      'practice' => '修炼', 
                      'independent' => '机遇', 
                      'quest' => '任务', 
                      'review' => '回顾', 
                      'nightmare_review' => '噩梦回顾', 
                      'robber' => '千面', 
                      'ufc' => '国术', 
                      'shadow' => '暗影', 
                      'shadow_advance' => '精英暗影'},
      :type_col => 'kind',
      :src_table => "start_campaign_sum",
      :columns => {'count' => '次数', 'players' => '人数'}
    }
    tmp_gen_view_by_category_zone( args )
  end
end