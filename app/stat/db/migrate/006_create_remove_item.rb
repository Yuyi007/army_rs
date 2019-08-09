class CreateRemoveItem < ActiveRecord::Migration
  def up
    create_table :remove_item, :options => 'ENGINE=InnoDB DEFAULT CHARSET=utf8' do |t|
      t.integer :zone_id,        :default => 0
      t.string  :sdk,            :null => false, :limit => 50
      t.string  :platform,       :null => false, :limit => 10
      t.date    :date
      t.string  :reason
      t.string  :pid
      t.integer :count,   :default => 0, :limit => 8
      t.integer :level,   :default => 0, :limit => 4
    end
    add_index :remove_item, :date
    add_index :remove_item, :zone_id
    add_index :remove_item, :sdk
    add_index :remove_item, :platform

    #代金券消耗系统明细
    create_table :alter_voucher_sys, :options => 'ENGINE=InnoDB DEFAULT CHARSET=utf8' do |t|
      t.integer :zone_id,        :default => 0
      t.string  :sdk,            :null => false, :limit => 50
      t.string  :platform,       :null => false, :limit => 10
      t.date    :date
      t.string  :reason
      t.integer :voucher, :default => 0, :limit => 8
      t.integer :players, :default => 0, :limit => 8
      t.integer :accounts, :default => 0, :limit => 8
    end
    add_index :alter_voucher_sys, :date
    add_index :alter_voucher_sys, :zone_id
    add_index :alter_voucher_sys, :sdk
    add_index :alter_voucher_sys, :platform
  end

  def down
    drop_table :remove_item
    drop_table :alter_voucher_sys
  end
end