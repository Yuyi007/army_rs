class CreateAlterCoins < ActiveRecord::Migration
  def up
    create_table :alter_coins, :options => 'ENGINE=InnoDB DEFAULT CHARSET=utf8' do |t|
      t.integer :zone_id,        :default => 0
      t.string  :sdk,            :null => false, :limit => 50
      t.string  :platform,       :null => false, :limit => 10
      t.date    :date
      t.string  :reason
      t.string  :pid
      t.integer :coins, :default => 0, :limit => 8
      t.integer :level,   :default => 0, :limit => 4
    end
    add_index :alter_coins, :date
    add_index :alter_coins, :zone_id
    add_index :alter_coins, :sdk
    add_index :alter_coins, :platform

    #消耗系统明细
    create_table :alter_coins_sys, :options => 'ENGINE=InnoDB DEFAULT CHARSET=utf8' do |t|
      t.integer :zone_id,        :default => 0
      t.string  :sdk,            :null => false, :limit => 50
      t.string  :platform,       :null => false, :limit => 10
      t.date    :date
      t.string  :reason
      t.integer :coins, :default => 0, :limit => 8
      t.integer :players, :default => 0, :limit => 8
    end
    add_index :alter_coins_sys, :date
    add_index :alter_coins_sys, :zone_id
    add_index :alter_coins_sys, :sdk
    add_index :alter_coins_sys, :platform

    #获取系统明细
    create_table :gain_coins_sys, :options => 'ENGINE=InnoDB DEFAULT CHARSET=utf8' do |t|
      t.integer :zone_id,        :default => 0
      t.string  :sdk,            :null => false, :limit => 50
      t.string  :platform,       :null => false, :limit => 10
      t.date    :date
      t.string  :reason
      t.integer :coins, :default => 0, :limit => 8
      t.integer :players, :default => 0, :limit => 8
    end
    add_index :gain_coins_sys, :date
    add_index :gain_coins_sys, :zone_id
    add_index :gain_coins_sys, :sdk
    add_index :gain_coins_sys, :platform
  end

  def down
    drop_table :alter_coins
    drop_table :alter_coins_sys
    drop_table :gain_coins_sys
  end
end