class CreateBases < ActiveRecord::Migration
  def up
    create_table :online_user_numbers, :options => 'ENGINE=InnoDB DEFAULT CHARSET=utf8' do |t|
      t.date    :date
      t.integer :zone_id, :default => 1
      t.integer :hour
      t.integer :max,     :default => 0
      t.integer :min,     :default => 0
    end

    [:user, :device, :account].each do |type|
      [:zone_id, :sdk, :market, :platform].each do |key|
        retention_table = "#{type}_#{key}_retention_reports"
        create_table retention_table, :options => 'ENGINE=InnoDB DEFAULT CHARSET=utf8' do |t|
          t.date    :date,           :null => false
          t.integer key,             :default => 0 if key == :zone_id
          t.string  key,             :null => false, :limit => 20 unless key == :zone_id
          (0..30).to_a.each do |n|
            t.integer "num_d#{n}",   :default => 0
          end
          t.integer "num_d90",   :default => 0
        end

        add_index retention_table, [:date, key], :unique => true
        add_index retention_table, key
      end
    end


    [:user, :device, :account].each do |type|
      retention_table = "#{type}_retention_reports"
      create_table retention_table, :options => 'ENGINE=InnoDB DEFAULT CHARSET=utf8' do |t|
        t.date    :date,           :null => false
        (0..30).to_a.each do |n|
          t.integer "num_d#{n}",   :default => 0
        end
        t.integer "num_d90",   :default => 0
      end

      add_index retention_table, :date, :unique => true
    end


    [:user, :account, :device, :new_user, :new_account, :new_device, :paid_user].each do |type|
      [:zone_id, :sdk, :market, :platform].each do |key|
        activity_table = "#{type}_#{key}_activity_reports"

        create_table activity_table, :options => 'ENGINE=InnoDB DEFAULT CHARSET=utf8' do |t|
          t.date    :date,    :null => false
          t.integer key,      :default => 0 if key == :zone_id
          t.string  key,      :null => false, :limit => 20 unless key == :zone_id
          t.integer :total,   :default => 0

          (5..60).step(5).to_a.each do |n|
            t.integer "num_m#{n}",  :default => 0
          end
          t.integer :num_m120, :default => 0
          t.integer :num_m180, :default => 0
          t.integer :num_m300, :default => 0
          t.integer :m300plus, :default => 0
        end

        add_index activity_table, [:date, key], :unique => true
        add_index activity_table, key
      end
    end

    [:user, :account, :device, :new_user, :new_account, :new_device].each do |type|
      activity_table = "#{type}_activity_reports"

      create_table activity_table, :options => 'ENGINE=InnoDB DEFAULT CHARSET=utf8' do |t|
        t.date    :date,    :null => false
        t.integer :total,   :default => 0

        (5..60).step(5).to_a.each do |n|
          t.integer "num_m#{n}",  :default => 0
        end
        t.integer :num_m120, :default => 0
        t.integer :num_m180, :default => 0
        t.integer :num_m300, :default => 0
        t.integer :m300plus, :default => 0
      end

      add_index activity_table, :date, :unique => true
    end


    create_table :zone_devices, :options => 'ENGINE=InnoDB DEFAULT CHARSET=utf8' do |t|
      t.string   :sid,         :null => false, :limit => 70
      t.integer  :zone_id,     :default => 1
      t.string   :market,      :limit => 50
      t.string   :sdk,         :limit => 50
      t.string   :platform,    :limit => 10
      t.date     :reg_date
      t.datetime :last_login_at
      t.datetime :last_logout_at
      t.integer  :active_secs, :default => 0
      t.integer  :total_active_secs, :default => 0
      t.integer  :active_days, :default => 0
    end

    add_index :zone_devices, [:sid, :zone_id], :unique => true, :name => :index_game_devices_on_device_id_and_zone_id
    add_index :zone_devices, [:last_login_at, :zone_id]
    add_index :zone_devices, [:reg_date, :last_login_at, :zone_id]
    add_index :zone_devices, [:reg_date, :last_login_at, :market]
    add_index :zone_devices, [:reg_date, :last_login_at, :sdk]
    add_index :zone_devices, [:reg_date, :last_login_at, :platform]
    add_index :zone_devices, [:reg_date, :last_login_at]
    add_index :zone_devices, :zone_id
    add_index :zone_devices, :sdk
    add_index :zone_devices, :market
    add_index :zone_devices, :platform
    add_index :zone_devices, :reg_date
    add_index :zone_devices, :last_login_at
    add_index :zone_devices, [:last_login_at, :active_secs]



    create_table :zone_users, :options => 'ENGINE=InnoDB DEFAULT CHARSET=utf8' do |t|
      t.string   :sid,                     :null => false, :limit => 50
      t.integer  :zone_id,                 :default => 1
      t.string   :platform,                :default => :ios, :limit => 10
      t.string   :market,                  :limit => 50
      t.string   :sdk,                     :limit => 50
      t.date     :reg_date
      t.datetime :last_login_at
      t.datetime :last_logout_at
      t.integer  :login_times,             :default => 0
      t.integer  :total_login_times,       :default => 0
      t.integer  :active_days,             :default => 0
      t.integer  :active_secs,             :default => 0
      t.integer  :total_active_secs,       :default => 0
      t.integer  :level,                   :default => 1
      t.integer  :coins,                    :default => 0, :limit => 8
      t.integer  :credits,                 :default => 0, :limit => 8
      t.integer  :money,                  :default => 0, :limit => 8
      t.integer  :vip_level,               :default => 0
      t.integer  :login_days_count,        :default => 0
      t.integer  :continuous_login_days,   :default => 0
      t.string   :level_group,             :null    => true
    end

    add_index :zone_users, [:sid, :zone_id], :unique => true
    add_index :zone_users, [:last_login_at, :zone_id]
    add_index :zone_users, [:reg_date, :last_login_at, :zone_id]
    add_index :zone_users, [:reg_date, :last_login_at, :market]
    add_index :zone_users, [:reg_date, :last_login_at, :sdk]
    add_index :zone_users, [:reg_date, :last_login_at, :platform]
    add_index :zone_users, [:reg_date, :last_login_at]
    add_index :zone_users, :zone_id
    add_index :zone_users, :sdk
    add_index :zone_users, :market
    add_index :zone_users, :platform
    add_index :zone_users, :reg_date
    add_index :zone_users, :last_login_at
    add_index :zone_users, [:last_login_at, :active_secs]

    create_table :zone_accounts, :options => 'ENGINE=InnoDB DEFAULT CHARSET=utf8' do |t|
      t.string   :sid,                     :null => false, :limit => 50
      t.integer  :zone_id,                 :default => 1
      t.string   :platform,                :default => :ios, :limit => 10
      t.string   :market,                  :limit => 50
      t.string   :sdk,                     :limit => 50
      t.date     :reg_date
      t.datetime :last_login_at
      t.datetime :last_logout_at
      t.integer  :login_times,             :default => 0
      t.integer  :total_login_times,       :default => 0
      t.integer  :active_days,             :default => 0
      t.integer  :active_secs,             :default => 0
      t.integer  :total_active_secs,       :default => 0
      t.integer  :level,                   :default => 1
      t.integer  :coins,                    :default => 0, :limit => 8
      t.integer  :credits,                 :default => 0, :limit => 8
      t.integer  :money,                  :default => 0, :limit => 8
      t.integer  :vip_level,               :default => 0
      t.integer  :login_days_count,        :default => 0
      t.integer  :continuous_login_days,   :default => 0
      t.string   :level_group,             :null    => true
    end

    add_index :zone_accounts, [:sid, :zone_id], :unique => true
    add_index :zone_accounts, [:last_login_at, :zone_id]
    add_index :zone_accounts, [:reg_date, :last_login_at, :zone_id]
    add_index :zone_accounts, [:reg_date, :last_login_at, :market]
    add_index :zone_accounts, [:reg_date, :last_login_at, :sdk]
    add_index :zone_accounts, [:reg_date, :last_login_at, :platform]
    add_index :zone_accounts, [:reg_date, :last_login_at]
    add_index :zone_accounts, :zone_id
    add_index :zone_accounts, :sdk
    add_index :zone_accounts, :market
    add_index :zone_accounts, :platform
    add_index :zone_accounts, :reg_date
    add_index :zone_accounts, :last_login_at
    add_index :zone_accounts, [:last_login_at, :active_secs]

    create_table :game_devices, :options => 'ENGINE=InnoDB DEFAULT CHARSET=utf8' do |t|
      t.string   :sid,        :null => false, :limit => 70 
      t.string   :market,     :limit => 50
      t.string   :sdk,        :limit => 50
      t.string   :platform,   :limit => 10
      t.date     :reg_date
      t.datetime :last_login_at
      t.datetime :last_logout_at
      t.integer  :active_secs, :default => 0
      t.integer  :total_active_secs, :default => 0
      t.integer  :active_days, :default => 0
    end

    add_index :game_devices, :sid, :unique => true
    add_index :game_devices, [:reg_date, :last_login_at, :market]
    add_index :game_devices, [:reg_date, :last_login_at, :sdk]
    add_index :game_devices, [:reg_date, :last_login_at, :platform]
    add_index :game_devices, [:reg_date, :last_login_at]
    add_index :game_devices, :sdk
    add_index :game_devices, :market
    add_index :game_devices, :platform
    add_index :game_devices, :reg_date
    add_index :game_devices, :last_login_at
    add_index :game_devices, [:last_login_at, :active_secs]

    create_table :game_users, :options => 'ENGINE=InnoDB DEFAULT CHARSET=utf8' do |t|
      t.string   :sid,      :null => false, :limit => 50
      t.string   :market,   :limit => 50
      t.string   :sdk,      :limit => 50
      t.string   :platform, :limit => 10
      t.date     :reg_date
      t.datetime :last_login_at
      t.datetime :last_logout_at
      t.integer  :active_secs, :default => 0
      t.integer  :total_active_secs, :default => 0
      t.integer  :active_days, :default => 0
    end

    add_index :game_users, :sid, :unique => true
    add_index :game_users, [:reg_date, :last_login_at, :market]
    add_index :game_users, [:reg_date, :last_login_at, :sdk]
    add_index :game_users, [:reg_date, :last_login_at, :platform]
    add_index :game_users, [:reg_date, :last_login_at]
    add_index :game_users, :sdk
    add_index :game_users, :market
    add_index :game_users, :platform
    add_index :game_users, :reg_date
    add_index :game_users, :last_login_at
    add_index :game_users, [:last_login_at, :active_secs]

    create_table :game_accounts, :options => 'ENGINE=InnoDB DEFAULT CHARSET=utf8' do |t|
      t.string   :sid,      :null => false, :limit => 50
      t.string   :market,   :limit => 50
      t.string   :sdk,      :limit => 50
      t.string   :platform, :limit => 10
      t.date     :reg_date
      t.datetime :last_login_at
      t.datetime :last_logout_at
      t.integer  :active_secs, :default => 0
      t.integer  :total_active_secs, :default => 0
      t.integer  :active_days, :default => 0
    end

    add_index :game_accounts, :sid, :unique => true
    add_index :game_accounts, [:reg_date, :last_login_at, :market]
    add_index :game_accounts, [:reg_date, :last_login_at, :sdk]
    add_index :game_accounts, [:reg_date, :last_login_at, :platform]
    add_index :game_accounts, [:reg_date, :last_login_at]
    add_index :game_accounts, :sdk
    add_index :game_accounts, :market
    add_index :game_accounts, :platform
    add_index :game_accounts, :reg_date
    add_index :game_accounts, :last_login_at
    add_index :game_accounts, [:last_login_at, :active_secs]

    create_table :sdks, :options => 'ENGINE=InnoDB DEFAULT CHARSET=utf8' do |t|
      t.string    :sdk, :null => false, :limit => 50
    end

    add_index :sdks, :sdk, :unique => true

    create_table :markets, :options => 'ENGINE=InnoDB DEFAULT CHARSET=utf8' do |t|
      t.string    :market, :null => false, :limit => 50
    end

    add_index :markets, :market, :unique => true

    create_table :platforms, :options => 'ENGINE=InnoDB DEFAULT CHARSET=utf8' do |t|
      t.string    :platform, :null => false, :limit => 10
    end

    add_index :platforms, :platform, :unique => true

    create_table :zones, :options => 'ENGINE=InnoDB DEFAULT CHARSET=utf8' do |t|
      t.integer   :zone_id, :default => 0
    end

    add_index :zones, :zone_id, :unique => true

    create_table :dates, :options => 'ENGINE=InnoDB DEFAULT CHARSET=utf8' do |t|
      t.datetime :date
    end
    add_index :dates, :date, :unique => true
  end

  def down
    [:online_user_numbers, :game_users, :game_accounts, :game_devices, :sdks, :markets, :platforms,
     :zones].each do |table_name|
      drop_table table_name
    end

    [:user, :account, :device].each do |type|
      [:zone_id, :sdk, :market, :platform].each do |key|
        retention_table = "#{type}_#{key}_retention_reports"
        drop_table retention_table
      end
    end

    [:user, :account, :device, :new_user, :new_account, :new_device, :paid_user].each do |type|
      [:zone_id, :sdk, :market, :platform].each do |key|
        activity_table = "#{type}_#{key}_activity_reports"
        drop_table activity_table
      end
    end

    [:user, :account, :device].each do |type|
      retention_table = "#{type}_retention_reports"
      drop_table retention_table 
    end

    [:user, :account, :device, :new_user, :new_account, :new_device].each do |type|
      activity_table = "#{type}_activity_reports"
      drop_table activity_table
    end
  end

end