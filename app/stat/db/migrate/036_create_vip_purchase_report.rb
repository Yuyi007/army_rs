class CreateVipPurchaseReport < ActiveRecord::Migration
  def up
    create_table :vip_purchase, :options => 'ENGINE=InnoDB DEFAULT CHARSET=utf8' do |t|
      t.integer :zone_id,        :default => 0
      t.string  :sdk,            :null => false, :limit => 50
      t.string  :platform,       :null => false, :limit => 10
      t.date    :date
      t.string   :tid,            :null => false
      t.integer  :players,        :default => 0
      t.integer  :consume,        :default => 0
      t.integer  :num,            :default => 0
    end
    add_index :vip_purchase, [:sdk, :platform, :zone_id]

    create_table :vip_purchase_report, :options => 'ENGINE=InnoDB DEFAULT CHARSET=utf8' do |t|
      t.integer :zone_id,        :default => 0
      t.string  :sdk,            :null => false, :limit => 50
      t.string  :platform,       :null => false, :limit => 10
      t.date    :date
      t.string   :tid,            :null => false
      t.integer  :players,        :default => 0
      t.integer  :consume,        :default => 0
      t.integer  :num,            :default => 0
    end
    add_index :vip_purchase_report, [:sdk, :platform, :zone_id]
  end

  def down
    drop_table :vip_purchase
    drop_table :vip_purchase_report
  end

end