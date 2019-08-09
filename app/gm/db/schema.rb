# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20180111070506) do

  create_table "action_logs", :id => false, :force => true do |t|
    t.string   "player_id",  :limit => 40, :null => false
    t.integer  "zone",       :limit => 2,  :null => false
    t.string   "t",          :limit => 30, :null => false
    t.string   "param1",     :limit => 30
    t.string   "param2",     :limit => 30
    t.string   "param3",     :limit => 30
    t.string   "param4",     :limit => 10
    t.string   "param5",     :limit => 10
    t.datetime "created_at",               :null => false
    t.string   "param6",     :limit => 10
  end

  add_index "action_logs", ["created_at"], :name => "index_action_logs_on_created_at"
  add_index "action_logs", ["player_id", "created_at"], :name => "index_action_logs_on_player_id_and_created_at"
  add_index "action_logs", ["t", "created_at"], :name => "index_action_logs_on_t_and_created_at"
  add_index "action_logs", ["zone", "created_at"], :name => "index_action_logs_on_zone_and_created_at"

  create_table "bills", :force => true do |t|
    t.string   "sdk"
    t.string   "platform"
    t.string   "transId",    :null => false
    t.string   "playerId"
    t.string   "zone"
    t.string   "goodsId"
    t.integer  "count"
    t.integer  "price"
    t.integer  "status"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
    t.string   "detail"
    t.string   "pid"
    t.string   "market"
  end

  add_index "bills", ["market"], :name => "index_bills_on_market"
  add_index "bills", ["pid"], :name => "index_bills_on_pid"
  add_index "bills", ["platform"], :name => "index_bills_on_platform"
  add_index "bills", ["playerId"], :name => "index_bills_on_playerId"
  add_index "bills", ["sdk"], :name => "index_bills_on_sdk"
  add_index "bills", ["status"], :name => "index_bills_on_status"
  add_index "bills", ["transId"], :name => "index_bills_on_transId"
  add_index "bills", ["zone"], :name => "index_bills_on_zone"

  create_table "cdkeys", :force => true do |t|
    t.string   "player_id",   :limit => 40
    t.integer  "zone",        :limit => 4
    t.string   "tid",         :limit => 20,                    :null => false
    t.string   "key",         :limit => 30,                    :null => false
    t.datetime "created_at",                                   :null => false
    t.boolean  "redeemed",                  :default => false
    t.string   "bonus_id",    :limit => 40
    t.integer  "bonus_count", :limit => 4
    t.datetime "end_time"
    t.string   "sdk"
  end

  add_index "cdkeys", ["created_at"], :name => "index_cdkeys_on_created_at"
  add_index "cdkeys", ["key"], :name => "index_cdkeys_on_key"
  add_index "cdkeys", ["player_id", "created_at"], :name => "index_cdkeys_on_player_id_and_created_at"
  add_index "cdkeys", ["tid", "created_at"], :name => "index_cdkeys_on_t_and_created_at"
  add_index "cdkeys", ["zone", "created_at"], :name => "index_cdkeys_on_zone_and_created_at"

  create_table "grant_records", :force => true do |t|
    t.integer  "site_user_id"
    t.string   "action"
    t.boolean  "success"
    t.text     "target_id",    :limit => 255
    t.string   "target_zone"
    t.string   "item_id"
    t.string   "item_amount"
    t.text     "reason"
    t.string   "status"
    t.datetime "created_at",                  :null => false
    t.datetime "updated_at",                  :null => false
    t.string   "item_name"
  end

  create_table "notif_alerts", :force => true do |t|
    t.string   "name",       :limit => 40,                   :null => false
    t.string   "receivers",  :limit => 50
    t.boolean  "enabled",                  :default => true
    t.datetime "created_at",                                 :null => false
    t.datetime "updated_at",                                 :null => false
  end

  add_index "notif_alerts", ["name"], :name => "index_notif_alerts_on_name", :unique => true

  create_table "notif_receivers", :force => true do |t|
    t.string   "name",       :limit => 40, :null => false
    t.string   "mobile",     :limit => 15, :null => false
    t.string   "email",      :limit => 50
    t.datetime "created_at",               :null => false
    t.datetime "updated_at",               :null => false
  end

  create_table "roles", :force => true do |t|
    t.string   "name",              :limit => 40, :null => false
    t.string   "authorizable_type", :limit => 40, :null => false
    t.integer  "authorizable_id",                 :null => false
    t.datetime "created_at",                      :null => false
    t.datetime "updated_at",                      :null => false
  end

  add_index "roles", ["authorizable_id"], :name => "index_roles_on_authorizable_id"
  add_index "roles", ["authorizable_type"], :name => "index_roles_on_authorizable_type"
  add_index "roles", ["name", "authorizable_id", "authorizable_type"], :name => "index_roles_on_name_and_authorizable_id_and_authorizable_type", :unique => true
  add_index "roles", ["name"], :name => "index_roles_on_name"

  create_table "roles_users", :id => false, :force => true do |t|
    t.integer "site_user_id"
    t.integer "role_id"
  end

  add_index "roles_users", ["role_id"], :name => "index_roles_users_on_role_id"
  add_index "roles_users", ["site_user_id", "role_id"], :name => "index_roles_users_on_site_user_id_and_role_id", :unique => true
  add_index "roles_users", ["site_user_id"], :name => "index_roles_users_on_site_user_id"

  create_table "site_user_records", :id => false, :force => true do |t|
    t.integer  "site_user_id"
    t.string   "action",       :default => "unknown", :null => false
    t.boolean  "success",      :default => true,      :null => false
    t.string   "target"
    t.integer  "zone"
    t.string   "tid"
    t.integer  "count"
    t.string   "param1"
    t.string   "param2"
    t.string   "param3"
    t.datetime "created_at",                          :null => false
    t.datetime "updated_at",                          :null => false
  end

  add_index "site_user_records", ["action"], :name => "index_site_user_records_on_action"
  add_index "site_user_records", ["site_user_id"], :name => "index_site_user_records_on_site_user_id"
  add_index "site_user_records", ["target"], :name => "index_site_user_records_on_target"
  add_index "site_user_records", ["tid"], :name => "index_site_user_records_on_tid"

  create_table "site_users", :force => true do |t|
    t.string   "username",            :default => "",    :null => false
    t.string   "email",                                  :null => false
    t.string   "crypted_password",                       :null => false
    t.string   "password_salt",                          :null => false
    t.string   "persistence_token",                      :null => false
    t.string   "single_access_token",                    :null => false
    t.string   "perishable_token",                       :null => false
    t.integer  "login_count",         :default => 0,     :null => false
    t.integer  "failed_login_count",  :default => 0,     :null => false
    t.datetime "last_request_at"
    t.datetime "current_login_at"
    t.datetime "last_login_at"
    t.string   "current_login_ip"
    t.string   "last_login_ip"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "active",              :default => true
    t.boolean  "verified",            :default => false
  end

  create_table "user_sessions", :force => true do |t|
    t.string   "session_id", :null => false
    t.text     "data"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  add_index "user_sessions", ["session_id"], :name => "index_user_sessions_on_session_id"
  add_index "user_sessions", ["updated_at"], :name => "index_user_sessions_on_updated_at"

end
