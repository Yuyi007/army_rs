class CreateGuildSkill < ActiveRecord::Migration
  def change
    create_table :guild_skill do |t|
      t.string   :sdk,            :null => false, :limit => 50
      t.string   :platform,       :null => false, :limit => 10
      t.integer  :zone_id,        :default => 1
      t.string  :pid
      t.integer :guild_skill_1
      t.integer :guild_skill_2
      t.integer :guild_skill_3
      t.integer :guild_skill_4
      t.integer :guild_skill_5
      t.integer :guild_skill_6
    end
    add_index :guild_skill, [:pid, :zone_id]
  end
end
