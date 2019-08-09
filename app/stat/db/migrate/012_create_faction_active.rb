class CreateFactionActive < ActiveRecord::Migration
  def up
    create_table :active_factions, :options => 'ENGINE=InnoDB DEFAULT CHARSET=utf8' do |t|
      t.integer :zone_id, :default => 1
      t.date    :date
      t.integer :count_by_player, :default => 0, :limit => 8
      t.integer :count_by_account, :default => 0, :limit => 8

      t.string  :faction
    end
    add_index :active_factions, :zone_id
  end

  def down
    drop_table :active_factions
  end
end