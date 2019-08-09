
class SiteUser < ActiveRecord::Base

  acts_as_authentic do |c|
    c.session_class = UserSession
    c.login_field = :email
    c.transition_from_crypto_providers = Authlogic::CryptoProviders::MD5
    c.crypto_provider = Authlogic::CryptoProviders::Sha512
    c.logged_in_timeout = 1.hours
  end

  validates_uniqueness_of :username

  validates_format_of :username,
    :with => /^([a-z]|[A-Z]|[\d_]){4,40}$/,
    :message => "must only include numbers, letters, underscores and be between 4 and 40 characters"

  validates_format_of :password,
    :with => /^(?=.*\d)(?=.*[a-z])(?=.*[A-Z])[\x20-\x7E]{8,40}$/,
    :if => :require_password?,
    :message => "must include at least one number, one uppercase letter, one lowercase letter and be between 8 and 40 characters"

  acts_as_authorization_subject :role_class_name => 'Role', :association_name => :roles, :join_table_name => :roles_users

  has_and_belongs_to_many :roles, :join_table => :roles_users
  has_many :site_user_records
  has_many :grant_records

  attr_accessible :username, :verified, :email, :password, :password_confirmation, :crypted_password, :password_salt, :persistence_token

  def deliver_verification_instructions!
    reset_perishable_token!
    SiteUserMailer.verification_instructions(self).deliver
    true
  end

  def verify!
    self.verified = true
    self.save
  end

  def role_name
    if has_role?(:admin)
      'admin'
    elsif has_role?(:p0)
      'p0'
    elsif has_role?(:p1)
      'p1'
    elsif has_role?(:p2)
      'p2'
    elsif has_role?(:p3)
      'p3'
    elsif has_role?(:p4)
      'p4'
    elsif has_role?(:p5)
      'p5'
    elsif has_role?(:p6)
      'p6'
    else
      'guest'
    end
  end

  def role_id
    Role.get_id_by_name(role_name)
  end

  def can_edit_by? user
    user.id == id or (user.role_name == 'admin' and role_name != 'admin')
  end

  def self.find_by_username_or_email(value)
    find_by_username(value) || find_by_email(value)
  end

end