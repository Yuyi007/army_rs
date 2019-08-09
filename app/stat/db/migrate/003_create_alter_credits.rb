class CreateAlterCredits < ActiveRecord::Migration
  def up
    #明细表 记录每一类变化
    create_table :alter_credits, :options => 'ENGINE=InnoDB DEFAULT CHARSET=utf8' do |t|
      t.integer :zone_id,        :default => 0
      t.string  :sdk,            :null => false, :limit => 50
      t.string  :platform,       :null => false, :limit => 10
      t.date    :date
      t.string  :reason
      t.string  :pid
      t.integer :credits, :default => 0, :limit => 8
      t.integer :level,   :default => 0, :limit => 4
    end
    add_index :alter_credits, :zone_id
    add_index :alter_credits, :sdk 
    add_index :alter_credits, :platform

    # #总计表 每日消耗最多 获得最多
    # create_table :alter_credits_total, :options => 'ENGINE=InnoDB DEFAULT CHARSET=utf8' do |t|
    #   t.integer :zone_id,        :default => 0
    #   t.string  :sdk,            :null => false, :limit => 50
    #   t.string  :platform,       :null => false, :limit => 10
    #   t.date    :date
    #   t.string  :max_pid
    #   t.string  :min_pid
    #   t.integer :max,     :default => 0, :limit => 8
    #   t.integer :min,     :default => 0, :limit => 8
    #   t.integer :total_inc, :default => 0, :limit => 8
    #   t.integer :total_dec, :default => 0, :limit => 8
    # end
    # add_index :alter_credits_total, :zone_id
    # add_index :alter_credits_total, :sdk 
    # add_index :alter_credits_total, :platform

    #总消耗和消耗人数报表
    create_table :alter_credits_sum, :options => 'ENGINE=InnoDB DEFAULT CHARSET=utf8' do |t|
      t.integer :zone_id,        :default => 0
      t.string  :sdk,            :null => false, :limit => 50
      t.string  :platform,       :null => false, :limit => 10
      t.date    :date
      t.integer :credits, :default => 0, :limit => 8
      t.integer :players, :default => 0, :limit => 8
    end
    add_index :alter_credits_sum, :zone_id
    add_index :alter_credits_sum, :sdk 
    add_index :alter_credits_sum, :platform

    #按系统分类的消耗报表
    create_table :alter_credits_sys, :options => 'ENGINE=InnoDB DEFAULT CHARSET=utf8' do |t|
      t.integer :zone_id,        :default => 0
      t.string  :sdk,            :null => false, :limit => 50
      t.string  :platform,       :null => false, :limit => 10
      t.date    :date
      t.string  :reason
      t.integer :credits, :default => 0, :limit => 8
      t.integer :players, :default => 0, :limit => 8
    end
    add_index :alter_credits_sys, :zone_id
    add_index :alter_credits_sys, :sdk 
    add_index :alter_credits_sys, :platform

    #获取系统报表
    create_table :gain_credits_sys, :options => 'ENGINE=InnoDB DEFAULT CHARSET=utf8' do |t|
      t.integer :zone_id,        :default => 0
      t.string  :sdk,            :null => false, :limit => 50
      t.string  :platform,       :null => false, :limit => 10
      t.date    :date
      t.string  :reason
      t.integer :credits, :default => 0, :limit => 8
      t.integer :players, :default => 0, :limit => 8
    end
    add_index :gain_credits_sys, :zone_id
    add_index :gain_credits_sys, :sdk 
    add_index :gain_credits_sys, :platform
  end

  def down
    drop_table :alter_credits
    drop_table :alter_credits_total
    drop_table :alter_credits_sum
    drop_table :alter_credits_sys
    drop_table :gain_credits_sys
  end
end