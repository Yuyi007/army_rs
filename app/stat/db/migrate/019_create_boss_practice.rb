class CreateBossPractice < ActiveRecord::Migration
  def up
    #获胜的人数统计
    create_table :boss_practice_report, :options => 'ENGINE=InnoDB DEFAULT CHARSET=utf8' do |t|
      t.integer  :zone_id,        :default => 0
      t.string   :sdk,            :null => false, :limit => 50
      t.string   :platform,       :null => false, :limit => 10
      t.date     :date,                   :null => false
      t.integer  :count1_boss,            :default => 0
      t.integer  :count2_boss,            :default => 0
      t.integer  :count3_boss,            :default => 0
      t.integer  :count4_boss,            :default => 0
      t.integer  :count5_boss,            :default => 0
      t.integer  :count6_boss,            :default => 0
      t.integer  :count7_boss,            :default => 0
      t.integer  :count8_boss,            :default => 0
      t.integer  :count_more_boss,         :default => 0
      t.integer  :count1p_boss,            :default => 0
      t.integer  :count2p_boss,            :default => 0
      t.integer  :count3p_boss,            :default => 0
      t.integer  :count4p_boss,            :default => 0
      t.integer  :count5p_boss,            :default => 0
      t.integer  :count6p_boss,           :default => 0
      t.integer  :count7p_boss,           :default => 0
      t.integer  :count8p_boss,           :default => 0
      t.integer  :countp_more_boss,         :default => 0
      t.integer  :count1_practice,         :default => 0
      t.integer  :count2_practice,         :default => 0
      t.integer  :count3_practice,         :default => 0
      t.integer  :count4_practice,         :default => 0
      t.integer  :count5_practice,         :default => 0
      t.integer  :count6_practice,        :default => 0
      t.integer  :count7_practice,        :default => 0
      t.integer  :count8_practice,        :default => 0
      t.integer  :count_more_practice,      :default => 0
      t.integer  :count1p_practice,         :default => 0
      t.integer  :count2p_practice,         :default => 0
      t.integer  :count3p_practice,         :default => 0
      t.integer  :count4p_practice,         :default => 0
      t.integer  :count5p_practice,         :default => 0
      t.integer  :count6p_practice,        :default => 0
      t.integer  :count7p_practice,        :default => 0
      t.integer  :count8p_practice,        :default => 0
      t.integer  :count_morep_practice,      :default => 0
    end
    add_index :boss_practice_report, [:date, :zone_id]
  end

  def down
    drop_table :boss_practice_report
  end
end