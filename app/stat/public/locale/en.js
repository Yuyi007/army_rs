map_string = {
  "alert": "Alert",
  "str_sys_inter_err": "System internal error!",
  "str_passwore_length_err": "Password length must grater than 6!",
  "err_wrong_email_pass": "Wrong email or password!",
  "err_invalid_param": "Invalid parameters!".
  "str_login": "Login",
  "str_email": "Email:",
  "str_password": "PassWord:",
  "str_confirm_password": "Confirm password:",
  "str_regist": "Regist",
  "err_email_format": "User name must be an email!",
  "str_functions": "Function list",
  "str_user_manage": "User Manage",
  "str_role_manage": "Role Manage",
  "str_logout": "Logout",
  "str_add_new_role": "Add new role",
  "str_id": "ID",
  "str_name": "Name",
  "str_description": "Description",
  "str_remove_alert": "Make sure remove?",
  "str_save_success": "Save Success!",
  "str_save": "Save",
  "str_cancel": "Cancel",
  "str_check_rights": "Check rights",
  "str_role": "Role",
  "yes": "Yes",
  "no": "No",
  "delete": "Delete",
  "modify": "Modify",
  "str_inuse": "Inuse",
  "str_switch_inuse": "enable/disable",
  "str_tip_modify_role": "Modify rights of a role",
  "str_remove_role": "Delete the Role",
  "str_switch_inuse": "Enable or disable account",
  "str_modify_user_role": "Modify role of account",
  "str_role_manage": "Select a role",
  "str_gen_today": "Force generate stats of today",
  "str_gen_today_stats_success": "Generating today stats is success!",
  "str_level_consume": "consume distribution query",
  "str_consume_report": "consume distribution report",
  "str_date": "Date",
  "str_zone": "zone",
  "str_plz_select_zone": "plz select zone",
  "str_huobi_cat": "cost type",
  "str_plz_select_category": "plz select cost",
  "str_sys_cat": "system",
  "str_plz_select_syscat": "plz select system",
  "str_credits": "credits",
  "str_coins": "coins",
  "str_money": "money",
  "str_voucher": "voucher",
  "str_query": "query"
  "str_module_users": "users",
  "str_module_statshelper": "game report",
  "str_module_statsorign": "common report"
}

function loc(id)
{
  if(!map_string[id])
  {
    return id;
  }
  return map_string[id];
}