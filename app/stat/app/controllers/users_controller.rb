class UsersController < ApplicationController
  def login
  end

  def regist
  end

  def do_regist
    email = params[:email]
    password = params[:password]
    ng('invalid args') if email.nil? || password.nil?
    
    res = {'success' => 'ok'}
    sql_check_exist = %Q{select id from sys_users where email='#{email}'}
    ret = execSql(sql_check_exist)
    return ng('already registed email!') if ret.rows.length >= 1

    pwd = Digest::SHA1.hexdigest(password)
    # sql_regist_user = %Q{insert into sys_users (email, password, roleid, inuse) values ('#{email}', '#{pwd}', 2, true)}
    # execSql(sql_regist_user)
    rc = SiteUsers::SysUsers.new
    rc.email = email
    rc.password = pwd
    rc.roleid = 2
    rc.inuse = true
    rc.save
    sendc(res)
  end

  def do_login
    email = params[:email]
    password = params[:password]

    res = {'success' => 'ok'}
    ok, uid = verify(email, password) 
    if ok
      res['uid'] = uid
      res['sid'] = sign_up(uid)
    else
      res['success'] = 'fail'
      res['reason'] = 'verify failed'
    end

    sendc(res)
  end

  def verify(email, password)
    return false if password.nil? || email.nil?

    pwd = Digest::SHA1.hexdigest(password) 
    user = SiteUsers::SysUsers.where(:email => email, :password => pwd).first
    [!user.nil?, user.id]
  end

  def do_logout
    sid = params[:sid]
    remove_session(sid)
    
    res = {'success' => 'ok'}
    sendc(res)
  end

  def role_list
    return ng('verify fail') if !check_session

    res = {'success' => 'ok'}
    sql = %Q{select * from sys_roles a order by id}
    rows = execSql(sql)
    res['res'] = rows.to_hash
    sendc(res)
  end

  def save_role
    return ng('verify fail') if !check_session
    id = params[:id]
    name = params[:name]
    desc = params[:desc]
    return ng('invalid args') if id.nil? || name.nil? || desc.nil?

    rc = SiteUsers::SysRoles.where(:name => name).first_or_initialize
    rc.name = name
    rc.desc = desc
    rc.save

    res = {'success' => 'ok'}
    sendc(res)
  end

  def remove_role
    return ng('verify fail') if !check_session

    id = params[:id]
    return ng('invalid args') if id.nil? 

    rc = SiteUsers::SysRoles.find(id)
    rc.destroy if !rc.nil?

    res = {'success' => 'ok'}
    sendc(res)
  end

  def right_manage
  end

  def save_role_rights
    return ng('verify fail') if !check_session
    roleid = params[:roleid]
    funids = params[:funids]
    return ng('invalid args') if roleid.nil? || funids.nil?

    funids = JSON.parse(funids)

    rc = SiteUsers::SysRights.where(:roleid => roleid)
    rc.destroy_all if !rc.nil?

    funids.each_with_index do |v, i|
      rc = SiteUsers::SysRights.new
      rc.roleid = roleid.to_i
      rc.funid = v.to_i
      rc.save
    end

    sendok
  end

  def role_funcs
    return ng('verify fail') if !check_session
    roleid = params[:roleid]
    return ng('invalid args') if roleid.nil? 

    
    sql = "select funid from sys_rights where roleid=#{roleid}"
    rows = execSql(sql)
    res = {'success' => 'ok'}
    res['res'] = rows.to_hash
    sendc(res)
  end

  def func_list
    return ng('verify fail') if !check_session

    res = {'success' => 'ok'}
    sql = %Q{select * from sys_functions}
    rows = execSql(sql)
    res['res'] = rows.to_hash
    sendc(res)
  end

  def user_list
    uid = check_session
    return ng('verify fail') if uid.nil?

    sql = %Q{select u.id as id, u.email as email, r.name as role, u.inuse as inuse from sys_users as u join sys_roles as r where u.roleid = r.id and u.id != #{uid}}
    rows = execSql(sql)
    res = {'success' => 'ok'}
    res['res'] = rows.to_hash
    
    sendc(res)
  end

  def enable_account
    return ng('verify fail') if !check_session

    uid = params[:id]
    inuse = params[:inuse]
    return ng('invalid args') if uid.nil? || inuse.nil?

    rc = SiteUsers::SysUsers.find(uid)
    return ng('not exist') if rc.nil?
    inuse = 1 - inuse.to_i
    binuse = false
    binuse = true if inuse == 1
    rc.inuse = binuse
    rc.save

    sendc({'success' => 'ok'})
  end

  def do_change_role
    return ng('verify fail') if !check_session

    roleid = params[:roleid]
    uid = params[:uid]
    return ng('invalid args') if roleid.nil? || uid.nil?

    rc = SiteUsers::SysUsers.find(uid)
    return ng('not exist') if rc.nil?

    rc.roleid = roleid
    rc.save

    sendc({'success' => 'ok'})
  end
end