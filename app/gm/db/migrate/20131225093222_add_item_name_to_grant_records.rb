class AddItemNameToGrantRecords < ActiveRecord::Migration
  def up
  	add_column :grant_records, :item_name, :string
  end

  def down
  	remove_column :grant_records, :item_name
  end
end
