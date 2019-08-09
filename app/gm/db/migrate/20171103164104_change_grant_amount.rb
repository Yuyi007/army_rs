class ChangeGrantAmount < ActiveRecord::Migration
  def up
  	change_column :grant_records, :item_amount, :string
  end

  def down
  	change_column :grant_records, :item_amount, :integer
  end
end
