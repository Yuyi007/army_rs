class AddVerifiedToSiteUser < ActiveRecord::Migration

  def change
    add_column :site_users, :verified, :boolean, :default => false

    # existing users don't need to verify
    SiteUser.all.each { |user| user.verified = true; user.save(:validate => false) }
  end

  def down
    remove_column :site_users, :verified
  end

end
