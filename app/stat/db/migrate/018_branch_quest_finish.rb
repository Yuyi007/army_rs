class BranchQuestFinish < ActiveRecord::Migration
  def up
    create_table :branch_quest_finish, :options => 'ENGINE=InnoDB DEFAULT CHARSET=utf8' do |t|
      t.integer :zone_id,        :default => 0
      t.string  :sdk,            :null => false, :limit => 50
      t.string  :platform,       :null => false, :limit => 10
      t.date    :date
      t.string  :tid
      t.string  :category
      t.integer :count,   :default => 0, :limit => 8
    end
    add_index :branch_quest_finish, :zone_id

    create_table :branch_quest_finish_report, :options => 'ENGINE=InnoDB DEFAULT CHARSET=utf8' do |t|
      t.integer :zone_id,        :default => 0
      t.string  :sdk,            :null => false, :limit => 50
      t.string  :platform,       :null => false, :limit => 10
      t.date    :date
      t.string  :tid
      t.string  :category
      t.integer :count,   :default => 0, :limit => 8
    end
    add_index :branch_quest_finish_report, :zone_id
  end

  def down
    drop_table :branch_quest_finish
    drop_table :branch_quest_finish_report
  end
end