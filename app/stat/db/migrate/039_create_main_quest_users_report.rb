class  CreateMainQuestUsersReport < ActiveRecord::Migration
  def up
    # 基础表, 记录每个玩家的任务情况
    create_table :main_quest_users, :options => 'ENGINE=InnoDB DEFAULT CHARSET=utf8' do |t|
      t.string   :sdk,            :null => false, :limit => 50
      t.string   :platform,       :null => false, :limit => 10
      t.integer  :zone_id,        :default => 1
      t.string   :pid,            :default => ''
      t.string   :qid,            :default => ''
    end
    add_index :main_quest_users, [:zone_id, :qid]

    # 汇总报表，用于展示。每日更新数据
    create_table :main_quest_users_report, :options => 'ENGINE=InnoDB DEFAULT CHARSET=utf8' do |t|
      t.string   :sdk,            :null => false, :limit => 50
      t.string   :platform,       :null => false, :limit => 10
      t.integer  :zone_id,        :default => 1
      t.date     :date,           :null => false
      t.string   :qid,            :default => ''
      t.integer  :num,            :default => 0
    end
    add_index :main_quest_users_report, [:date, :zone_id, :platform, :sdk, :qid],
      :name => 'index_on_mqur_as_date_and_zone_and_pltfm_and_sdk_and_qtid'
  end

  def down
    drop_table :main_quest_users #report
    drop_table :main_quest_users_report
  end
end