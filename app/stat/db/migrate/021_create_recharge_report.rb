class CreateRechargeReport < ActiveRecord::Migration
  def up
    #按日统计每种类型充值的新增和总充值
    create_table :recharge_report, :options => 'ENGINE=InnoDB DEFAULT CHARSET=utf8' do |t|
      t.string   :platform,               :null => false
      t.string   :sdk
      t.string   :market
      t.integer  :zone_id,                :default => 0
      t.date     :date,                   :null => false
      t.integer  :num,                    :default => 0
      t.string   :goods,                  :null => false
      t.boolean  :isnew
    end
    add_index :recharge_report, [:goods, :zone_id]
  end

  def down
    drop_table :recharge_report
  end
end