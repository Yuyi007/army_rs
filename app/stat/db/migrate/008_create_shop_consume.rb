class CreateShopConsume < ActiveRecord::Migration
  def up
    create_table :shop_consume, :options => 'ENGINE=InnoDB DEFAULT CHARSET=utf8' do |t|
      t.integer :zone_id,        :default => 0
      t.string  :sdk,            :null => false, :limit => 50
      t.string  :platform,       :null => false, :limit => 10
      t.date    :date
      t.string  :pid
      t.string  :shop_id
      t.string  :tid
      t.string  :cost_type
      t.integer :count,   :default => 0, :limit => 8
      t.integer :consume, :default => 0, :limit => 8
    end
    add_index :shop_consume, [:zone_id, :date]


    create_table :shop_consume_sum, :options => 'ENGINE=InnoDB DEFAULT CHARSET=utf8' do |t|
      t.integer :zone_id,        :default => 0
      t.string  :sdk,            :null => false, :limit => 50
      t.string  :platform,       :null => false, :limit => 10
      t.date    :date
      t.string  :tid
      t.string  :shop_id
      t.string  :cost_type
      t.integer :count,   :default => 0, :limit => 8
      t.integer :consume, :default => 0, :limit => 8
      t.integer :players,   :default => 0, :limit => 8
    end
    add_index :shop_consume_sum, [:zone_id, :date]
  end

  def down
    drop_table :shop_consume
    drop_table :shop_consume_sum
  end
end