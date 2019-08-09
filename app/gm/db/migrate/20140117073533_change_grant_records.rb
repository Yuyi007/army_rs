class ChangeGrantRecords < ActiveRecord::Migration
  def up
  	change_column :grant_records, :target_id, :text
  	change_column :grant_records, :item_amount, :string
  end

  def down
  	change_column :grant_records, :target_id, :string
  	change_column :grant_records, :item_amount, :integer
  end
end
