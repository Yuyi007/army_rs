class CreateGuildActiveReport< ActiveRecord::Migration
  def up
    create_table :guild_active do |t|
      t.integer :zone_id,        :default => 0
      t.string  :sdk,            :null => false, :limit => 50
      t.string  :platform,       :null => false, :limit => 10
      t.date    :date,           :null => false
      t.string  :guild_id
      t.string  :active_type
    end
    add_index :guild_active, [:date, :zone_id]

    create_table :guild_active_report do |t|
      t.integer :zone_id,        :default => 0
      t.string  :sdk,            :null => false, :limit => 50
      t.string  :platform,       :null => false, :limit => 10
      t.date    :date,           :null => false
      t.string  :guild_id
      t.string  :active_type
      t.integer :num
    end
    add_index :guild_active_report, [:date, :zone_id, :active_type, :guild_id],
      :name => 'index_gar_on_dt_and_zone_and_act_and_gid'
  end

  def down
    drop_table :guild_active
    drop_table :guild_active_report
  end
end
