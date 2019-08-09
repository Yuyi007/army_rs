class AddIdToCdkeys < ActiveRecord::Migration
  def change
    add_column :cdkeys, :id, :integer
  end
end
