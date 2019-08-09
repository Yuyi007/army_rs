class CreateStartCampaign < ActiveRecord::Migration
  def up
    create_table :start_campaign, :options => 'ENGINE=InnoDB DEFAULT CHARSET=utf8' do |t|
      t.integer  :zone_id,        :default => 0
      t.string   :sdk,            :null => false, :limit => 50
      t.string   :platform,       :null => false, :limit => 10
      t.date     :date,           :null => false
      t.integer  :count,          :default => 0
      t.integer  :level_rgn,      :default => 10
      t.string   :pid,            :null => false
      t.string   :kind,           :null => false
    end
    add_index :start_campaign, [:date, :sdk, :zone_id, :platform]

    create_table :start_campaign_sum, :options => 'ENGINE=InnoDB DEFAULT CHARSET=utf8' do |t|
      t.integer  :zone_id,        :default => 0
      t.string   :sdk,            :null => false, :limit => 50
      t.string   :platform,       :null => false, :limit => 10
      t.date     :date,           :null => false
      t.integer  :count,          :default => 0
      t.integer  :players,        :default => 0
      t.integer  :accounts,       :default => 0
      t.string   :kind,           :null => false
    end
    add_index :start_campaign_sum, [:date, :zone_id]

    #按等级段统计
    create_table :level_campaign_report, :options => 'ENGINE=InnoDB DEFAULT CHARSET=utf8' do |t|
      t.integer  :zone_id,        :default => 0
      t.string   :sdk,            :null => false, :limit => 50
      t.string   :platform,       :null => false, :limit => 10
      t.date     :date,           :null => false
      t.integer  :count,          :default => 0
      t.integer  :players,        :default => 0
      t.string   :kind,           :null => false
      t.integer  :level_rgn,      :defaule => 10
    end
    add_index :level_campaign_report, [:date, :zone_id]

    #按场景城区统计
    create_table :city_campaign, :options => 'ENGINE=InnoDB DEFAULT CHARSET=utf8' do |t|
      t.integer  :zone_id,        :default => 0
      t.string   :sdk,            :null => false, :limit => 50
      t.string   :platform,       :null => false, :limit => 10
      t.date     :date,           :null => false
      t.integer  :count,          :default => 0
      t.integer  :players,        :default => 0
      t.string   :kind,           :null => false
      t.string   :city_id,        :null => false
    end
    add_index :city_campaign, [:date, :zone_id]

    create_table :city_campaign_report, :options => 'ENGINE=InnoDB DEFAULT CHARSET=utf8' do |t|
      t.integer  :zone_id,        :default => 0
      t.string   :sdk,            :null => false, :limit => 50
      t.string   :platform,       :null => false, :limit => 10
      t.date     :date,           :null => false
      t.integer  :count,          :default => 0
      t.integer  :players,        :default => 0
      t.string   :kind,           :null => false
      t.string   :city_id,        :null => false
    end
    add_index :city_campaign_report, [:date, :zone_id]

  end

  def down
    drop_table :start_campaign
    drop_table :start_campaign_sum
    drop_table :level_campaign_report
    drop_table :city_campaign
    drop_table :city_campaign_report
  end

end