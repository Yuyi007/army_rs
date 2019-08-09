class AddCdkey < ActiveRecord::Migration
 def up
    create_table "cdkeys", :id => true, :force => true do |t|
      t.string   "player_id",  :limit => 40
      t.integer  "zone",       :limit => 2
      t.string   "tid",        :limit => 20, :null => false
      t.string   "key",      :limit => 30, :null => false
      t.datetime "created_at", :null => false
    end

    add_index "cdkeys", ["created_at"], :name => "index_cdkeys_on_created_at"
    add_index "cdkeys", ["player_id", "created_at"], :name => "index_cdkeys_on_player_id_and_created_at"
    add_index "cdkeys", ["tid", "created_at"], :name => "index_cdkeys_on_t_and_created_at"
    add_index "cdkeys", ["zone", "created_at"], :name => "index_cdkeys_on_zone_and_created_at"
    add_index "cdkeys", ["key"], :name => "index_cdkeys_on_key"
  end

  def down
    drop_table 'cdkeys'
  end
end
