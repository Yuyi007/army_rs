module SiteUsers
  class SysRoles < ActiveRecord::Base
    self.table_name = :sys_roles
    attr_accessible  :id
    attr_accessible :name
    attr_accessible :desc
  end

  class SysFunctions < ActiveRecord::Base
    self.table_name = :sys_functions
    attr_accessible  :id
    attr_accessible :name
    attr_accessible :desc
  end

  class SysRights < ActiveRecord::Base
    self.table_name = :sys_rights
    attr_accessible :roleid
    attr_accessible :funid
  end

  class SysUsers < ActiveRecord::Base
    self.table_name = :sys_users
    attr_accessible  :id
    attr_accessible  :email
    attr_accessible  :password
    attr_accessible  :roleid
    attr_accessible  :inuse
  end
end