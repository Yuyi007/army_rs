
class Role < ActiveRecord::Base

  acts_as_authorization_role :join_table_name => :roles_users

  has_and_belongs_to_many :site_users, :join_table => :roles_users

  attr_accessible :name, :authorizable_type, :authorizable_id

  def self.get_id_by_name(name)
    role = Role.where("name = ?", name).first
    if role then
      role.authorizable_id
    else
      7
    end
  end

end