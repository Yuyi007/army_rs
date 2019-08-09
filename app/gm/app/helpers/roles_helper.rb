# encoding: utf-8

module RolesHelper

  ROLE_DESC__ = {
    'admin' => :perm_admin, 
    'p0' => :perm_p0, 
    'p1' => :perm_p1, 
    'p2' => :perm_p2, 
    'p3' => :perm_p3, 
    'p4' => :perm_p4, 
    'guest' => :perm_guest, 
  }

  def self.ROLE_DESC
    desc = {}
    ROLE_DESC__.each { |k,v| desc[k] = I18n.t(v) }
    desc
  end

end
