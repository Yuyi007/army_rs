class CreateGrantRecords < ActiveRecord::Migration
  def change
    create_table :grant_records do |t|
      t.integer :site_user_id
      t.string :action
      t.boolean :success
      t.string :target_id
      t.string :target_zone
      t.string :item_id
      t.string :item_amount
      t.text :reason
      t.string :status

      t.timestamps
    end
  end

  def down
    drop_table :grant_records
  end
end
