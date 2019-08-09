class CreateBoothTrade < ActiveRecord::Migration
  def up
    create_table :booth_trade, :options => 'ENGINE=InnoDB DEFAULT CHARSET=utf8' do |t|
      t.date     :date,           :null => false
      t.integer  :zone_id,        :default => 1    
      t.string   :seller_id,      :null => false
      t.string   :buyer_id,       :null => false
      t.string   :tid,            :null => false
      t.string   :name,           :null => false
      t.integer  :count,          :null => false, :default => 0
      t.integer  :price,          :null => false, :default => 0
      t.integer  :level,          :default => 0
      t.integer  :grade,          :default => 0
      t.string   :star,           :default => ''
      t.string   :time
    end
    add_index :booth_trade, [:date, :zone_id]
  end

  def down
    drop_table :booth_trade
  end
end