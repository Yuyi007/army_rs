class CreateFactionAll < ActiveRecord::Migration
  def up
     create_table :all_factions, :options => 'ENGINE=InnoDB DEFAULT CHARSET=utf8' do |t|
      t.integer  :zone_id,        :default => 0
      t.string   :sdk,            :null => false, :limit => 50
      t.string   :platform,       :null => false, :limit => 10
      t.string   :pid,            :null => false
      t.string   :faction,        :null => false
    end
    add_index :all_factions, [:zone_id, :pid, :faction]

    create_table :all_factions_report, :options => 'ENGINE=InnoDB DEFAULT CHARSET=utf8' do |t|
      t.integer  :zone_id,        :default => 0
      t.string   :sdk,            :null => false, :limit => 50
      t.string   :platform,       :null => false, :limit => 10
      t.date    :date
      t.integer :players, :default => 0, :limit => 8
      t.integer :accounts, :default => 0, :limit => 8
      t.string  :faction
    end
    add_index :all_factions_report, [:zone_id, :faction]
  end

  def down
    drop_table :all_factions
    drop_table :all_factions_report
  end
end