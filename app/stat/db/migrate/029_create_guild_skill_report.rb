class CreateGuildSkillReport < ActiveRecord::Migration
  def change
    create_table :guild_skill_report do |t|
      t.string   :sdk,            :null => false, :limit => 50
      t.string   :platform,       :null => false, :limit => 10
      t.integer  :zone_id,        :default => 1
      t.date     :date,  :null => false
      t.string   :skill_id
      t.integer  :lv_rgn
      t.integer  :num
    end

    add_index :guild_skill_report, [:date, :zone_id, :skill_id, :lv_rgn],
      :name => 'index_gkr_on_rd_and_zone_and_sid_and_lr'
  end
end
