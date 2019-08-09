class CreateVipLevelReport < ActiveRecord::Migration
  def up
    create_table :vip_level_report, :options => 'ENGINE=InnoDB DEFAULT CHARSET=utf8' do |t|
      t.integer :zone_id,        :default => 0
      t.string  :sdk,            :null => false, :limit => 50
      t.string  :platform,       :null => false, :limit => 10
      t.date     :date,           :null => false
      t.integer  :level,          :default => 1
      t.integer  :num,            :default => 0
    end
    add_index :vip_level_report, [:date, :zone_id, :sdk, :platform]
  end

  def down
    drop_table :vip_level_report
  end

end