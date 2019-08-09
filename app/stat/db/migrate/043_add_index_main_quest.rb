class  AddIndexMainQuest< ActiveRecord::Migration
  def up
		add_index :main_quest_users, [:zone_id, :platform, :sdk, :pid, :qid],
              :name => 'index_mq_zone_plat_sdk_pid_qid'
  end
end