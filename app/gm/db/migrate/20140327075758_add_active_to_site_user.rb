class AddActiveToSiteUser < ActiveRecord::Migration

  def change
    add_column :site_users, :active, :boolean, :default => true
  end

  def down
    remove_column :site_users, :active
  end

end
