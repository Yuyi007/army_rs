class MainController < ApplicationController
  def dashboard
  end

  def get_rights
    sid = params[:sid]
    return ng('verify fail') if sid.nil?
    uid = check_session(sid)
    return ng('verify fail') if uid.nil?

    res = {'success' => 'ok'}
    sql = %Q{select f.name from sys_rights as r join sys_functions as f join sys_roles as o join sys_users as u 
            where u.id=#{uid} and u.roleid=o.id and r.roleid=o.id and f.id=r.funid
            order by name desc }
    rows = execSql(sql)
    funcs = []
    rows.each do |row|
      funcs << row['name']
    end
    res['res'] = funcs
    sendc(res)
  end
end