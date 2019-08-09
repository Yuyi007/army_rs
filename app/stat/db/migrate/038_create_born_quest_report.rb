
class CreateBornQuestReport < ActiveRecord::Migration
  def up
    create_table :born_quest, :options => 'ENGINE=InnoDB DEFAULT CHARSET=utf8' do |t|
      t.integer  :zone_id,        :default => 0
      t.string   :sdk,            :null => false, :limit => 50
      t.string   :platform,       :null => false, :limit => 10
      t.date     :date,           :null => false
      t.string   :tid,            :null => false
      t.string  :pid,             :null => false
    end
    add_index :born_quest, [:date, :zone_id]


    create_table :born_quest_report, :options => 'ENGINE=InnoDB DEFAULT CHARSET=utf8' do |t|
      t.integer  :zone_id,        :default => 0
      t.string   :sdk,            :null => false, :limit => 50
      t.string   :platform,       :null => false, :limit => 10
      t.date     :date,           :null => false
      t.string   :tid,            :null => false
      t.integer  :num,            :default => 0
    end
    add_index :born_quest_report, [:date, :zone_id]
  
  end

  def down
    drop_table :born_quest
    drop_table :born_quest_report
  end

end