require_relative '../../app/models/site_users'

class CreateSysAccounts < ActiveRecord::Migration
  def up
    create_table :sys_roles, :options => 'ENGINE=InnoDB DEFAULT CHARSET=utf8' do |t|
      t.integer :id, primary: true, :null => false
      t.string  :name, :null => false
      t.string  :desc, :limit => 64
    end
    add_index :sys_roles, :id
    SiteUsers::SysRoles.create :name => 'admin', :desc => 'Admin has all rights'
    SiteUsers::SysRoles.create :name => 'guest', :desc => 'Guest has partial rights'

    create_table :sys_functions, :options => 'ENGINE=InnoDB DEFAULT CHARSET=utf8' do |t|
      t.integer :id, primary: true, :null => false
      t.string  :name, :null => false
      t.string  :desc, :limit => 64
    end
    add_index :sys_functions, :id

    funcs = [   {:name => 'role_manage', :desc => 'Manage roles'},
                {:name => 'user_manage', :desc => 'Manage accounts'},
                {:name => 'gen_today', :desc => 'Generate today Stats'},
                {:name => 'level_consume', :desc => 'Lookup consume by level'},
                {:name => 'consume_report', :desc => 'Lookup consume report by level'},
                {:name => 'total_active', :desc => 'Lookup total active per week'},
                {:name => 'active_report', :desc => 'Lookup active per day'},
                {:name => 'retention_report', :desc => 'Lookup retention per day'},
                {:name => 'chief_level_report', :desc => 'Lookup chief level per day'},
                {:name => 'city_level_report', :desc => 'Lookup city level per day'    },
                {:name => 'credits_consume_report', :desc => 'Lookup credits consume report' },
                {:name => 'credits_gain_report', :desc => 'Lookup credits gain report'    },
                {:name => 'coins_consume_report', :desc => 'Lookup coins consume report' },
                {:name => 'coins_gain_report', :desc => 'Lookup coins gain report' },
                {:name => 'money_consume_report', :desc => 'Lookup money consume report' },
                {:name => 'money_gain_report', :desc => 'Lookup money gain report' },
                {:name => 'voucher_consume_report', :desc => 'Lookup voucher consume report' },
                {:name => 'voucher_gain_report', :desc => 'Lookup voucher gain report' },
                {:name => 'shop_consume_report', :desc => 'Lookup shop consume report' },
                {:name => 'start_campaign_report', :desc => 'Lookup campaign start report' },
                {:name => 'active_factions_report', :desc => 'Lookup active factions report' },
                {:name => 'main_quest_cam_report', :desc => 'Lookup main quest campaigns report' },
                {:name => 'booth_trade_report', :desc => 'Lookup booth trade report' },
                {:name => 'new_users_report', :desc => 'Lookup real-time new users report' },
                {:name => 'active_users_report', :desc => 'Lookup real-time active users report' },
                {:name => 'max_online_report', :desc => 'Lookup real-time max online count report' },
                {:name => 'ave_online_report', :desc => 'Lookup real-time average online count report' },
                {:name => 'chapter_quest_report', :desc => 'Lookup chapter quest finished report' },
                {:name => 'boss_practice_report', :desc => 'Lookup boss & practice campaign start report' },
                {:name => 'player_recharge_report', :desc => 'Lookup player recharte report' },
                {:name => 'player_recharge_record', :desc => 'Lookup player recharte records' },
                {:name => 'new_player_recharge_report', :desc => 'Lookup new player recharte records' },
                {:name => 'loss_consume_report', :desc => 'Lookup loss player consume level records' },
                {:name => 'loss_recharge_report', :desc => 'Lookup loss player recharge level records' },
                {:name => 'all_factions_report', :desc => 'Lookup all factions report' },
                {:name => 'level_campaign_report', :desc => 'Lookup all campaign report by hero level range' },
                {:name => 'city_campaign_report', :desc => 'Lookup all factions report by city id' },
                {:name => 'add_equip_report', :desc => 'Lookup all add equip report' },
                {:name => 'guild_level_record', :desc => 'Lookup all guild level report' },
                {:name => 'guild_skill_record', :desc => 'Lookup all guild skill level report' },
                {:name => 'all_player_level_report', :desc => 'Lookup all player level' },
                {:name => 'all_player_city_event_level_report', :desc => 'Lookup all player city event level' },
                {:name => 'guild_active_record', :desc => 'Lookup all guild active event report' },
                {:name => 'main_quest_report', :desc => 'Lookup main quest complete report' },
                {:name => 'main_quest_user_report', :desc => 'Lookup main quest complete report' },
                {:name => 'vip_level_report', :desc => 'Lookup vip level report' },
                {:name => 'vip_purchase_report', :desc => 'Lookup vip package purchase report' },
                {:name => 'share_award_report', :desc => 'Lookup share award report' },
                {:name => 'born_quest_report', :desc => 'Lookup born quest award report' },
                {:name => 'loss_report', :desc => 'Lookup players loss report' },
                
            ]


    create_table :sys_rights, :options => 'ENGINE=InnoDB DEFAULT CHARSET=utf8' do |t|
      t.integer  :roleid, :null => false
      t.integer  :funid, :null => false
    end
    add_index :sys_rights, :roleid

    funcs.each_with_index do |x, i|
        SiteUsers::SysFunctions.create :name => x[:name], :desc => x[:desc]
        SiteUsers::SysRights.create :roleid => 1, :funid => (i+1)
    end


    create_table :sys_users, :options => 'ENGINE=InnoDB DEFAULT CHARSET=utf8' do |t|
      t.integer  :id, primary: true, :null => false
      t.string   :email, :limit => 64
      t.string   :password, :limit => 64
      t.integer  :roleid, :null => false
      t.boolean  :inuse, :default => false
    end

    add_index :sys_users, :email, :unique => true
    add_index :sys_users, :id
    SiteUsers::SysUsers.create :email => 'duwenjie@firevale.com', :password => Digest::SHA1.hexdigest('firevale1'), :roleid => 1, :inuse => true
  end

  def down
    drop_table  :sys_users
    drop_table  :sys_functions
    drop_table  :sys_roles
    drop_table  :sys_rights
  end
end