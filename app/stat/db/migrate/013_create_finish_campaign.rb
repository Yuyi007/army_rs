class CreateFinishCampaign < ActiveRecord::Migration
  def up
    create_table :finish_campaign, :options => 'ENGINE=InnoDB DEFAULT CHARSET=utf8' do |t|
      t.integer  :zone_id,        :default => 0
      t.string   :sdk,            :null => false, :limit => 50
      t.string   :platform,       :null => false, :limit => 10
      t.date     :date,           :null => false
      t.string   :cid,            :null => false
    end
    add_index :finish_campaign, [:date, :zone_id]

    #获胜的人数统计
    create_table :finish_campaign_sum, :options => 'ENGINE=InnoDB DEFAULT CHARSET=utf8' do |t|
      t.integer  :zone_id,        :default => 0
      t.string   :sdk,            :null => false, :limit => 50
      t.string   :platform,       :null => false, :limit => 10
      t.date     :date,           :null => false
      t.integer  :players,        :default => 0
      t.string   :cid,           :null => false
    end
    add_index :finish_campaign_sum, [:date, :zone_id]
  end

  def down
    drop_table :finish_campaign
    drop_table :finish_campaign_sum
  end
end