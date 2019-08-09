class ChangeCdkey < ActiveRecord::Migration
  def up
    change_column :cdkeys, :key, :string, :limit => 30
    change_column :cdkeys, :zone, :integer, :limit => 4
  end

  def down
  end
end
