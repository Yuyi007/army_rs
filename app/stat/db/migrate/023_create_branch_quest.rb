class CreateBranchQuest < ActiveRecord::Migration
  def up
    create_table :create_branch_quest, :options => 'ENGINE=InnoDB DEFAULT CHARSET=utf8' do |t|
      t.integer :zone_id,        :default => 0
      t.string  :sdk,            :null => false, :limit => 50
      t.string  :platform,       :null => false, :limit => 10
      t.date    :date
      t.string  :tid
      t.string  :category
      t.integer :count,   :default => 0, :limit => 8
    end
    add_index :create_branch_quest, :zone_id


    create_table :create_branch_quest_report, :options => 'ENGINE=InnoDB DEFAULT CHARSET=utf8' do |t|
      t.integer :zone_id,        :default => 0
      t.string  :sdk,            :null => false, :limit => 50
      t.string  :platform,       :null => false, :limit => 10
      t.date    :date
      t.string  :tid
      t.string  :category
      t.integer :count,   :default => 0, :limit => 8
    end
    add_index :create_branch_quest_report, :zone_id
  end

  def down
    drop_table :create_branch_quest
    drop_table :create_branch_quest_report
  end
end