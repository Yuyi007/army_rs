class AddSdkToCdkey < ActiveRecord::Migration
  def change
    # add_column :cdkeys, :bonus_id, :string
    add_column :cdkeys, :sdk, :string
  end
end
