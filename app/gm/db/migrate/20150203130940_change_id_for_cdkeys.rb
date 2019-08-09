class ChangeIdForCdkeys < ActiveRecord::Migration
  def change
    change_column :cdkeys, :id, :primary_key
  end

end
