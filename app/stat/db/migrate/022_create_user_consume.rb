class CreateUserConsume < ActiveRecord::Migration
  def up
    #玩家消费按系统 币种 统计
    create_table :user_consume, :options => 'ENGINE=InnoDB DEFAULT CHARSET=utf8' do |t|
      t.integer  :zone_id,        :default => 0
      t.string   :sdk,            :null => false, :limit => 50
      t.string   :platform,       :null => false, :limit => 10
      t.string   :sys_name    
      t.string   :cost_type      
      t.integer  :pid,            :null => false
      t.integer  :cid,            :null => false
      t.integer  :consume,        :default => 0
    end
    add_index :user_consume, [:zone_id, :cost_type, :sys_name]
  end

  def down
    drop_table :user_consume
  end
end