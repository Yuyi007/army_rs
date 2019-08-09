class CreateRechargeRecord < ActiveRecord::Migration
  def up
    #每日按照充值类型记录 玩家每日充值
    create_table :recharge_record, :options => 'ENGINE=InnoDB DEFAULT CHARSET=utf8' do |t|
      t.string   :platform,               :null => false
      t.string   :sdk
      t.string   :market
      t.integer  :zone_id,                :default => 0
      t.string   :cid,                    :null => false
      t.string   :pid,                    :null => false
      t.date     :date,                   :null => false
      t.date     :first_date,             :null => false
      t.integer  :num,                    :default => 0
      t.string   :goods,                  :null => false
      t.integer  :total_num,              :default => 0
      t.integer  :days,                   :default => 0
      t.boolean  :isnew,                  :default => false             
    end
    add_index :recharge_record, [:goods, :zone_id]
  end

  def down
    drop_table :recharge_record
  end
end