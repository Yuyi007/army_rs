class CreateAddEquipReport < ActiveRecord::Migration
  def up
    create_table :add_equip_report, :options => 'ENGINE=InnoDB DEFAULT CHARSET=utf8' do |t|
      t.integer :zone_id,   :default => 1
      t.date    :date,      :null => false
      t.string  :reason,    :max => 64
      t.integer :grade,     :default => 0, :limit => 8
      t.integer :star,      :default => 0, :limit => 8
      t.integer :suits,     :default => 0, :limit => 8
      t.integer :scarces,   :default => 0, :limit => 8
      t.integer :normals,   :default => 0, :limit => 8
    end
    add_index :add_equip_report, [:zone_id, :date, :grade, :star]
  end

  def down
    drop_table :add_equip_report
  end
end