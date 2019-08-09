class AddUpdatedAtToSiteUsers < ActiveRecord::Migration

  def change
    add_column :site_users, :created_at, :datetime
    add_column :site_users, :updated_at, :datetime
  end

  def down
    remove_column :site_users, :created_at
    remove_column :site_users, :updated_at
  end

end
