class CreateCampaignReport < ActiveRecord::Migration
  def up
    create_table :campaign_report, :options => 'ENGINE=InnoDB DEFAULT CHARSET=utf8' do |t|
      t.date     :date,           :null => false
      t.integer  :zone_id,        :default => 1
      t.string   :cid,            :null => false
      t.integer  :num,            :default => 0
      t.integer  :players,        :default => 0
      t.string   :cat,            :null => false
    end

    add_index :campaign_report, [:date, :zone_id, :cid]
  end

  def down
    drop_table :campaign_report
  end

end