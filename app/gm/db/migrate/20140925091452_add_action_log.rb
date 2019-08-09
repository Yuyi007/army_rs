class AddActionLog < ActiveRecord::Migration
  def up
    create_table "action_logs", :id => false, :force => true do |t|
      t.string   "player_id",  :limit => 40, :null => false
      t.integer  "zone",       :limit => 2,  :null => false
      t.string   "t",           :limit => 20,  :null => false
      t.string   "param1",     :limit => 10
      t.string   "param2",     :limit => 10
      t.string   "param3",     :limit => 10
      t.string   "param4",     :limit => 10
      t.string   "param5",     :limit => 10
      t.datetime "created_at",               :null => false
    end

    add_index "action_logs", ["created_at"], :name => "index_action_logs_on_created_at"
    add_index "action_logs", ["player_id", "created_at"], :name => "index_action_logs_on_player_id_and_created_at"
    add_index "action_logs", ["t", "created_at"], :name => "index_action_logs_on_t_and_created_at"
    add_index "action_logs", ["zone", "created_at"], :name => "index_action_logs_on_zone_and_created_at"
  end

  def down
    drop_table 'action_logs'
  end
end
