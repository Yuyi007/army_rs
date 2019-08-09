class CreateConsumeLevel < ActiveRecord::Migration
  def up
    create_table :consume_levels, :options => 'ENGINE=InnoDB DEFAULT CHARSET=utf8' do |t|
      t.integer :zone_id,        :default => 0
      t.string  :sdk,            :null => false, :limit => 50
      t.string  :platform,       :null => false, :limit => 10
      t.date    :date
      t.string   :sys_name    
      t.string   :cost_type      
      t.integer  :players,        :default => 0
      t.integer  :consume,        :default => 0
      t.integer  :level_rgn,      :defaule => 10
    end
    add_index :consume_levels, [:date, :zone_id]
  end

  def down
    drop_table :consume_levels
  end
end