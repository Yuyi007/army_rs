class CreateChiefLevel < ActiveRecord::Migration
  def up
    create_table :chief_level_report, :options => 'ENGINE=InnoDB DEFAULT CHARSET=utf8' do |t|
      t.date     :date,           :null => false
      t.integer  :level,          :default => 1
      t.integer  :zone_id,        :default => 1
      t.integer  :num,            :default => 0
    end

    add_index :chief_level_report, [:date, :level, :zone_id]
  end

  def down
    drop_table :chief_level_report
  end

end