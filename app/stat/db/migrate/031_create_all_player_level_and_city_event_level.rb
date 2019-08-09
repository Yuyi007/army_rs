class CreateAllPlayerLevelAndCityEventLevel < ActiveRecord::Migration
  def up
    create_table :all_player_level_and_city_event_level, :options => 'ENGINE=InnoDB DEFAULT CHARSET=utf8' do |t|
      t.integer  :zone_id,        :default => 0
      t.string   :sdk,            :null => false, :limit => 50
      t.string   :platform,       :null => false, :limit => 10
      t.string   :pid
      t.integer  :level,          :default => 1
      t.integer  :vip_level,      :default => 0
      t.integer  :city_event_level,          :default => 1
    end
    add_index :all_player_level_and_city_event_level, [:pid]

    create_table :all_player_level, :options => 'ENGINE=InnoDB DEFAULT CHARSET=utf8' do |t|
      t.integer  :zone_id,        :default => 0
      t.string   :sdk,            :null => false, :limit => 50
      t.string   :platform,       :null => false, :limit => 10
      t.date     :date
      t.integer  :level,          :default => 1
      t.integer  :num,          :default => 1
    end

    add_index :all_player_level, [:date, :zone_id, :level]

    create_table :all_city_event_level, :options => 'ENGINE=InnoDB DEFAULT CHARSET=utf8' do |t|
      t.integer  :zone_id,        :default => 0
      t.string   :sdk,            :null => false, :limit => 50
      t.string   :platform,       :null => false, :limit => 10
      t.date     :date
      t.integer  :level,                     :default => 1
      t.integer  :num,                       :default => 1
    end

    add_index :all_city_event_level, [:date, :zone_id, :level]

  end

  def down
    drop_table :all_player_level_and_city_event_level
    drop_table :all_player_level
    drop_table :all_city_event_level
  end

end