class CreateMainQuestReport < ActiveRecord::Migration
  def up
    create_table :main_quest_report, :options => 'ENGINE=InnoDB DEFAULT CHARSET=utf8' do |t|
      t.date     :date,                   :null => false
      t.integer  :zone_id,                :default => 1
      t.string   :tid,                    :default => ''
      t.integer  :num,                    :default => 0
    end
    add_index :main_quest_report, [:date, :zone_id]
  end

  def down
    drop_table :main_quest_report
  end
end