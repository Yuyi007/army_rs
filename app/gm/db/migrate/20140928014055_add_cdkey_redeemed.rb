class AddCdkeyRedeemed < ActiveRecord::Migration
  def up
    add_column :cdkeys, :redeemed, :boolean, :default => false
  end

  def down
  end
end
