class CreateGuildLevelRecord < ActiveRecord::Migration
  def change
    create_table :guild_level_record do |t|
      t.date :record_date,  :null => false
      t.integer :zone
      t.integer :level_1
      t.integer :level_2
      t.integer :level_3
      t.integer :level_4
      t.integer :level_5
      t.integer :level_6
      t.integer :level_7
      t.integer :level_8
      t.integer :level_9
      t.integer :level_10
      t.integer :level_11_15
      t.integer :level_16_20
      t.integer :level_21_25
      t.integer :level_26_30
      t.integer :level_over_30

      t.integer :level_1_person
      t.integer :level_2_person
      t.integer :level_3_person
      t.integer :level_4_person
      t.integer :level_5_person
      t.integer :level_6_person
      t.integer :level_7_person
      t.integer :level_8_person
      t.integer :level_9_person
      t.integer :level_10_person
      t.integer :level_11_15_person
      t.integer :level_16_20_person
      t.integer :level_21_25_person
      t.integer :level_26_30_person
      t.integer :level_over_30_person

    end
    add_index :guild_level_record, [:record_date, :zone]
  end
end
