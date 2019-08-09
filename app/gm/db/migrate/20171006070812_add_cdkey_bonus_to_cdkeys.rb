class AddCdkeyBonusToCdkeys < ActiveRecord::Migration
  def change
    # add_column :cdkeys, :bonus_id, :string
    add_column :cdkeys, :bonus_id,      :string,      :limit => 40
    add_column :cdkeys, :bonus_count,   :integer,     :limit => 4
    add_column :cdkeys, :end_time,      :datetime
  end
end
