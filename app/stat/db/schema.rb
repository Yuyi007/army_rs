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

ActiveRecord::Schema.define(:version => 42) do

  create_table "account_activity_reports", :force => true do |t|
    t.date    "date",                    :null => false
    t.integer "total",    :default => 0
    t.integer "num_m5",   :default => 0
    t.integer "num_m10",  :default => 0
    t.integer "num_m15",  :default => 0
    t.integer "num_m20",  :default => 0
    t.integer "num_m25",  :default => 0
    t.integer "num_m30",  :default => 0
    t.integer "num_m35",  :default => 0
    t.integer "num_m40",  :default => 0
    t.integer "num_m45",  :default => 0
    t.integer "num_m50",  :default => 0
    t.integer "num_m55",  :default => 0
    t.integer "num_m60",  :default => 0
    t.integer "num_m120", :default => 0
    t.integer "num_m180", :default => 0
    t.integer "num_m300", :default => 0
    t.integer "m300plus", :default => 0
  end

  add_index "account_activity_reports", ["date"], :name => "index_account_activity_reports_on_date", :unique => true

  create_table "account_market_activity_reports", :force => true do |t|
    t.date    "date",                                  :null => false
    t.string  "market",   :limit => 20,                :null => false
    t.integer "total",                  :default => 0
    t.integer "num_m5",                 :default => 0
    t.integer "num_m10",                :default => 0
    t.integer "num_m15",                :default => 0
    t.integer "num_m20",                :default => 0
    t.integer "num_m25",                :default => 0
    t.integer "num_m30",                :default => 0
    t.integer "num_m35",                :default => 0
    t.integer "num_m40",                :default => 0
    t.integer "num_m45",                :default => 0
    t.integer "num_m50",                :default => 0
    t.integer "num_m55",                :default => 0
    t.integer "num_m60",                :default => 0
    t.integer "num_m120",               :default => 0
    t.integer "num_m180",               :default => 0
    t.integer "num_m300",               :default => 0
    t.integer "m300plus",               :default => 0
  end

  add_index "account_market_activity_reports", ["date", "market"], :name => "index_account_market_activity_reports_on_date_and_market", :unique => true
  add_index "account_market_activity_reports", ["market"], :name => "index_account_market_activity_reports_on_market"

  create_table "account_market_retention_reports", :force => true do |t|
    t.date    "date",                                 :null => false
    t.string  "market",  :limit => 20,                :null => false
    t.integer "num_d0",                :default => 0
    t.integer "num_d1",                :default => 0
    t.integer "num_d2",                :default => 0
    t.integer "num_d3",                :default => 0
    t.integer "num_d4",                :default => 0
    t.integer "num_d5",                :default => 0
    t.integer "num_d6",                :default => 0
    t.integer "num_d7",                :default => 0
    t.integer "num_d8",                :default => 0
    t.integer "num_d9",                :default => 0
    t.integer "num_d10",               :default => 0
    t.integer "num_d11",               :default => 0
    t.integer "num_d12",               :default => 0
    t.integer "num_d13",               :default => 0
    t.integer "num_d14",               :default => 0
    t.integer "num_d15",               :default => 0
    t.integer "num_d16",               :default => 0
    t.integer "num_d17",               :default => 0
    t.integer "num_d18",               :default => 0
    t.integer "num_d19",               :default => 0
    t.integer "num_d20",               :default => 0
    t.integer "num_d21",               :default => 0
    t.integer "num_d22",               :default => 0
    t.integer "num_d23",               :default => 0
    t.integer "num_d24",               :default => 0
    t.integer "num_d25",               :default => 0
    t.integer "num_d26",               :default => 0
    t.integer "num_d27",               :default => 0
    t.integer "num_d28",               :default => 0
    t.integer "num_d29",               :default => 0
    t.integer "num_d30",               :default => 0
    t.integer "num_d90",               :default => 0
  end

  add_index "account_market_retention_reports", ["date", "market"], :name => "index_account_market_retention_reports_on_date_and_market", :unique => true
  add_index "account_market_retention_reports", ["market"], :name => "index_account_market_retention_reports_on_market"

  create_table "account_platform_activity_reports", :force => true do |t|
    t.date    "date",                                  :null => false
    t.string  "platform", :limit => 20,                :null => false
    t.integer "total",                  :default => 0
    t.integer "num_m5",                 :default => 0
    t.integer "num_m10",                :default => 0
    t.integer "num_m15",                :default => 0
    t.integer "num_m20",                :default => 0
    t.integer "num_m25",                :default => 0
    t.integer "num_m30",                :default => 0
    t.integer "num_m35",                :default => 0
    t.integer "num_m40",                :default => 0
    t.integer "num_m45",                :default => 0
    t.integer "num_m50",                :default => 0
    t.integer "num_m55",                :default => 0
    t.integer "num_m60",                :default => 0
    t.integer "num_m120",               :default => 0
    t.integer "num_m180",               :default => 0
    t.integer "num_m300",               :default => 0
    t.integer "m300plus",               :default => 0
  end

  add_index "account_platform_activity_reports", ["date", "platform"], :name => "index_account_platform_activity_reports_on_date_and_platform", :unique => true
  add_index "account_platform_activity_reports", ["platform"], :name => "index_account_platform_activity_reports_on_platform"

  create_table "account_platform_retention_reports", :force => true do |t|
    t.date    "date",                                  :null => false
    t.string  "platform", :limit => 20,                :null => false
    t.integer "num_d0",                 :default => 0
    t.integer "num_d1",                 :default => 0
    t.integer "num_d2",                 :default => 0
    t.integer "num_d3",                 :default => 0
    t.integer "num_d4",                 :default => 0
    t.integer "num_d5",                 :default => 0
    t.integer "num_d6",                 :default => 0
    t.integer "num_d7",                 :default => 0
    t.integer "num_d8",                 :default => 0
    t.integer "num_d9",                 :default => 0
    t.integer "num_d10",                :default => 0
    t.integer "num_d11",                :default => 0
    t.integer "num_d12",                :default => 0
    t.integer "num_d13",                :default => 0
    t.integer "num_d14",                :default => 0
    t.integer "num_d15",                :default => 0
    t.integer "num_d16",                :default => 0
    t.integer "num_d17",                :default => 0
    t.integer "num_d18",                :default => 0
    t.integer "num_d19",                :default => 0
    t.integer "num_d20",                :default => 0
    t.integer "num_d21",                :default => 0
    t.integer "num_d22",                :default => 0
    t.integer "num_d23",                :default => 0
    t.integer "num_d24",                :default => 0
    t.integer "num_d25",                :default => 0
    t.integer "num_d26",                :default => 0
    t.integer "num_d27",                :default => 0
    t.integer "num_d28",                :default => 0
    t.integer "num_d29",                :default => 0
    t.integer "num_d30",                :default => 0
    t.integer "num_d90",                :default => 0
  end

  add_index "account_platform_retention_reports", ["date", "platform"], :name => "index_account_platform_retention_reports_on_date_and_platform", :unique => true
  add_index "account_platform_retention_reports", ["platform"], :name => "index_account_platform_retention_reports_on_platform"

  create_table "account_retention_reports", :force => true do |t|
    t.date    "date",                   :null => false
    t.integer "num_d0",  :default => 0
    t.integer "num_d1",  :default => 0
    t.integer "num_d2",  :default => 0
    t.integer "num_d3",  :default => 0
    t.integer "num_d4",  :default => 0
    t.integer "num_d5",  :default => 0
    t.integer "num_d6",  :default => 0
    t.integer "num_d7",  :default => 0
    t.integer "num_d8",  :default => 0
    t.integer "num_d9",  :default => 0
    t.integer "num_d10", :default => 0
    t.integer "num_d11", :default => 0
    t.integer "num_d12", :default => 0
    t.integer "num_d13", :default => 0
    t.integer "num_d14", :default => 0
    t.integer "num_d15", :default => 0
    t.integer "num_d16", :default => 0
    t.integer "num_d17", :default => 0
    t.integer "num_d18", :default => 0
    t.integer "num_d19", :default => 0
    t.integer "num_d20", :default => 0
    t.integer "num_d21", :default => 0
    t.integer "num_d22", :default => 0
    t.integer "num_d23", :default => 0
    t.integer "num_d24", :default => 0
    t.integer "num_d25", :default => 0
    t.integer "num_d26", :default => 0
    t.integer "num_d27", :default => 0
    t.integer "num_d28", :default => 0
    t.integer "num_d29", :default => 0
    t.integer "num_d30", :default => 0
    t.integer "num_d90", :default => 0
  end

  add_index "account_retention_reports", ["date"], :name => "index_account_retention_reports_on_date", :unique => true

  create_table "account_sdk_activity_reports", :force => true do |t|
    t.date    "date",                                  :null => false
    t.string  "sdk",      :limit => 20,                :null => false
    t.integer "total",                  :default => 0
    t.integer "num_m5",                 :default => 0
    t.integer "num_m10",                :default => 0
    t.integer "num_m15",                :default => 0
    t.integer "num_m20",                :default => 0
    t.integer "num_m25",                :default => 0
    t.integer "num_m30",                :default => 0
    t.integer "num_m35",                :default => 0
    t.integer "num_m40",                :default => 0
    t.integer "num_m45",                :default => 0
    t.integer "num_m50",                :default => 0
    t.integer "num_m55",                :default => 0
    t.integer "num_m60",                :default => 0
    t.integer "num_m120",               :default => 0
    t.integer "num_m180",               :default => 0
    t.integer "num_m300",               :default => 0
    t.integer "m300plus",               :default => 0
  end

  add_index "account_sdk_activity_reports", ["date", "sdk"], :name => "index_account_sdk_activity_reports_on_date_and_sdk", :unique => true
  add_index "account_sdk_activity_reports", ["sdk"], :name => "index_account_sdk_activity_reports_on_sdk"

  create_table "account_sdk_retention_reports", :force => true do |t|
    t.date    "date",                                 :null => false
    t.string  "sdk",     :limit => 20,                :null => false
    t.integer "num_d0",                :default => 0
    t.integer "num_d1",                :default => 0
    t.integer "num_d2",                :default => 0
    t.integer "num_d3",                :default => 0
    t.integer "num_d4",                :default => 0
    t.integer "num_d5",                :default => 0
    t.integer "num_d6",                :default => 0
    t.integer "num_d7",                :default => 0
    t.integer "num_d8",                :default => 0
    t.integer "num_d9",                :default => 0
    t.integer "num_d10",               :default => 0
    t.integer "num_d11",               :default => 0
    t.integer "num_d12",               :default => 0
    t.integer "num_d13",               :default => 0
    t.integer "num_d14",               :default => 0
    t.integer "num_d15",               :default => 0
    t.integer "num_d16",               :default => 0
    t.integer "num_d17",               :default => 0
    t.integer "num_d18",               :default => 0
    t.integer "num_d19",               :default => 0
    t.integer "num_d20",               :default => 0
    t.integer "num_d21",               :default => 0
    t.integer "num_d22",               :default => 0
    t.integer "num_d23",               :default => 0
    t.integer "num_d24",               :default => 0
    t.integer "num_d25",               :default => 0
    t.integer "num_d26",               :default => 0
    t.integer "num_d27",               :default => 0
    t.integer "num_d28",               :default => 0
    t.integer "num_d29",               :default => 0
    t.integer "num_d30",               :default => 0
    t.integer "num_d90",               :default => 0
  end

  add_index "account_sdk_retention_reports", ["date", "sdk"], :name => "index_account_sdk_retention_reports_on_date_and_sdk", :unique => true
  add_index "account_sdk_retention_reports", ["sdk"], :name => "index_account_sdk_retention_reports_on_sdk"

  create_table "account_zone_id_activity_reports", :force => true do |t|
    t.date    "date",                    :null => false
    t.integer "zone_id",  :default => 0
    t.integer "total",    :default => 0
    t.integer "num_m5",   :default => 0
    t.integer "num_m10",  :default => 0
    t.integer "num_m15",  :default => 0
    t.integer "num_m20",  :default => 0
    t.integer "num_m25",  :default => 0
    t.integer "num_m30",  :default => 0
    t.integer "num_m35",  :default => 0
    t.integer "num_m40",  :default => 0
    t.integer "num_m45",  :default => 0
    t.integer "num_m50",  :default => 0
    t.integer "num_m55",  :default => 0
    t.integer "num_m60",  :default => 0
    t.integer "num_m120", :default => 0
    t.integer "num_m180", :default => 0
    t.integer "num_m300", :default => 0
    t.integer "m300plus", :default => 0
  end

  add_index "account_zone_id_activity_reports", ["date", "zone_id"], :name => "index_account_zone_id_activity_reports_on_date_and_zone_id", :unique => true
  add_index "account_zone_id_activity_reports", ["zone_id"], :name => "index_account_zone_id_activity_reports_on_zone_id"

  create_table "account_zone_id_retention_reports", :force => true do |t|
    t.date    "date",                   :null => false
    t.integer "zone_id", :default => 0
    t.integer "num_d0",  :default => 0
    t.integer "num_d1",  :default => 0
    t.integer "num_d2",  :default => 0
    t.integer "num_d3",  :default => 0
    t.integer "num_d4",  :default => 0
    t.integer "num_d5",  :default => 0
    t.integer "num_d6",  :default => 0
    t.integer "num_d7",  :default => 0
    t.integer "num_d8",  :default => 0
    t.integer "num_d9",  :default => 0
    t.integer "num_d10", :default => 0
    t.integer "num_d11", :default => 0
    t.integer "num_d12", :default => 0
    t.integer "num_d13", :default => 0
    t.integer "num_d14", :default => 0
    t.integer "num_d15", :default => 0
    t.integer "num_d16", :default => 0
    t.integer "num_d17", :default => 0
    t.integer "num_d18", :default => 0
    t.integer "num_d19", :default => 0
    t.integer "num_d20", :default => 0
    t.integer "num_d21", :default => 0
    t.integer "num_d22", :default => 0
    t.integer "num_d23", :default => 0
    t.integer "num_d24", :default => 0
    t.integer "num_d25", :default => 0
    t.integer "num_d26", :default => 0
    t.integer "num_d27", :default => 0
    t.integer "num_d28", :default => 0
    t.integer "num_d29", :default => 0
    t.integer "num_d30", :default => 0
    t.integer "num_d90", :default => 0
  end

  add_index "account_zone_id_retention_reports", ["date", "zone_id"], :name => "index_account_zone_id_retention_reports_on_date_and_zone_id", :unique => true
  add_index "account_zone_id_retention_reports", ["zone_id"], :name => "index_account_zone_id_retention_reports_on_zone_id"

  create_table "accounts", :force => true do |t|
    t.string   "name"
    t.string   "surname"
    t.string   "email"
    t.string   "crypted_password"
    t.string   "role"
    t.datetime "login_at",         :null => false
    t.datetime "created_at",       :null => false
    t.datetime "updated_at",       :null => false
  end

  add_index "accounts", ["email"], :name => "index_accounts_on_email", :unique => true
  add_index "accounts", ["name"], :name => "index_accounts_on_name"

  create_table "active_factions", :force => true do |t|
    t.integer "zone_id",                       :default => 1
    t.date    "date"
    t.integer "count_by_player",  :limit => 8, :default => 0
    t.integer "count_by_account", :limit => 8, :default => 0
    t.string  "faction"
  end

  add_index "active_factions", ["zone_id"], :name => "index_active_factions_on_zone_id"

  create_table "add_equip_report", :force => true do |t|
    t.integer "zone_id",              :default => 1
    t.date    "date",                                :null => false
    t.string  "reason"
    t.integer "grade",   :limit => 8, :default => 0
    t.integer "star",    :limit => 8, :default => 0
    t.integer "suits",   :limit => 8, :default => 0
    t.integer "scarces", :limit => 8, :default => 0
    t.integer "normals", :limit => 8, :default => 0
  end

  add_index "add_equip_report", ["zone_id", "date", "grade", "star"], :name => "index_add_equip_report_on_zone_id_and_date_and_grade_and_star"

  create_table "add_item", :force => true do |t|
    t.integer "zone_id",                :default => 0
    t.string  "sdk",      :limit => 50,                :null => false
    t.string  "platform", :limit => 10,                :null => false
    t.date    "date"
    t.string  "reason"
    t.string  "pid"
    t.integer "count",    :limit => 8,  :default => 0
    t.integer "level",                  :default => 0
  end

  add_index "add_item", ["date"], :name => "index_add_item_on_date"
  add_index "add_item", ["platform"], :name => "index_add_item_on_platform"
  add_index "add_item", ["sdk"], :name => "index_add_item_on_sdk"
  add_index "add_item", ["zone_id"], :name => "index_add_item_on_zone_id"

  create_table "all_city_event_level", :force => true do |t|
    t.integer "zone_id",                :default => 0
    t.string  "sdk",      :limit => 50,                :null => false
    t.string  "platform", :limit => 10,                :null => false
    t.date    "date"
    t.integer "level",                  :default => 1
    t.integer "num",                    :default => 1
  end

  add_index "all_city_event_level", ["date", "zone_id", "level"], :name => "index_all_city_event_level_on_date_and_zone_id_and_level"

  create_table "all_factions", :force => true do |t|
    t.integer "zone_id",                :default => 0
    t.string  "sdk",      :limit => 50,                :null => false
    t.string  "platform", :limit => 10,                :null => false
    t.string  "pid",                                   :null => false
    t.string  "faction",                               :null => false
  end

  add_index "all_factions", ["zone_id", "pid", "faction"], :name => "index_all_factions_on_zone_id_and_pid_and_faction"

  create_table "all_factions_report", :force => true do |t|
    t.integer "zone_id",                :default => 0
    t.string  "sdk",      :limit => 50,                :null => false
    t.string  "platform", :limit => 10,                :null => false
    t.date    "date"
    t.integer "players",  :limit => 8,  :default => 0
    t.integer "accounts", :limit => 8,  :default => 0
    t.string  "faction"
  end

  add_index "all_factions_report", ["zone_id", "faction"], :name => "index_all_factions_report_on_zone_id_and_faction"

  create_table "all_player_level", :force => true do |t|
    t.integer "zone_id",                :default => 0
    t.string  "sdk",      :limit => 50,                :null => false
    t.string  "platform", :limit => 10,                :null => false
    t.date    "date"
    t.integer "level",                  :default => 1
    t.integer "num",                    :default => 1
  end

  add_index "all_player_level", ["date", "zone_id", "level"], :name => "index_all_player_level_on_date_and_zone_id_and_level"

  create_table "all_player_level_and_city_event_level", :force => true do |t|
    t.integer "zone_id",                        :default => 0
    t.string  "sdk",              :limit => 50,                :null => false
    t.string  "platform",         :limit => 10,                :null => false
    t.string  "pid"
    t.integer "level",                          :default => 1
    t.integer "vip_level",                      :default => 0
    t.integer "city_event_level",               :default => 1
  end

  add_index "all_player_level_and_city_event_level", ["pid"], :name => "index_all_player_level_and_city_event_level_on_pid"

  create_table "alter_coins", :force => true do |t|
    t.integer "zone_id",                :default => 0
    t.string  "sdk",      :limit => 50,                :null => false
    t.string  "platform", :limit => 10,                :null => false
    t.date    "date"
    t.string  "reason"
    t.string  "pid"
    t.integer "coins",    :limit => 8,  :default => 0
    t.integer "level",                  :default => 0
  end

  add_index "alter_coins", ["date"], :name => "index_alter_coins_on_date"
  add_index "alter_coins", ["platform"], :name => "index_alter_coins_on_platform"
  add_index "alter_coins", ["sdk"], :name => "index_alter_coins_on_sdk"
  add_index "alter_coins", ["zone_id"], :name => "index_alter_coins_on_zone_id"

  create_table "alter_coins_sys", :force => true do |t|
    t.integer "zone_id",                :default => 0
    t.string  "sdk",      :limit => 50,                :null => false
    t.string  "platform", :limit => 10,                :null => false
    t.date    "date"
    t.string  "reason"
    t.integer "coins",    :limit => 8,  :default => 0
    t.integer "players",  :limit => 8,  :default => 0
  end

  add_index "alter_coins_sys", ["date"], :name => "index_alter_coins_sys_on_date"
  add_index "alter_coins_sys", ["platform"], :name => "index_alter_coins_sys_on_platform"
  add_index "alter_coins_sys", ["sdk"], :name => "index_alter_coins_sys_on_sdk"
  add_index "alter_coins_sys", ["zone_id"], :name => "index_alter_coins_sys_on_zone_id"

  create_table "alter_credits", :force => true do |t|
    t.integer "zone_id",                :default => 0
    t.string  "sdk",      :limit => 50,                :null => false
    t.string  "platform", :limit => 10,                :null => false
    t.date    "date"
    t.string  "reason"
    t.string  "pid"
    t.integer "credits",  :limit => 8,  :default => 0
    t.integer "level",                  :default => 0
  end

  add_index "alter_credits", ["platform"], :name => "index_alter_credits_on_platform"
  add_index "alter_credits", ["sdk"], :name => "index_alter_credits_on_sdk"
  add_index "alter_credits", ["zone_id"], :name => "index_alter_credits_on_zone_id"

  create_table "alter_credits_sum", :force => true do |t|
    t.integer "zone_id",                :default => 0
    t.string  "sdk",      :limit => 50,                :null => false
    t.string  "platform", :limit => 10,                :null => false
    t.date    "date"
    t.integer "credits",  :limit => 8,  :default => 0
    t.integer "players",  :limit => 8,  :default => 0
  end

  add_index "alter_credits_sum", ["platform"], :name => "index_alter_credits_sum_on_platform"
  add_index "alter_credits_sum", ["sdk"], :name => "index_alter_credits_sum_on_sdk"
  add_index "alter_credits_sum", ["zone_id"], :name => "index_alter_credits_sum_on_zone_id"

  create_table "alter_credits_sys", :force => true do |t|
    t.integer "zone_id",                :default => 0
    t.string  "sdk",      :limit => 50,                :null => false
    t.string  "platform", :limit => 10,                :null => false
    t.date    "date"
    t.string  "reason"
    t.integer "credits",  :limit => 8,  :default => 0
    t.integer "players",  :limit => 8,  :default => 0
  end

  add_index "alter_credits_sys", ["platform"], :name => "index_alter_credits_sys_on_platform"
  add_index "alter_credits_sys", ["sdk"], :name => "index_alter_credits_sys_on_sdk"
  add_index "alter_credits_sys", ["zone_id"], :name => "index_alter_credits_sys_on_zone_id"

  create_table "alter_money", :force => true do |t|
    t.integer "zone_id",                :default => 0
    t.string  "sdk",      :limit => 50,                :null => false
    t.string  "platform", :limit => 10,                :null => false
    t.date    "date"
    t.string  "reason"
    t.string  "pid"
    t.integer "money",    :limit => 8,  :default => 0
    t.integer "level",                  :default => 0
  end

  add_index "alter_money", ["date"], :name => "index_alter_money_on_date"
  add_index "alter_money", ["platform"], :name => "index_alter_money_on_platform"
  add_index "alter_money", ["sdk"], :name => "index_alter_money_on_sdk"
  add_index "alter_money", ["zone_id"], :name => "index_alter_money_on_zone_id"

  create_table "alter_money_sys", :force => true do |t|
    t.integer "zone_id",                :default => 0
    t.string  "sdk",      :limit => 50,                :null => false
    t.string  "platform", :limit => 10,                :null => false
    t.date    "date"
    t.string  "reason"
    t.integer "money",    :limit => 8,  :default => 0
    t.integer "players",  :limit => 8,  :default => 0
  end

  add_index "alter_money_sys", ["date"], :name => "index_alter_money_sys_on_date"
  add_index "alter_money_sys", ["platform"], :name => "index_alter_money_sys_on_platform"
  add_index "alter_money_sys", ["sdk"], :name => "index_alter_money_sys_on_sdk"
  add_index "alter_money_sys", ["zone_id"], :name => "index_alter_money_sys_on_zone_id"

  create_table "alter_voucher_sys", :force => true do |t|
    t.integer "zone_id",                :default => 0
    t.string  "sdk",      :limit => 50,                :null => false
    t.string  "platform", :limit => 10,                :null => false
    t.date    "date"
    t.string  "reason"
    t.integer "voucher",  :limit => 8,  :default => 0
    t.integer "players",  :limit => 8,  :default => 0
    t.integer "accounts", :limit => 8,  :default => 0
  end

  add_index "alter_voucher_sys", ["date"], :name => "index_alter_voucher_sys_on_date"
  add_index "alter_voucher_sys", ["platform"], :name => "index_alter_voucher_sys_on_platform"
  add_index "alter_voucher_sys", ["sdk"], :name => "index_alter_voucher_sys_on_sdk"
  add_index "alter_voucher_sys", ["zone_id"], :name => "index_alter_voucher_sys_on_zone_id"

  create_table "booth_trade", :force => true do |t|
    t.date    "date",                      :null => false
    t.integer "zone_id",   :default => 1
    t.string  "seller_id",                 :null => false
    t.string  "buyer_id",                  :null => false
    t.string  "tid",                       :null => false
    t.string  "name",                      :null => false
    t.integer "count",     :default => 0,  :null => false
    t.integer "price",     :default => 0,  :null => false
    t.integer "level",     :default => 0
    t.integer "grade",     :default => 0
    t.string  "star",      :default => ""
    t.string  "time"
  end

  add_index "booth_trade", ["date", "zone_id"], :name => "index_booth_trade_on_date_and_zone_id"

  create_table "born_quest", :force => true do |t|
    t.integer "zone_id",                :default => 0
    t.string  "sdk",      :limit => 50,                :null => false
    t.string  "platform", :limit => 10,                :null => false
    t.date    "date",                                  :null => false
    t.string  "tid",                                   :null => false
    t.string  "pid",                                   :null => false
  end

  add_index "born_quest", ["date", "zone_id"], :name => "index_born_quest_on_date_and_zone_id"

  create_table "born_quest_report", :force => true do |t|
    t.integer "zone_id",                :default => 0
    t.string  "sdk",      :limit => 50,                :null => false
    t.string  "platform", :limit => 10,                :null => false
    t.date    "date",                                  :null => false
    t.string  "tid",                                   :null => false
    t.integer "num",                    :default => 0
  end

  add_index "born_quest_report", ["date", "zone_id"], :name => "index_born_quest_report_on_date_and_zone_id"

  create_table "boss_practice_report", :force => true do |t|
    t.integer "zone_id",                            :default => 0
    t.string  "sdk",                  :limit => 50,                :null => false
    t.string  "platform",             :limit => 10,                :null => false
    t.date    "date",                                              :null => false
    t.integer "count1_boss",                        :default => 0
    t.integer "count2_boss",                        :default => 0
    t.integer "count3_boss",                        :default => 0
    t.integer "count4_boss",                        :default => 0
    t.integer "count5_boss",                        :default => 0
    t.integer "count6_boss",                        :default => 0
    t.integer "count7_boss",                        :default => 0
    t.integer "count8_boss",                        :default => 0
    t.integer "count_more_boss",                    :default => 0
    t.integer "count1p_boss",                       :default => 0
    t.integer "count2p_boss",                       :default => 0
    t.integer "count3p_boss",                       :default => 0
    t.integer "count4p_boss",                       :default => 0
    t.integer "count5p_boss",                       :default => 0
    t.integer "count6p_boss",                       :default => 0
    t.integer "count7p_boss",                       :default => 0
    t.integer "count8p_boss",                       :default => 0
    t.integer "countp_more_boss",                   :default => 0
    t.integer "count1_practice",                    :default => 0
    t.integer "count2_practice",                    :default => 0
    t.integer "count3_practice",                    :default => 0
    t.integer "count4_practice",                    :default => 0
    t.integer "count5_practice",                    :default => 0
    t.integer "count6_practice",                    :default => 0
    t.integer "count7_practice",                    :default => 0
    t.integer "count8_practice",                    :default => 0
    t.integer "count_more_practice",                :default => 0
    t.integer "count1p_practice",                   :default => 0
    t.integer "count2p_practice",                   :default => 0
    t.integer "count3p_practice",                   :default => 0
    t.integer "count4p_practice",                   :default => 0
    t.integer "count5p_practice",                   :default => 0
    t.integer "count6p_practice",                   :default => 0
    t.integer "count7p_practice",                   :default => 0
    t.integer "count8p_practice",                   :default => 0
    t.integer "count_morep_practice",               :default => 0
  end

  add_index "boss_practice_report", ["date", "zone_id"], :name => "index_boss_practice_report_on_date_and_zone_id"

  create_table "branch_quest_finish", :force => true do |t|
    t.integer "zone_id",                :default => 0
    t.string  "sdk",      :limit => 50,                :null => false
    t.string  "platform", :limit => 10,                :null => false
    t.date    "date"
    t.string  "tid"
    t.string  "category"
    t.integer "count",    :limit => 8,  :default => 0
  end

  add_index "branch_quest_finish", ["zone_id"], :name => "index_branch_quest_finish_on_zone_id"

  create_table "branch_quest_finish_report", :force => true do |t|
    t.integer "zone_id",                :default => 0
    t.string  "sdk",      :limit => 50,                :null => false
    t.string  "platform", :limit => 10,                :null => false
    t.date    "date"
    t.string  "tid"
    t.string  "category"
    t.integer "count",    :limit => 8,  :default => 0
  end

  add_index "branch_quest_finish_report", ["zone_id"], :name => "index_branch_quest_finish_report_on_zone_id"

  create_table "campaign_report", :force => true do |t|
    t.date    "date",                   :null => false
    t.integer "zone_id", :default => 1
    t.string  "cid",                    :null => false
    t.integer "num",     :default => 0
    t.integer "players", :default => 0
    t.string  "cat",                    :null => false
  end

  add_index "campaign_report", ["date", "zone_id", "cid"], :name => "index_campaign_report_on_date_and_zone_id_and_cid"

  create_table "chief_level_report", :force => true do |t|
    t.date    "date",                   :null => false
    t.integer "level",   :default => 1
    t.integer "zone_id", :default => 1
    t.integer "num",     :default => 0
  end

  add_index "chief_level_report", ["date", "level", "zone_id"], :name => "index_chief_level_report_on_date_and_level_and_zone_id"

  create_table "city_campaign", :force => true do |t|
    t.integer "zone_id",                :default => 0
    t.string  "sdk",      :limit => 50,                :null => false
    t.string  "platform", :limit => 10,                :null => false
    t.date    "date",                                  :null => false
    t.integer "count",                  :default => 0
    t.integer "players",                :default => 0
    t.string  "kind",                                  :null => false
    t.string  "city_id",                               :null => false
  end

  add_index "city_campaign", ["date", "zone_id"], :name => "index_city_campaign_on_date_and_zone_id"

  create_table "city_campaign_report", :force => true do |t|
    t.integer "zone_id",                :default => 0
    t.string  "sdk",      :limit => 50,                :null => false
    t.string  "platform", :limit => 10,                :null => false
    t.date    "date",                                  :null => false
    t.integer "count",                  :default => 0
    t.integer "players",                :default => 0
    t.string  "kind",                                  :null => false
    t.string  "city_id",                               :null => false
  end

  add_index "city_campaign_report", ["date", "zone_id"], :name => "index_city_campaign_report_on_date_and_zone_id"

  create_table "city_event_level_report", :force => true do |t|
    t.date    "date",                   :null => false
    t.integer "level",   :default => 1
    t.integer "zone_id", :default => 1
    t.integer "num",     :default => 0
  end

  add_index "city_event_level_report", ["date", "level", "zone_id"], :name => "index_city_event_level_report_on_date_and_level_and_zone_id"

  create_table "consume_levels", :force => true do |t|
    t.integer "zone_id",                 :default => 0
    t.string  "sdk",       :limit => 50,                :null => false
    t.string  "platform",  :limit => 10,                :null => false
    t.date    "date"
    t.string  "sys_name"
    t.string  "cost_type"
    t.integer "players",                 :default => 0
    t.integer "consume",                 :default => 0
    t.integer "level_rgn"
  end

  add_index "consume_levels", ["date", "zone_id"], :name => "index_consume_levels_on_date_and_zone_id"

  create_table "create_branch_quest", :force => true do |t|
    t.integer "zone_id",                :default => 0
    t.string  "sdk",      :limit => 50,                :null => false
    t.string  "platform", :limit => 10,                :null => false
    t.date    "date"
    t.string  "tid"
    t.string  "category"
    t.integer "count",    :limit => 8,  :default => 0
  end

  add_index "create_branch_quest", ["zone_id"], :name => "index_create_branch_quest_on_zone_id"

  create_table "create_branch_quest_report", :force => true do |t|
    t.integer "zone_id",                :default => 0
    t.string  "sdk",      :limit => 50,                :null => false
    t.string  "platform", :limit => 10,                :null => false
    t.date    "date"
    t.string  "tid"
    t.string  "category"
    t.integer "count",    :limit => 8,  :default => 0
  end

  add_index "create_branch_quest_report", ["zone_id"], :name => "index_create_branch_quest_report_on_zone_id"

  create_table "dates", :force => true do |t|
    t.datetime "date"
  end

  add_index "dates", ["date"], :name => "index_dates_on_date", :unique => true

  create_table "device_activity_reports", :force => true do |t|
    t.date    "date",                    :null => false
    t.integer "total",    :default => 0
    t.integer "num_m5",   :default => 0
    t.integer "num_m10",  :default => 0
    t.integer "num_m15",  :default => 0
    t.integer "num_m20",  :default => 0
    t.integer "num_m25",  :default => 0
    t.integer "num_m30",  :default => 0
    t.integer "num_m35",  :default => 0
    t.integer "num_m40",  :default => 0
    t.integer "num_m45",  :default => 0
    t.integer "num_m50",  :default => 0
    t.integer "num_m55",  :default => 0
    t.integer "num_m60",  :default => 0
    t.integer "num_m120", :default => 0
    t.integer "num_m180", :default => 0
    t.integer "num_m300", :default => 0
    t.integer "m300plus", :default => 0
  end

  add_index "device_activity_reports", ["date"], :name => "index_device_activity_reports_on_date", :unique => true

  create_table "device_market_activity_reports", :force => true do |t|
    t.date    "date",                                  :null => false
    t.string  "market",   :limit => 20,                :null => false
    t.integer "total",                  :default => 0
    t.integer "num_m5",                 :default => 0
    t.integer "num_m10",                :default => 0
    t.integer "num_m15",                :default => 0
    t.integer "num_m20",                :default => 0
    t.integer "num_m25",                :default => 0
    t.integer "num_m30",                :default => 0
    t.integer "num_m35",                :default => 0
    t.integer "num_m40",                :default => 0
    t.integer "num_m45",                :default => 0
    t.integer "num_m50",                :default => 0
    t.integer "num_m55",                :default => 0
    t.integer "num_m60",                :default => 0
    t.integer "num_m120",               :default => 0
    t.integer "num_m180",               :default => 0
    t.integer "num_m300",               :default => 0
    t.integer "m300plus",               :default => 0
  end

  add_index "device_market_activity_reports", ["date", "market"], :name => "index_device_market_activity_reports_on_date_and_market", :unique => true
  add_index "device_market_activity_reports", ["market"], :name => "index_device_market_activity_reports_on_market"

  create_table "device_market_retention_reports", :force => true do |t|
    t.date    "date",                                 :null => false
    t.string  "market",  :limit => 20,                :null => false
    t.integer "num_d0",                :default => 0
    t.integer "num_d1",                :default => 0
    t.integer "num_d2",                :default => 0
    t.integer "num_d3",                :default => 0
    t.integer "num_d4",                :default => 0
    t.integer "num_d5",                :default => 0
    t.integer "num_d6",                :default => 0
    t.integer "num_d7",                :default => 0
    t.integer "num_d8",                :default => 0
    t.integer "num_d9",                :default => 0
    t.integer "num_d10",               :default => 0
    t.integer "num_d11",               :default => 0
    t.integer "num_d12",               :default => 0
    t.integer "num_d13",               :default => 0
    t.integer "num_d14",               :default => 0
    t.integer "num_d15",               :default => 0
    t.integer "num_d16",               :default => 0
    t.integer "num_d17",               :default => 0
    t.integer "num_d18",               :default => 0
    t.integer "num_d19",               :default => 0
    t.integer "num_d20",               :default => 0
    t.integer "num_d21",               :default => 0
    t.integer "num_d22",               :default => 0
    t.integer "num_d23",               :default => 0
    t.integer "num_d24",               :default => 0
    t.integer "num_d25",               :default => 0
    t.integer "num_d26",               :default => 0
    t.integer "num_d27",               :default => 0
    t.integer "num_d28",               :default => 0
    t.integer "num_d29",               :default => 0
    t.integer "num_d30",               :default => 0
    t.integer "num_d90",               :default => 0
  end

  add_index "device_market_retention_reports", ["date", "market"], :name => "index_device_market_retention_reports_on_date_and_market", :unique => true
  add_index "device_market_retention_reports", ["market"], :name => "index_device_market_retention_reports_on_market"

  create_table "device_platform_activity_reports", :force => true do |t|
    t.date    "date",                                  :null => false
    t.string  "platform", :limit => 20,                :null => false
    t.integer "total",                  :default => 0
    t.integer "num_m5",                 :default => 0
    t.integer "num_m10",                :default => 0
    t.integer "num_m15",                :default => 0
    t.integer "num_m20",                :default => 0
    t.integer "num_m25",                :default => 0
    t.integer "num_m30",                :default => 0
    t.integer "num_m35",                :default => 0
    t.integer "num_m40",                :default => 0
    t.integer "num_m45",                :default => 0
    t.integer "num_m50",                :default => 0
    t.integer "num_m55",                :default => 0
    t.integer "num_m60",                :default => 0
    t.integer "num_m120",               :default => 0
    t.integer "num_m180",               :default => 0
    t.integer "num_m300",               :default => 0
    t.integer "m300plus",               :default => 0
  end

  add_index "device_platform_activity_reports", ["date", "platform"], :name => "index_device_platform_activity_reports_on_date_and_platform", :unique => true
  add_index "device_platform_activity_reports", ["platform"], :name => "index_device_platform_activity_reports_on_platform"

  create_table "device_platform_retention_reports", :force => true do |t|
    t.date    "date",                                  :null => false
    t.string  "platform", :limit => 20,                :null => false
    t.integer "num_d0",                 :default => 0
    t.integer "num_d1",                 :default => 0
    t.integer "num_d2",                 :default => 0
    t.integer "num_d3",                 :default => 0
    t.integer "num_d4",                 :default => 0
    t.integer "num_d5",                 :default => 0
    t.integer "num_d6",                 :default => 0
    t.integer "num_d7",                 :default => 0
    t.integer "num_d8",                 :default => 0
    t.integer "num_d9",                 :default => 0
    t.integer "num_d10",                :default => 0
    t.integer "num_d11",                :default => 0
    t.integer "num_d12",                :default => 0
    t.integer "num_d13",                :default => 0
    t.integer "num_d14",                :default => 0
    t.integer "num_d15",                :default => 0
    t.integer "num_d16",                :default => 0
    t.integer "num_d17",                :default => 0
    t.integer "num_d18",                :default => 0
    t.integer "num_d19",                :default => 0
    t.integer "num_d20",                :default => 0
    t.integer "num_d21",                :default => 0
    t.integer "num_d22",                :default => 0
    t.integer "num_d23",                :default => 0
    t.integer "num_d24",                :default => 0
    t.integer "num_d25",                :default => 0
    t.integer "num_d26",                :default => 0
    t.integer "num_d27",                :default => 0
    t.integer "num_d28",                :default => 0
    t.integer "num_d29",                :default => 0
    t.integer "num_d30",                :default => 0
    t.integer "num_d90",                :default => 0
  end

  add_index "device_platform_retention_reports", ["date", "platform"], :name => "index_device_platform_retention_reports_on_date_and_platform", :unique => true
  add_index "device_platform_retention_reports", ["platform"], :name => "index_device_platform_retention_reports_on_platform"

  create_table "device_retention_reports", :force => true do |t|
    t.date    "date",                   :null => false
    t.integer "num_d0",  :default => 0
    t.integer "num_d1",  :default => 0
    t.integer "num_d2",  :default => 0
    t.integer "num_d3",  :default => 0
    t.integer "num_d4",  :default => 0
    t.integer "num_d5",  :default => 0
    t.integer "num_d6",  :default => 0
    t.integer "num_d7",  :default => 0
    t.integer "num_d8",  :default => 0
    t.integer "num_d9",  :default => 0
    t.integer "num_d10", :default => 0
    t.integer "num_d11", :default => 0
    t.integer "num_d12", :default => 0
    t.integer "num_d13", :default => 0
    t.integer "num_d14", :default => 0
    t.integer "num_d15", :default => 0
    t.integer "num_d16", :default => 0
    t.integer "num_d17", :default => 0
    t.integer "num_d18", :default => 0
    t.integer "num_d19", :default => 0
    t.integer "num_d20", :default => 0
    t.integer "num_d21", :default => 0
    t.integer "num_d22", :default => 0
    t.integer "num_d23", :default => 0
    t.integer "num_d24", :default => 0
    t.integer "num_d25", :default => 0
    t.integer "num_d26", :default => 0
    t.integer "num_d27", :default => 0
    t.integer "num_d28", :default => 0
    t.integer "num_d29", :default => 0
    t.integer "num_d30", :default => 0
    t.integer "num_d90", :default => 0
  end

  add_index "device_retention_reports", ["date"], :name => "index_device_retention_reports_on_date", :unique => true

  create_table "device_sdk_activity_reports", :force => true do |t|
    t.date    "date",                                  :null => false
    t.string  "sdk",      :limit => 20,                :null => false
    t.integer "total",                  :default => 0
    t.integer "num_m5",                 :default => 0
    t.integer "num_m10",                :default => 0
    t.integer "num_m15",                :default => 0
    t.integer "num_m20",                :default => 0
    t.integer "num_m25",                :default => 0
    t.integer "num_m30",                :default => 0
    t.integer "num_m35",                :default => 0
    t.integer "num_m40",                :default => 0
    t.integer "num_m45",                :default => 0
    t.integer "num_m50",                :default => 0
    t.integer "num_m55",                :default => 0
    t.integer "num_m60",                :default => 0
    t.integer "num_m120",               :default => 0
    t.integer "num_m180",               :default => 0
    t.integer "num_m300",               :default => 0
    t.integer "m300plus",               :default => 0
  end

  add_index "device_sdk_activity_reports", ["date", "sdk"], :name => "index_device_sdk_activity_reports_on_date_and_sdk", :unique => true
  add_index "device_sdk_activity_reports", ["sdk"], :name => "index_device_sdk_activity_reports_on_sdk"

  create_table "device_sdk_retention_reports", :force => true do |t|
    t.date    "date",                                 :null => false
    t.string  "sdk",     :limit => 20,                :null => false
    t.integer "num_d0",                :default => 0
    t.integer "num_d1",                :default => 0
    t.integer "num_d2",                :default => 0
    t.integer "num_d3",                :default => 0
    t.integer "num_d4",                :default => 0
    t.integer "num_d5",                :default => 0
    t.integer "num_d6",                :default => 0
    t.integer "num_d7",                :default => 0
    t.integer "num_d8",                :default => 0
    t.integer "num_d9",                :default => 0
    t.integer "num_d10",               :default => 0
    t.integer "num_d11",               :default => 0
    t.integer "num_d12",               :default => 0
    t.integer "num_d13",               :default => 0
    t.integer "num_d14",               :default => 0
    t.integer "num_d15",               :default => 0
    t.integer "num_d16",               :default => 0
    t.integer "num_d17",               :default => 0
    t.integer "num_d18",               :default => 0
    t.integer "num_d19",               :default => 0
    t.integer "num_d20",               :default => 0
    t.integer "num_d21",               :default => 0
    t.integer "num_d22",               :default => 0
    t.integer "num_d23",               :default => 0
    t.integer "num_d24",               :default => 0
    t.integer "num_d25",               :default => 0
    t.integer "num_d26",               :default => 0
    t.integer "num_d27",               :default => 0
    t.integer "num_d28",               :default => 0
    t.integer "num_d29",               :default => 0
    t.integer "num_d30",               :default => 0
    t.integer "num_d90",               :default => 0
  end

  add_index "device_sdk_retention_reports", ["date", "sdk"], :name => "index_device_sdk_retention_reports_on_date_and_sdk", :unique => true
  add_index "device_sdk_retention_reports", ["sdk"], :name => "index_device_sdk_retention_reports_on_sdk"

  create_table "device_zone_id_activity_reports", :force => true do |t|
    t.date    "date",                    :null => false
    t.integer "zone_id",  :default => 0
    t.integer "total",    :default => 0
    t.integer "num_m5",   :default => 0
    t.integer "num_m10",  :default => 0
    t.integer "num_m15",  :default => 0
    t.integer "num_m20",  :default => 0
    t.integer "num_m25",  :default => 0
    t.integer "num_m30",  :default => 0
    t.integer "num_m35",  :default => 0
    t.integer "num_m40",  :default => 0
    t.integer "num_m45",  :default => 0
    t.integer "num_m50",  :default => 0
    t.integer "num_m55",  :default => 0
    t.integer "num_m60",  :default => 0
    t.integer "num_m120", :default => 0
    t.integer "num_m180", :default => 0
    t.integer "num_m300", :default => 0
    t.integer "m300plus", :default => 0
  end

  add_index "device_zone_id_activity_reports", ["date", "zone_id"], :name => "index_device_zone_id_activity_reports_on_date_and_zone_id", :unique => true
  add_index "device_zone_id_activity_reports", ["zone_id"], :name => "index_device_zone_id_activity_reports_on_zone_id"

  create_table "device_zone_id_retention_reports", :force => true do |t|
    t.date    "date",                   :null => false
    t.integer "zone_id", :default => 0
    t.integer "num_d0",  :default => 0
    t.integer "num_d1",  :default => 0
    t.integer "num_d2",  :default => 0
    t.integer "num_d3",  :default => 0
    t.integer "num_d4",  :default => 0
    t.integer "num_d5",  :default => 0
    t.integer "num_d6",  :default => 0
    t.integer "num_d7",  :default => 0
    t.integer "num_d8",  :default => 0
    t.integer "num_d9",  :default => 0
    t.integer "num_d10", :default => 0
    t.integer "num_d11", :default => 0
    t.integer "num_d12", :default => 0
    t.integer "num_d13", :default => 0
    t.integer "num_d14", :default => 0
    t.integer "num_d15", :default => 0
    t.integer "num_d16", :default => 0
    t.integer "num_d17", :default => 0
    t.integer "num_d18", :default => 0
    t.integer "num_d19", :default => 0
    t.integer "num_d20", :default => 0
    t.integer "num_d21", :default => 0
    t.integer "num_d22", :default => 0
    t.integer "num_d23", :default => 0
    t.integer "num_d24", :default => 0
    t.integer "num_d25", :default => 0
    t.integer "num_d26", :default => 0
    t.integer "num_d27", :default => 0
    t.integer "num_d28", :default => 0
    t.integer "num_d29", :default => 0
    t.integer "num_d30", :default => 0
    t.integer "num_d90", :default => 0
  end

  add_index "device_zone_id_retention_reports", ["date", "zone_id"], :name => "index_device_zone_id_retention_reports_on_date_and_zone_id", :unique => true
  add_index "device_zone_id_retention_reports", ["zone_id"], :name => "index_device_zone_id_retention_reports_on_zone_id"

  create_table "finish_campaign", :force => true do |t|
    t.integer "zone_id",                :default => 0
    t.string  "sdk",      :limit => 50,                :null => false
    t.string  "platform", :limit => 10,                :null => false
    t.date    "date",                                  :null => false
    t.string  "cid",                                   :null => false
  end

  add_index "finish_campaign", ["date", "zone_id"], :name => "index_finish_campaign_on_date_and_zone_id"

  create_table "finish_campaign_sum", :force => true do |t|
    t.integer "zone_id",                :default => 0
    t.string  "sdk",      :limit => 50,                :null => false
    t.string  "platform", :limit => 10,                :null => false
    t.date    "date",                                  :null => false
    t.integer "players",                :default => 0
    t.string  "cid",                                   :null => false
  end

  add_index "finish_campaign_sum", ["date", "zone_id"], :name => "index_finish_campaign_sum_on_date_and_zone_id"

  create_table "gain_coins_sys", :force => true do |t|
    t.integer "zone_id",                :default => 0
    t.string  "sdk",      :limit => 50,                :null => false
    t.string  "platform", :limit => 10,                :null => false
    t.date    "date"
    t.string  "reason"
    t.integer "coins",    :limit => 8,  :default => 0
    t.integer "players",  :limit => 8,  :default => 0
  end

  add_index "gain_coins_sys", ["date"], :name => "index_gain_coins_sys_on_date"
  add_index "gain_coins_sys", ["platform"], :name => "index_gain_coins_sys_on_platform"
  add_index "gain_coins_sys", ["sdk"], :name => "index_gain_coins_sys_on_sdk"
  add_index "gain_coins_sys", ["zone_id"], :name => "index_gain_coins_sys_on_zone_id"

  create_table "gain_credits_sys", :force => true do |t|
    t.integer "zone_id",                :default => 0
    t.string  "sdk",      :limit => 50,                :null => false
    t.string  "platform", :limit => 10,                :null => false
    t.date    "date"
    t.string  "reason"
    t.integer "credits",  :limit => 8,  :default => 0
    t.integer "players",  :limit => 8,  :default => 0
  end

  add_index "gain_credits_sys", ["platform"], :name => "index_gain_credits_sys_on_platform"
  add_index "gain_credits_sys", ["sdk"], :name => "index_gain_credits_sys_on_sdk"
  add_index "gain_credits_sys", ["zone_id"], :name => "index_gain_credits_sys_on_zone_id"

  create_table "gain_money_sys", :force => true do |t|
    t.integer "zone_id",                :default => 0
    t.string  "sdk",      :limit => 50,                :null => false
    t.string  "platform", :limit => 10,                :null => false
    t.date    "date"
    t.string  "reason"
    t.integer "money",    :limit => 8,  :default => 0
    t.integer "players",  :limit => 8,  :default => 0
  end

  add_index "gain_money_sys", ["date"], :name => "index_gain_money_sys_on_date"
  add_index "gain_money_sys", ["platform"], :name => "index_gain_money_sys_on_platform"
  add_index "gain_money_sys", ["sdk"], :name => "index_gain_money_sys_on_sdk"
  add_index "gain_money_sys", ["zone_id"], :name => "index_gain_money_sys_on_zone_id"

  create_table "gain_voucher_sys", :force => true do |t|
    t.integer "zone_id",                :default => 0
    t.string  "sdk",      :limit => 50,                :null => false
    t.string  "platform", :limit => 10,                :null => false
    t.date    "date"
    t.string  "reason"
    t.integer "voucher",  :limit => 8,  :default => 0
    t.integer "players",  :limit => 8,  :default => 0
    t.integer "accounts", :limit => 8,  :default => 0
  end

  add_index "gain_voucher_sys", ["date"], :name => "index_gain_voucher_sys_on_date"
  add_index "gain_voucher_sys", ["platform"], :name => "index_gain_voucher_sys_on_platform"
  add_index "gain_voucher_sys", ["sdk"], :name => "index_gain_voucher_sys_on_sdk"
  add_index "gain_voucher_sys", ["zone_id"], :name => "index_gain_voucher_sys_on_zone_id"

  create_table "game_accounts", :force => true do |t|
    t.string   "sid",               :limit => 50,                :null => false
    t.string   "market",            :limit => 50
    t.string   "sdk",               :limit => 50
    t.string   "platform",          :limit => 10
    t.date     "reg_date"
    t.datetime "last_login_at"
    t.datetime "last_logout_at"
    t.integer  "active_secs",                     :default => 0
    t.integer  "total_active_secs",               :default => 0
    t.integer  "active_days",                     :default => 0
  end

  add_index "game_accounts", ["last_login_at", "active_secs"], :name => "index_game_accounts_on_last_login_at_and_active_secs"
  add_index "game_accounts", ["last_login_at"], :name => "index_game_accounts_on_last_login_at"
  add_index "game_accounts", ["market"], :name => "index_game_accounts_on_market"
  add_index "game_accounts", ["platform"], :name => "index_game_accounts_on_platform"
  add_index "game_accounts", ["reg_date", "last_login_at", "market"], :name => "index_game_accounts_on_reg_date_and_last_login_at_and_market"
  add_index "game_accounts", ["reg_date", "last_login_at", "platform"], :name => "index_game_accounts_on_reg_date_and_last_login_at_and_platform"
  add_index "game_accounts", ["reg_date", "last_login_at", "sdk"], :name => "index_game_accounts_on_reg_date_and_last_login_at_and_sdk"
  add_index "game_accounts", ["reg_date", "last_login_at"], :name => "index_game_accounts_on_reg_date_and_last_login_at"
  add_index "game_accounts", ["reg_date"], :name => "index_game_accounts_on_reg_date"
  add_index "game_accounts", ["sdk"], :name => "index_game_accounts_on_sdk"
  add_index "game_accounts", ["sid"], :name => "index_game_accounts_on_sid", :unique => true

  create_table "game_devices", :force => true do |t|
    t.string   "sid",               :limit => 70,                :null => false
    t.string   "market",            :limit => 50
    t.string   "sdk",               :limit => 50
    t.string   "platform",          :limit => 10
    t.date     "reg_date"
    t.datetime "last_login_at"
    t.datetime "last_logout_at"
    t.integer  "active_secs",                     :default => 0
    t.integer  "total_active_secs",               :default => 0
    t.integer  "active_days",                     :default => 0
  end

  add_index "game_devices", ["last_login_at", "active_secs"], :name => "index_game_devices_on_last_login_at_and_active_secs"
  add_index "game_devices", ["last_login_at"], :name => "index_game_devices_on_last_login_at"
  add_index "game_devices", ["market"], :name => "index_game_devices_on_market"
  add_index "game_devices", ["platform"], :name => "index_game_devices_on_platform"
  add_index "game_devices", ["reg_date", "last_login_at", "market"], :name => "index_game_devices_on_reg_date_and_last_login_at_and_market"
  add_index "game_devices", ["reg_date", "last_login_at", "platform"], :name => "index_game_devices_on_reg_date_and_last_login_at_and_platform"
  add_index "game_devices", ["reg_date", "last_login_at", "sdk"], :name => "index_game_devices_on_reg_date_and_last_login_at_and_sdk"
  add_index "game_devices", ["reg_date", "last_login_at"], :name => "index_game_devices_on_reg_date_and_last_login_at"
  add_index "game_devices", ["reg_date"], :name => "index_game_devices_on_reg_date"
  add_index "game_devices", ["sdk"], :name => "index_game_devices_on_sdk"
  add_index "game_devices", ["sid"], :name => "index_game_devices_on_sid", :unique => true

  create_table "game_users", :force => true do |t|
    t.string   "sid",               :limit => 50,                :null => false
    t.string   "market",            :limit => 50
    t.string   "sdk",               :limit => 50
    t.string   "platform",          :limit => 10
    t.date     "reg_date"
    t.datetime "last_login_at"
    t.datetime "last_logout_at"
    t.integer  "active_secs",                     :default => 0
    t.integer  "total_active_secs",               :default => 0
    t.integer  "active_days",                     :default => 0
  end

  add_index "game_users", ["last_login_at", "active_secs"], :name => "index_game_users_on_last_login_at_and_active_secs"
  add_index "game_users", ["last_login_at"], :name => "index_game_users_on_last_login_at"
  add_index "game_users", ["market"], :name => "index_game_users_on_market"
  add_index "game_users", ["platform"], :name => "index_game_users_on_platform"
  add_index "game_users", ["reg_date", "last_login_at", "market"], :name => "index_game_users_on_reg_date_and_last_login_at_and_market"
  add_index "game_users", ["reg_date", "last_login_at", "platform"], :name => "index_game_users_on_reg_date_and_last_login_at_and_platform"
  add_index "game_users", ["reg_date", "last_login_at", "sdk"], :name => "index_game_users_on_reg_date_and_last_login_at_and_sdk"
  add_index "game_users", ["reg_date", "last_login_at"], :name => "index_game_users_on_reg_date_and_last_login_at"
  add_index "game_users", ["reg_date"], :name => "index_game_users_on_reg_date"
  add_index "game_users", ["sdk"], :name => "index_game_users_on_sdk"
  add_index "game_users", ["sid"], :name => "index_game_users_on_sid", :unique => true

  create_table "guild_active", :force => true do |t|
    t.integer "zone_id",                   :default => 0
    t.string  "sdk",         :limit => 50,                :null => false
    t.string  "platform",    :limit => 10,                :null => false
    t.date    "date",                                     :null => false
    t.string  "guild_id"
    t.string  "active_type"
  end

  add_index "guild_active", ["date", "zone_id"], :name => "index_guild_active_on_date_and_zone_id"

  create_table "guild_active_report", :force => true do |t|
    t.integer "zone_id",                   :default => 0
    t.string  "sdk",         :limit => 50,                :null => false
    t.string  "platform",    :limit => 10,                :null => false
    t.date    "date",                                     :null => false
    t.string  "guild_id"
    t.string  "active_type"
    t.integer "num"
  end

  add_index "guild_active_report", ["date", "zone_id", "active_type", "guild_id"], :name => "index_gar_on_dt_and_zone_and_act_and_gid"

  create_table "guild_level_record", :force => true do |t|
    t.date    "record_date",          :null => false
    t.integer "zone"
    t.integer "level_1"
    t.integer "level_2"
    t.integer "level_3"
    t.integer "level_4"
    t.integer "level_5"
    t.integer "level_6"
    t.integer "level_7"
    t.integer "level_8"
    t.integer "level_9"
    t.integer "level_10"
    t.integer "level_11_15"
    t.integer "level_16_20"
    t.integer "level_21_25"
    t.integer "level_26_30"
    t.integer "level_over_30"
    t.integer "level_1_person"
    t.integer "level_2_person"
    t.integer "level_3_person"
    t.integer "level_4_person"
    t.integer "level_5_person"
    t.integer "level_6_person"
    t.integer "level_7_person"
    t.integer "level_8_person"
    t.integer "level_9_person"
    t.integer "level_10_person"
    t.integer "level_11_15_person"
    t.integer "level_16_20_person"
    t.integer "level_21_25_person"
    t.integer "level_26_30_person"
    t.integer "level_over_30_person"
  end

  add_index "guild_level_record", ["record_date", "zone"], :name => "index_guild_level_record_on_record_date_and_zone"

  create_table "guild_skill", :force => true do |t|
    t.string  "sdk",           :limit => 50,                :null => false
    t.string  "platform",      :limit => 10,                :null => false
    t.integer "zone_id",                     :default => 1
    t.string  "pid"
    t.integer "guild_skill_1"
    t.integer "guild_skill_2"
    t.integer "guild_skill_3"
    t.integer "guild_skill_4"
    t.integer "guild_skill_5"
    t.integer "guild_skill_6"
  end

  add_index "guild_skill", ["pid", "zone_id"], :name => "index_guild_skill_on_pid_and_zone_id"

  create_table "guild_skill_report", :force => true do |t|
    t.string  "sdk",      :limit => 50,                :null => false
    t.string  "platform", :limit => 10,                :null => false
    t.integer "zone_id",                :default => 1
    t.date    "date",                                  :null => false
    t.string  "skill_id"
    t.integer "lv_rgn"
    t.integer "num"
  end

  add_index "guild_skill_report", ["date", "zone_id", "skill_id", "lv_rgn"], :name => "index_gkr_on_rd_and_zone_and_sid_and_lr"

  create_table "guilds", :force => true do |t|
    t.string  "guild_id"
    t.integer "zone"
    t.integer "level"
    t.integer "member_size"
  end

  add_index "guilds", ["guild_id", "zone"], :name => "index_guilds_on_guild_id_and_zone"

  create_table "level_campaign_report", :force => true do |t|
    t.integer "zone_id",                 :default => 0
    t.string  "sdk",       :limit => 50,                :null => false
    t.string  "platform",  :limit => 10,                :null => false
    t.date    "date",                                   :null => false
    t.integer "count",                   :default => 0
    t.integer "players",                 :default => 0
    t.string  "kind",                                   :null => false
    t.integer "level_rgn"
  end

  add_index "level_campaign_report", ["date", "zone_id"], :name => "index_level_campaign_report_on_date_and_zone_id"

  create_table "main_quest_report", :force => true do |t|
    t.date    "date",                    :null => false
    t.integer "zone_id", :default => 1
    t.string  "tid",     :default => ""
    t.integer "num",     :default => 0
  end

  add_index "main_quest_report", ["date", "zone_id"], :name => "index_main_quest_report_on_date_and_zone_id"

  create_table "main_quest_users", :force => true do |t|
    t.string  "sdk",      :limit => 50,                 :null => false
    t.string  "platform", :limit => 10,                 :null => false
    t.integer "zone_id",                :default => 1
    t.string  "pid",                    :default => ""
    t.string  "qid",                    :default => ""
  end

  add_index "main_quest_users", ["zone_id", "qid"], :name => "index_main_quest_users_on_zone_id_and_qid"

  create_table "main_quest_users_report", :force => true do |t|
    t.string  "sdk",      :limit => 50,                 :null => false
    t.string  "platform", :limit => 10,                 :null => false
    t.integer "zone_id",                :default => 1
    t.date    "date",                                   :null => false
    t.string  "qid",                    :default => ""
    t.integer "num",                    :default => 0
  end

  add_index "main_quest_users_report", ["date", "zone_id", "platform", "sdk", "qid"], :name => "index_on_mqur_as_date_and_zone_and_pltfm_and_sdk_and_qtid"

  create_table "markets", :force => true do |t|
    t.string "market", :limit => 50, :null => false
  end

  add_index "markets", ["market"], :name => "index_markets_on_market", :unique => true

  create_table "new_account_activity_reports", :force => true do |t|
    t.date    "date",                    :null => false
    t.integer "total",    :default => 0
    t.integer "num_m5",   :default => 0
    t.integer "num_m10",  :default => 0
    t.integer "num_m15",  :default => 0
    t.integer "num_m20",  :default => 0
    t.integer "num_m25",  :default => 0
    t.integer "num_m30",  :default => 0
    t.integer "num_m35",  :default => 0
    t.integer "num_m40",  :default => 0
    t.integer "num_m45",  :default => 0
    t.integer "num_m50",  :default => 0
    t.integer "num_m55",  :default => 0
    t.integer "num_m60",  :default => 0
    t.integer "num_m120", :default => 0
    t.integer "num_m180", :default => 0
    t.integer "num_m300", :default => 0
    t.integer "m300plus", :default => 0
  end

  add_index "new_account_activity_reports", ["date"], :name => "index_new_account_activity_reports_on_date", :unique => true

  create_table "new_account_market_activity_reports", :force => true do |t|
    t.date    "date",                                  :null => false
    t.string  "market",   :limit => 20,                :null => false
    t.integer "total",                  :default => 0
    t.integer "num_m5",                 :default => 0
    t.integer "num_m10",                :default => 0
    t.integer "num_m15",                :default => 0
    t.integer "num_m20",                :default => 0
    t.integer "num_m25",                :default => 0
    t.integer "num_m30",                :default => 0
    t.integer "num_m35",                :default => 0
    t.integer "num_m40",                :default => 0
    t.integer "num_m45",                :default => 0
    t.integer "num_m50",                :default => 0
    t.integer "num_m55",                :default => 0
    t.integer "num_m60",                :default => 0
    t.integer "num_m120",               :default => 0
    t.integer "num_m180",               :default => 0
    t.integer "num_m300",               :default => 0
    t.integer "m300plus",               :default => 0
  end

  add_index "new_account_market_activity_reports", ["date", "market"], :name => "index_new_account_market_activity_reports_on_date_and_market", :unique => true
  add_index "new_account_market_activity_reports", ["market"], :name => "index_new_account_market_activity_reports_on_market"

  create_table "new_account_platform_activity_reports", :force => true do |t|
    t.date    "date",                                  :null => false
    t.string  "platform", :limit => 20,                :null => false
    t.integer "total",                  :default => 0
    t.integer "num_m5",                 :default => 0
    t.integer "num_m10",                :default => 0
    t.integer "num_m15",                :default => 0
    t.integer "num_m20",                :default => 0
    t.integer "num_m25",                :default => 0
    t.integer "num_m30",                :default => 0
    t.integer "num_m35",                :default => 0
    t.integer "num_m40",                :default => 0
    t.integer "num_m45",                :default => 0
    t.integer "num_m50",                :default => 0
    t.integer "num_m55",                :default => 0
    t.integer "num_m60",                :default => 0
    t.integer "num_m120",               :default => 0
    t.integer "num_m180",               :default => 0
    t.integer "num_m300",               :default => 0
    t.integer "m300plus",               :default => 0
  end

  add_index "new_account_platform_activity_reports", ["date", "platform"], :name => "index_new_account_platform_activity_reports_on_date_and_platform", :unique => true
  add_index "new_account_platform_activity_reports", ["platform"], :name => "index_new_account_platform_activity_reports_on_platform"

  create_table "new_account_sdk_activity_reports", :force => true do |t|
    t.date    "date",                                  :null => false
    t.string  "sdk",      :limit => 20,                :null => false
    t.integer "total",                  :default => 0
    t.integer "num_m5",                 :default => 0
    t.integer "num_m10",                :default => 0
    t.integer "num_m15",                :default => 0
    t.integer "num_m20",                :default => 0
    t.integer "num_m25",                :default => 0
    t.integer "num_m30",                :default => 0
    t.integer "num_m35",                :default => 0
    t.integer "num_m40",                :default => 0
    t.integer "num_m45",                :default => 0
    t.integer "num_m50",                :default => 0
    t.integer "num_m55",                :default => 0
    t.integer "num_m60",                :default => 0
    t.integer "num_m120",               :default => 0
    t.integer "num_m180",               :default => 0
    t.integer "num_m300",               :default => 0
    t.integer "m300plus",               :default => 0
  end

  add_index "new_account_sdk_activity_reports", ["date", "sdk"], :name => "index_new_account_sdk_activity_reports_on_date_and_sdk", :unique => true
  add_index "new_account_sdk_activity_reports", ["sdk"], :name => "index_new_account_sdk_activity_reports_on_sdk"

  create_table "new_account_zone_id_activity_reports", :force => true do |t|
    t.date    "date",                    :null => false
    t.integer "zone_id",  :default => 0
    t.integer "total",    :default => 0
    t.integer "num_m5",   :default => 0
    t.integer "num_m10",  :default => 0
    t.integer "num_m15",  :default => 0
    t.integer "num_m20",  :default => 0
    t.integer "num_m25",  :default => 0
    t.integer "num_m30",  :default => 0
    t.integer "num_m35",  :default => 0
    t.integer "num_m40",  :default => 0
    t.integer "num_m45",  :default => 0
    t.integer "num_m50",  :default => 0
    t.integer "num_m55",  :default => 0
    t.integer "num_m60",  :default => 0
    t.integer "num_m120", :default => 0
    t.integer "num_m180", :default => 0
    t.integer "num_m300", :default => 0
    t.integer "m300plus", :default => 0
  end

  add_index "new_account_zone_id_activity_reports", ["date", "zone_id"], :name => "index_new_account_zone_id_activity_reports_on_date_and_zone_id", :unique => true
  add_index "new_account_zone_id_activity_reports", ["zone_id"], :name => "index_new_account_zone_id_activity_reports_on_zone_id"

  create_table "new_device_activity_reports", :force => true do |t|
    t.date    "date",                    :null => false
    t.integer "total",    :default => 0
    t.integer "num_m5",   :default => 0
    t.integer "num_m10",  :default => 0
    t.integer "num_m15",  :default => 0
    t.integer "num_m20",  :default => 0
    t.integer "num_m25",  :default => 0
    t.integer "num_m30",  :default => 0
    t.integer "num_m35",  :default => 0
    t.integer "num_m40",  :default => 0
    t.integer "num_m45",  :default => 0
    t.integer "num_m50",  :default => 0
    t.integer "num_m55",  :default => 0
    t.integer "num_m60",  :default => 0
    t.integer "num_m120", :default => 0
    t.integer "num_m180", :default => 0
    t.integer "num_m300", :default => 0
    t.integer "m300plus", :default => 0
  end

  add_index "new_device_activity_reports", ["date"], :name => "index_new_device_activity_reports_on_date", :unique => true

  create_table "new_device_market_activity_reports", :force => true do |t|
    t.date    "date",                                  :null => false
    t.string  "market",   :limit => 20,                :null => false
    t.integer "total",                  :default => 0
    t.integer "num_m5",                 :default => 0
    t.integer "num_m10",                :default => 0
    t.integer "num_m15",                :default => 0
    t.integer "num_m20",                :default => 0
    t.integer "num_m25",                :default => 0
    t.integer "num_m30",                :default => 0
    t.integer "num_m35",                :default => 0
    t.integer "num_m40",                :default => 0
    t.integer "num_m45",                :default => 0
    t.integer "num_m50",                :default => 0
    t.integer "num_m55",                :default => 0
    t.integer "num_m60",                :default => 0
    t.integer "num_m120",               :default => 0
    t.integer "num_m180",               :default => 0
    t.integer "num_m300",               :default => 0
    t.integer "m300plus",               :default => 0
  end

  add_index "new_device_market_activity_reports", ["date", "market"], :name => "index_new_device_market_activity_reports_on_date_and_market", :unique => true
  add_index "new_device_market_activity_reports", ["market"], :name => "index_new_device_market_activity_reports_on_market"

  create_table "new_device_platform_activity_reports", :force => true do |t|
    t.date    "date",                                  :null => false
    t.string  "platform", :limit => 20,                :null => false
    t.integer "total",                  :default => 0
    t.integer "num_m5",                 :default => 0
    t.integer "num_m10",                :default => 0
    t.integer "num_m15",                :default => 0
    t.integer "num_m20",                :default => 0
    t.integer "num_m25",                :default => 0
    t.integer "num_m30",                :default => 0
    t.integer "num_m35",                :default => 0
    t.integer "num_m40",                :default => 0
    t.integer "num_m45",                :default => 0
    t.integer "num_m50",                :default => 0
    t.integer "num_m55",                :default => 0
    t.integer "num_m60",                :default => 0
    t.integer "num_m120",               :default => 0
    t.integer "num_m180",               :default => 0
    t.integer "num_m300",               :default => 0
    t.integer "m300plus",               :default => 0
  end

  add_index "new_device_platform_activity_reports", ["date", "platform"], :name => "index_new_device_platform_activity_reports_on_date_and_platform", :unique => true
  add_index "new_device_platform_activity_reports", ["platform"], :name => "index_new_device_platform_activity_reports_on_platform"

  create_table "new_device_sdk_activity_reports", :force => true do |t|
    t.date    "date",                                  :null => false
    t.string  "sdk",      :limit => 20,                :null => false
    t.integer "total",                  :default => 0
    t.integer "num_m5",                 :default => 0
    t.integer "num_m10",                :default => 0
    t.integer "num_m15",                :default => 0
    t.integer "num_m20",                :default => 0
    t.integer "num_m25",                :default => 0
    t.integer "num_m30",                :default => 0
    t.integer "num_m35",                :default => 0
    t.integer "num_m40",                :default => 0
    t.integer "num_m45",                :default => 0
    t.integer "num_m50",                :default => 0
    t.integer "num_m55",                :default => 0
    t.integer "num_m60",                :default => 0
    t.integer "num_m120",               :default => 0
    t.integer "num_m180",               :default => 0
    t.integer "num_m300",               :default => 0
    t.integer "m300plus",               :default => 0
  end

  add_index "new_device_sdk_activity_reports", ["date", "sdk"], :name => "index_new_device_sdk_activity_reports_on_date_and_sdk", :unique => true
  add_index "new_device_sdk_activity_reports", ["sdk"], :name => "index_new_device_sdk_activity_reports_on_sdk"

  create_table "new_device_zone_id_activity_reports", :force => true do |t|
    t.date    "date",                    :null => false
    t.integer "zone_id",  :default => 0
    t.integer "total",    :default => 0
    t.integer "num_m5",   :default => 0
    t.integer "num_m10",  :default => 0
    t.integer "num_m15",  :default => 0
    t.integer "num_m20",  :default => 0
    t.integer "num_m25",  :default => 0
    t.integer "num_m30",  :default => 0
    t.integer "num_m35",  :default => 0
    t.integer "num_m40",  :default => 0
    t.integer "num_m45",  :default => 0
    t.integer "num_m50",  :default => 0
    t.integer "num_m55",  :default => 0
    t.integer "num_m60",  :default => 0
    t.integer "num_m120", :default => 0
    t.integer "num_m180", :default => 0
    t.integer "num_m300", :default => 0
    t.integer "m300plus", :default => 0
  end

  add_index "new_device_zone_id_activity_reports", ["date", "zone_id"], :name => "index_new_device_zone_id_activity_reports_on_date_and_zone_id", :unique => true
  add_index "new_device_zone_id_activity_reports", ["zone_id"], :name => "index_new_device_zone_id_activity_reports_on_zone_id"

  create_table "new_user_activity_reports", :force => true do |t|
    t.date    "date",                    :null => false
    t.integer "total",    :default => 0
    t.integer "num_m5",   :default => 0
    t.integer "num_m10",  :default => 0
    t.integer "num_m15",  :default => 0
    t.integer "num_m20",  :default => 0
    t.integer "num_m25",  :default => 0
    t.integer "num_m30",  :default => 0
    t.integer "num_m35",  :default => 0
    t.integer "num_m40",  :default => 0
    t.integer "num_m45",  :default => 0
    t.integer "num_m50",  :default => 0
    t.integer "num_m55",  :default => 0
    t.integer "num_m60",  :default => 0
    t.integer "num_m120", :default => 0
    t.integer "num_m180", :default => 0
    t.integer "num_m300", :default => 0
    t.integer "m300plus", :default => 0
  end

  add_index "new_user_activity_reports", ["date"], :name => "index_new_user_activity_reports_on_date", :unique => true

  create_table "new_user_market_activity_reports", :force => true do |t|
    t.date    "date",                                  :null => false
    t.string  "market",   :limit => 20,                :null => false
    t.integer "total",                  :default => 0
    t.integer "num_m5",                 :default => 0
    t.integer "num_m10",                :default => 0
    t.integer "num_m15",                :default => 0
    t.integer "num_m20",                :default => 0
    t.integer "num_m25",                :default => 0
    t.integer "num_m30",                :default => 0
    t.integer "num_m35",                :default => 0
    t.integer "num_m40",                :default => 0
    t.integer "num_m45",                :default => 0
    t.integer "num_m50",                :default => 0
    t.integer "num_m55",                :default => 0
    t.integer "num_m60",                :default => 0
    t.integer "num_m120",               :default => 0
    t.integer "num_m180",               :default => 0
    t.integer "num_m300",               :default => 0
    t.integer "m300plus",               :default => 0
  end

  add_index "new_user_market_activity_reports", ["date", "market"], :name => "index_new_user_market_activity_reports_on_date_and_market", :unique => true
  add_index "new_user_market_activity_reports", ["market"], :name => "index_new_user_market_activity_reports_on_market"

  create_table "new_user_platform_activity_reports", :force => true do |t|
    t.date    "date",                                  :null => false
    t.string  "platform", :limit => 20,                :null => false
    t.integer "total",                  :default => 0
    t.integer "num_m5",                 :default => 0
    t.integer "num_m10",                :default => 0
    t.integer "num_m15",                :default => 0
    t.integer "num_m20",                :default => 0
    t.integer "num_m25",                :default => 0
    t.integer "num_m30",                :default => 0
    t.integer "num_m35",                :default => 0
    t.integer "num_m40",                :default => 0
    t.integer "num_m45",                :default => 0
    t.integer "num_m50",                :default => 0
    t.integer "num_m55",                :default => 0
    t.integer "num_m60",                :default => 0
    t.integer "num_m120",               :default => 0
    t.integer "num_m180",               :default => 0
    t.integer "num_m300",               :default => 0
    t.integer "m300plus",               :default => 0
  end

  add_index "new_user_platform_activity_reports", ["date", "platform"], :name => "index_new_user_platform_activity_reports_on_date_and_platform", :unique => true
  add_index "new_user_platform_activity_reports", ["platform"], :name => "index_new_user_platform_activity_reports_on_platform"

  create_table "new_user_sdk_activity_reports", :force => true do |t|
    t.date    "date",                                  :null => false
    t.string  "sdk",      :limit => 20,                :null => false
    t.integer "total",                  :default => 0
    t.integer "num_m5",                 :default => 0
    t.integer "num_m10",                :default => 0
    t.integer "num_m15",                :default => 0
    t.integer "num_m20",                :default => 0
    t.integer "num_m25",                :default => 0
    t.integer "num_m30",                :default => 0
    t.integer "num_m35",                :default => 0
    t.integer "num_m40",                :default => 0
    t.integer "num_m45",                :default => 0
    t.integer "num_m50",                :default => 0
    t.integer "num_m55",                :default => 0
    t.integer "num_m60",                :default => 0
    t.integer "num_m120",               :default => 0
    t.integer "num_m180",               :default => 0
    t.integer "num_m300",               :default => 0
    t.integer "m300plus",               :default => 0
  end

  add_index "new_user_sdk_activity_reports", ["date", "sdk"], :name => "index_new_user_sdk_activity_reports_on_date_and_sdk", :unique => true
  add_index "new_user_sdk_activity_reports", ["sdk"], :name => "index_new_user_sdk_activity_reports_on_sdk"

  create_table "new_user_zone_id_activity_reports", :force => true do |t|
    t.date    "date",                    :null => false
    t.integer "zone_id",  :default => 0
    t.integer "total",    :default => 0
    t.integer "num_m5",   :default => 0
    t.integer "num_m10",  :default => 0
    t.integer "num_m15",  :default => 0
    t.integer "num_m20",  :default => 0
    t.integer "num_m25",  :default => 0
    t.integer "num_m30",  :default => 0
    t.integer "num_m35",  :default => 0
    t.integer "num_m40",  :default => 0
    t.integer "num_m45",  :default => 0
    t.integer "num_m50",  :default => 0
    t.integer "num_m55",  :default => 0
    t.integer "num_m60",  :default => 0
    t.integer "num_m120", :default => 0
    t.integer "num_m180", :default => 0
    t.integer "num_m300", :default => 0
    t.integer "m300plus", :default => 0
  end

  add_index "new_user_zone_id_activity_reports", ["date", "zone_id"], :name => "index_new_user_zone_id_activity_reports_on_date_and_zone_id", :unique => true
  add_index "new_user_zone_id_activity_reports", ["zone_id"], :name => "index_new_user_zone_id_activity_reports_on_zone_id"

  create_table "online_user_numbers", :force => true do |t|
    t.date    "date"
    t.integer "zone_id", :default => 1
    t.integer "hour"
    t.integer "max",     :default => 0
    t.integer "min",     :default => 0
  end

  create_table "paid_user_market_activity_reports", :force => true do |t|
    t.date    "date",                                  :null => false
    t.string  "market",   :limit => 20,                :null => false
    t.integer "total",                  :default => 0
    t.integer "num_m5",                 :default => 0
    t.integer "num_m10",                :default => 0
    t.integer "num_m15",                :default => 0
    t.integer "num_m20",                :default => 0
    t.integer "num_m25",                :default => 0
    t.integer "num_m30",                :default => 0
    t.integer "num_m35",                :default => 0
    t.integer "num_m40",                :default => 0
    t.integer "num_m45",                :default => 0
    t.integer "num_m50",                :default => 0
    t.integer "num_m55",                :default => 0
    t.integer "num_m60",                :default => 0
    t.integer "num_m120",               :default => 0
    t.integer "num_m180",               :default => 0
    t.integer "num_m300",               :default => 0
    t.integer "m300plus",               :default => 0
  end

  add_index "paid_user_market_activity_reports", ["date", "market"], :name => "index_paid_user_market_activity_reports_on_date_and_market", :unique => true
  add_index "paid_user_market_activity_reports", ["market"], :name => "index_paid_user_market_activity_reports_on_market"

  create_table "paid_user_platform_activity_reports", :force => true do |t|
    t.date    "date",                                  :null => false
    t.string  "platform", :limit => 20,                :null => false
    t.integer "total",                  :default => 0
    t.integer "num_m5",                 :default => 0
    t.integer "num_m10",                :default => 0
    t.integer "num_m15",                :default => 0
    t.integer "num_m20",                :default => 0
    t.integer "num_m25",                :default => 0
    t.integer "num_m30",                :default => 0
    t.integer "num_m35",                :default => 0
    t.integer "num_m40",                :default => 0
    t.integer "num_m45",                :default => 0
    t.integer "num_m50",                :default => 0
    t.integer "num_m55",                :default => 0
    t.integer "num_m60",                :default => 0
    t.integer "num_m120",               :default => 0
    t.integer "num_m180",               :default => 0
    t.integer "num_m300",               :default => 0
    t.integer "m300plus",               :default => 0
  end

  add_index "paid_user_platform_activity_reports", ["date", "platform"], :name => "index_paid_user_platform_activity_reports_on_date_and_platform", :unique => true
  add_index "paid_user_platform_activity_reports", ["platform"], :name => "index_paid_user_platform_activity_reports_on_platform"

  create_table "paid_user_sdk_activity_reports", :force => true do |t|
    t.date    "date",                                  :null => false
    t.string  "sdk",      :limit => 20,                :null => false
    t.integer "total",                  :default => 0
    t.integer "num_m5",                 :default => 0
    t.integer "num_m10",                :default => 0
    t.integer "num_m15",                :default => 0
    t.integer "num_m20",                :default => 0
    t.integer "num_m25",                :default => 0
    t.integer "num_m30",                :default => 0
    t.integer "num_m35",                :default => 0
    t.integer "num_m40",                :default => 0
    t.integer "num_m45",                :default => 0
    t.integer "num_m50",                :default => 0
    t.integer "num_m55",                :default => 0
    t.integer "num_m60",                :default => 0
    t.integer "num_m120",               :default => 0
    t.integer "num_m180",               :default => 0
    t.integer "num_m300",               :default => 0
    t.integer "m300plus",               :default => 0
  end

  add_index "paid_user_sdk_activity_reports", ["date", "sdk"], :name => "index_paid_user_sdk_activity_reports_on_date_and_sdk", :unique => true
  add_index "paid_user_sdk_activity_reports", ["sdk"], :name => "index_paid_user_sdk_activity_reports_on_sdk"

  create_table "paid_user_zone_id_activity_reports", :force => true do |t|
    t.date    "date",                    :null => false
    t.integer "zone_id",  :default => 0
    t.integer "total",    :default => 0
    t.integer "num_m5",   :default => 0
    t.integer "num_m10",  :default => 0
    t.integer "num_m15",  :default => 0
    t.integer "num_m20",  :default => 0
    t.integer "num_m25",  :default => 0
    t.integer "num_m30",  :default => 0
    t.integer "num_m35",  :default => 0
    t.integer "num_m40",  :default => 0
    t.integer "num_m45",  :default => 0
    t.integer "num_m50",  :default => 0
    t.integer "num_m55",  :default => 0
    t.integer "num_m60",  :default => 0
    t.integer "num_m120", :default => 0
    t.integer "num_m180", :default => 0
    t.integer "num_m300", :default => 0
    t.integer "m300plus", :default => 0
  end

  add_index "paid_user_zone_id_activity_reports", ["date", "zone_id"], :name => "index_paid_user_zone_id_activity_reports_on_date_and_zone_id", :unique => true
  add_index "paid_user_zone_id_activity_reports", ["zone_id"], :name => "index_paid_user_zone_id_activity_reports_on_zone_id"

  create_table "platforms", :force => true do |t|
    t.string "platform", :limit => 10, :null => false
  end

  add_index "platforms", ["platform"], :name => "index_platforms_on_platform", :unique => true

  create_table "player_record", :force => true do |t|
    t.string "kind", :null => false
    t.string "pid",  :null => false
    t.string "data", :null => false
  end

  add_index "player_record", ["kind", "pid", "data"], :name => "index_player_record_on_kind_and_pid_and_data"

  create_table "recharge_record", :force => true do |t|
    t.string  "platform",                      :null => false
    t.string  "sdk"
    t.string  "market"
    t.integer "zone_id",    :default => 0
    t.string  "cid",                           :null => false
    t.string  "pid",                           :null => false
    t.date    "date",                          :null => false
    t.date    "first_date",                    :null => false
    t.integer "num",        :default => 0
    t.string  "goods",                         :null => false
    t.integer "total_num",  :default => 0
    t.integer "days",       :default => 0
    t.boolean "isnew",      :default => false
  end

  add_index "recharge_record", ["goods", "zone_id"], :name => "index_recharge_record_on_goods_and_zone_id"

  create_table "recharge_report", :force => true do |t|
    t.string  "platform",                :null => false
    t.string  "sdk"
    t.string  "market"
    t.integer "zone_id",  :default => 0
    t.date    "date",                    :null => false
    t.integer "num",      :default => 0
    t.string  "goods",                   :null => false
    t.boolean "isnew"
  end

  add_index "recharge_report", ["goods", "zone_id"], :name => "index_recharge_report_on_goods_and_zone_id"

  create_table "remove_item", :force => true do |t|
    t.integer "zone_id",                :default => 0
    t.string  "sdk",      :limit => 50,                :null => false
    t.string  "platform", :limit => 10,                :null => false
    t.date    "date"
    t.string  "reason"
    t.string  "pid"
    t.integer "count",    :limit => 8,  :default => 0
    t.integer "level",                  :default => 0
  end

  add_index "remove_item", ["date"], :name => "index_remove_item_on_date"
  add_index "remove_item", ["platform"], :name => "index_remove_item_on_platform"
  add_index "remove_item", ["sdk"], :name => "index_remove_item_on_sdk"
  add_index "remove_item", ["zone_id"], :name => "index_remove_item_on_zone_id"

  create_table "sdks", :force => true do |t|
    t.string "sdk", :limit => 50, :null => false
  end

  add_index "sdks", ["sdk"], :name => "index_sdks_on_sdk", :unique => true

  create_table "share_award", :force => true do |t|
    t.integer "zone_id",                :default => 0
    t.string  "sdk",      :limit => 50,                :null => false
    t.string  "platform", :limit => 10,                :null => false
    t.date    "date",                                  :null => false
    t.string  "tid",                                   :null => false
  end

  add_index "share_award", ["date", "zone_id"], :name => "index_share_award_on_date_and_zone_id"

  create_table "share_award_report", :force => true do |t|
    t.integer "zone_id",                :default => 0
    t.string  "sdk",      :limit => 50,                :null => false
    t.string  "platform", :limit => 10,                :null => false
    t.date    "date",                                  :null => false
    t.string  "tid",                                   :null => false
    t.integer "num",                    :default => 0
  end

  add_index "share_award_report", ["date", "zone_id"], :name => "index_share_award_report_on_date_and_zone_id"

  create_table "shop_consume", :force => true do |t|
    t.integer "zone_id",                 :default => 0
    t.string  "sdk",       :limit => 50,                :null => false
    t.string  "platform",  :limit => 10,                :null => false
    t.date    "date"
    t.string  "pid"
    t.string  "shop_id"
    t.string  "tid"
    t.string  "cost_type"
    t.integer "count",     :limit => 8,  :default => 0
    t.integer "consume",   :limit => 8,  :default => 0
  end

  add_index "shop_consume", ["zone_id", "date"], :name => "index_shop_consume_on_zone_id_and_date"

  create_table "shop_consume_sum", :force => true do |t|
    t.integer "zone_id",                 :default => 0
    t.string  "sdk",       :limit => 50,                :null => false
    t.string  "platform",  :limit => 10,                :null => false
    t.date    "date"
    t.string  "tid"
    t.string  "shop_id"
    t.string  "cost_type"
    t.integer "count",     :limit => 8,  :default => 0
    t.integer "consume",   :limit => 8,  :default => 0
    t.integer "players",   :limit => 8,  :default => 0
  end

  add_index "shop_consume_sum", ["zone_id", "date"], :name => "index_shop_consume_sum_on_zone_id_and_date"

  create_table "start_campaign", :force => true do |t|
    t.integer "zone_id",                 :default => 0
    t.string  "sdk",       :limit => 50,                 :null => false
    t.string  "platform",  :limit => 10,                 :null => false
    t.date    "date",                                    :null => false
    t.integer "count",                   :default => 0
    t.integer "level_rgn",               :default => 10
    t.string  "pid",                                     :null => false
    t.string  "kind",                                    :null => false
  end

  add_index "start_campaign", ["date", "sdk", "zone_id", "platform"], :name => "index_start_campaign_on_date_and_sdk_and_zone_id_and_platform"

  create_table "start_campaign_sum", :force => true do |t|
    t.integer "zone_id",                :default => 0
    t.string  "sdk",      :limit => 50,                :null => false
    t.string  "platform", :limit => 10,                :null => false
    t.date    "date",                                  :null => false
    t.integer "count",                  :default => 0
    t.integer "players",                :default => 0
    t.integer "accounts",               :default => 0
    t.string  "kind",                                  :null => false
  end

  add_index "start_campaign_sum", ["date", "zone_id"], :name => "index_start_campaign_sum_on_date_and_zone_id"

  create_table "stats_server", :force => true do |t|
    t.string "name", :null => false
    t.date   "date", :null => false
  end

  create_table "sys_flags", :force => true do |t|
    t.string "flag",                :null => false
    t.string "value", :limit => 64
  end

  add_index "sys_flags", ["flag"], :name => "index_sys_flags_on_flag", :unique => true

  create_table "sys_functions", :force => true do |t|
    t.string "name",               :null => false
    t.string "desc", :limit => 64
  end

  add_index "sys_functions", ["id"], :name => "index_sys_functions_on_id"

  create_table "sys_rights", :force => true do |t|
    t.integer "roleid", :null => false
    t.integer "funid",  :null => false
  end

  add_index "sys_rights", ["roleid"], :name => "index_sys_rights_on_roleid"

  create_table "sys_roles", :force => true do |t|
    t.string "name",               :null => false
    t.string "desc", :limit => 64
  end

  add_index "sys_roles", ["id"], :name => "index_sys_roles_on_id"

  create_table "sys_users", :force => true do |t|
    t.string  "email",    :limit => 64
    t.string  "password", :limit => 64
    t.integer "roleid",                                    :null => false
    t.boolean "inuse",                  :default => false
  end

  add_index "sys_users", ["email"], :name => "index_sys_users_on_email", :unique => true
  add_index "sys_users", ["id"], :name => "index_sys_users_on_id"

  create_table "user_activity_reports", :force => true do |t|
    t.date    "date",                    :null => false
    t.integer "total",    :default => 0
    t.integer "num_m5",   :default => 0
    t.integer "num_m10",  :default => 0
    t.integer "num_m15",  :default => 0
    t.integer "num_m20",  :default => 0
    t.integer "num_m25",  :default => 0
    t.integer "num_m30",  :default => 0
    t.integer "num_m35",  :default => 0
    t.integer "num_m40",  :default => 0
    t.integer "num_m45",  :default => 0
    t.integer "num_m50",  :default => 0
    t.integer "num_m55",  :default => 0
    t.integer "num_m60",  :default => 0
    t.integer "num_m120", :default => 0
    t.integer "num_m180", :default => 0
    t.integer "num_m300", :default => 0
    t.integer "m300plus", :default => 0
  end

  add_index "user_activity_reports", ["date"], :name => "index_user_activity_reports_on_date", :unique => true

  create_table "user_consume", :force => true do |t|
    t.integer "zone_id",                 :default => 0
    t.string  "sdk",       :limit => 50,                :null => false
    t.string  "platform",  :limit => 10,                :null => false
    t.string  "sys_name"
    t.string  "cost_type"
    t.integer "pid",                                    :null => false
    t.integer "cid",                                    :null => false
    t.integer "consume",                 :default => 0
  end

  add_index "user_consume", ["zone_id", "cost_type", "sys_name"], :name => "index_user_consume_on_zone_id_and_cost_type_and_sys_name"

  create_table "user_market_activity_reports", :force => true do |t|
    t.date    "date",                                  :null => false
    t.string  "market",   :limit => 20,                :null => false
    t.integer "total",                  :default => 0
    t.integer "num_m5",                 :default => 0
    t.integer "num_m10",                :default => 0
    t.integer "num_m15",                :default => 0
    t.integer "num_m20",                :default => 0
    t.integer "num_m25",                :default => 0
    t.integer "num_m30",                :default => 0
    t.integer "num_m35",                :default => 0
    t.integer "num_m40",                :default => 0
    t.integer "num_m45",                :default => 0
    t.integer "num_m50",                :default => 0
    t.integer "num_m55",                :default => 0
    t.integer "num_m60",                :default => 0
    t.integer "num_m120",               :default => 0
    t.integer "num_m180",               :default => 0
    t.integer "num_m300",               :default => 0
    t.integer "m300plus",               :default => 0
  end

  add_index "user_market_activity_reports", ["date", "market"], :name => "index_user_market_activity_reports_on_date_and_market", :unique => true
  add_index "user_market_activity_reports", ["market"], :name => "index_user_market_activity_reports_on_market"

  create_table "user_market_retention_reports", :force => true do |t|
    t.date    "date",                                 :null => false
    t.string  "market",  :limit => 20,                :null => false
    t.integer "num_d0",                :default => 0
    t.integer "num_d1",                :default => 0
    t.integer "num_d2",                :default => 0
    t.integer "num_d3",                :default => 0
    t.integer "num_d4",                :default => 0
    t.integer "num_d5",                :default => 0
    t.integer "num_d6",                :default => 0
    t.integer "num_d7",                :default => 0
    t.integer "num_d8",                :default => 0
    t.integer "num_d9",                :default => 0
    t.integer "num_d10",               :default => 0
    t.integer "num_d11",               :default => 0
    t.integer "num_d12",               :default => 0
    t.integer "num_d13",               :default => 0
    t.integer "num_d14",               :default => 0
    t.integer "num_d15",               :default => 0
    t.integer "num_d16",               :default => 0
    t.integer "num_d17",               :default => 0
    t.integer "num_d18",               :default => 0
    t.integer "num_d19",               :default => 0
    t.integer "num_d20",               :default => 0
    t.integer "num_d21",               :default => 0
    t.integer "num_d22",               :default => 0
    t.integer "num_d23",               :default => 0
    t.integer "num_d24",               :default => 0
    t.integer "num_d25",               :default => 0
    t.integer "num_d26",               :default => 0
    t.integer "num_d27",               :default => 0
    t.integer "num_d28",               :default => 0
    t.integer "num_d29",               :default => 0
    t.integer "num_d30",               :default => 0
    t.integer "num_d90",               :default => 0
  end

  add_index "user_market_retention_reports", ["date", "market"], :name => "index_user_market_retention_reports_on_date_and_market", :unique => true
  add_index "user_market_retention_reports", ["market"], :name => "index_user_market_retention_reports_on_market"

  create_table "user_platform_activity_reports", :force => true do |t|
    t.date    "date",                                  :null => false
    t.string  "platform", :limit => 20,                :null => false
    t.integer "total",                  :default => 0
    t.integer "num_m5",                 :default => 0
    t.integer "num_m10",                :default => 0
    t.integer "num_m15",                :default => 0
    t.integer "num_m20",                :default => 0
    t.integer "num_m25",                :default => 0
    t.integer "num_m30",                :default => 0
    t.integer "num_m35",                :default => 0
    t.integer "num_m40",                :default => 0
    t.integer "num_m45",                :default => 0
    t.integer "num_m50",                :default => 0
    t.integer "num_m55",                :default => 0
    t.integer "num_m60",                :default => 0
    t.integer "num_m120",               :default => 0
    t.integer "num_m180",               :default => 0
    t.integer "num_m300",               :default => 0
    t.integer "m300plus",               :default => 0
  end

  add_index "user_platform_activity_reports", ["date", "platform"], :name => "index_user_platform_activity_reports_on_date_and_platform", :unique => true
  add_index "user_platform_activity_reports", ["platform"], :name => "index_user_platform_activity_reports_on_platform"

  create_table "user_platform_retention_reports", :force => true do |t|
    t.date    "date",                                  :null => false
    t.string  "platform", :limit => 20,                :null => false
    t.integer "num_d0",                 :default => 0
    t.integer "num_d1",                 :default => 0
    t.integer "num_d2",                 :default => 0
    t.integer "num_d3",                 :default => 0
    t.integer "num_d4",                 :default => 0
    t.integer "num_d5",                 :default => 0
    t.integer "num_d6",                 :default => 0
    t.integer "num_d7",                 :default => 0
    t.integer "num_d8",                 :default => 0
    t.integer "num_d9",                 :default => 0
    t.integer "num_d10",                :default => 0
    t.integer "num_d11",                :default => 0
    t.integer "num_d12",                :default => 0
    t.integer "num_d13",                :default => 0
    t.integer "num_d14",                :default => 0
    t.integer "num_d15",                :default => 0
    t.integer "num_d16",                :default => 0
    t.integer "num_d17",                :default => 0
    t.integer "num_d18",                :default => 0
    t.integer "num_d19",                :default => 0
    t.integer "num_d20",                :default => 0
    t.integer "num_d21",                :default => 0
    t.integer "num_d22",                :default => 0
    t.integer "num_d23",                :default => 0
    t.integer "num_d24",                :default => 0
    t.integer "num_d25",                :default => 0
    t.integer "num_d26",                :default => 0
    t.integer "num_d27",                :default => 0
    t.integer "num_d28",                :default => 0
    t.integer "num_d29",                :default => 0
    t.integer "num_d30",                :default => 0
    t.integer "num_d90",                :default => 0
  end

  add_index "user_platform_retention_reports", ["date", "platform"], :name => "index_user_platform_retention_reports_on_date_and_platform", :unique => true
  add_index "user_platform_retention_reports", ["platform"], :name => "index_user_platform_retention_reports_on_platform"

  create_table "user_retention_reports", :force => true do |t|
    t.date    "date",                   :null => false
    t.integer "num_d0",  :default => 0
    t.integer "num_d1",  :default => 0
    t.integer "num_d2",  :default => 0
    t.integer "num_d3",  :default => 0
    t.integer "num_d4",  :default => 0
    t.integer "num_d5",  :default => 0
    t.integer "num_d6",  :default => 0
    t.integer "num_d7",  :default => 0
    t.integer "num_d8",  :default => 0
    t.integer "num_d9",  :default => 0
    t.integer "num_d10", :default => 0
    t.integer "num_d11", :default => 0
    t.integer "num_d12", :default => 0
    t.integer "num_d13", :default => 0
    t.integer "num_d14", :default => 0
    t.integer "num_d15", :default => 0
    t.integer "num_d16", :default => 0
    t.integer "num_d17", :default => 0
    t.integer "num_d18", :default => 0
    t.integer "num_d19", :default => 0
    t.integer "num_d20", :default => 0
    t.integer "num_d21", :default => 0
    t.integer "num_d22", :default => 0
    t.integer "num_d23", :default => 0
    t.integer "num_d24", :default => 0
    t.integer "num_d25", :default => 0
    t.integer "num_d26", :default => 0
    t.integer "num_d27", :default => 0
    t.integer "num_d28", :default => 0
    t.integer "num_d29", :default => 0
    t.integer "num_d30", :default => 0
    t.integer "num_d90", :default => 0
  end

  add_index "user_retention_reports", ["date"], :name => "index_user_retention_reports_on_date", :unique => true

  create_table "user_sdk_activity_reports", :force => true do |t|
    t.date    "date",                                  :null => false
    t.string  "sdk",      :limit => 20,                :null => false
    t.integer "total",                  :default => 0
    t.integer "num_m5",                 :default => 0
    t.integer "num_m10",                :default => 0
    t.integer "num_m15",                :default => 0
    t.integer "num_m20",                :default => 0
    t.integer "num_m25",                :default => 0
    t.integer "num_m30",                :default => 0
    t.integer "num_m35",                :default => 0
    t.integer "num_m40",                :default => 0
    t.integer "num_m45",                :default => 0
    t.integer "num_m50",                :default => 0
    t.integer "num_m55",                :default => 0
    t.integer "num_m60",                :default => 0
    t.integer "num_m120",               :default => 0
    t.integer "num_m180",               :default => 0
    t.integer "num_m300",               :default => 0
    t.integer "m300plus",               :default => 0
  end

  add_index "user_sdk_activity_reports", ["date", "sdk"], :name => "index_user_sdk_activity_reports_on_date_and_sdk", :unique => true
  add_index "user_sdk_activity_reports", ["sdk"], :name => "index_user_sdk_activity_reports_on_sdk"

  create_table "user_sdk_retention_reports", :force => true do |t|
    t.date    "date",                                 :null => false
    t.string  "sdk",     :limit => 20,                :null => false
    t.integer "num_d0",                :default => 0
    t.integer "num_d1",                :default => 0
    t.integer "num_d2",                :default => 0
    t.integer "num_d3",                :default => 0
    t.integer "num_d4",                :default => 0
    t.integer "num_d5",                :default => 0
    t.integer "num_d6",                :default => 0
    t.integer "num_d7",                :default => 0
    t.integer "num_d8",                :default => 0
    t.integer "num_d9",                :default => 0
    t.integer "num_d10",               :default => 0
    t.integer "num_d11",               :default => 0
    t.integer "num_d12",               :default => 0
    t.integer "num_d13",               :default => 0
    t.integer "num_d14",               :default => 0
    t.integer "num_d15",               :default => 0
    t.integer "num_d16",               :default => 0
    t.integer "num_d17",               :default => 0
    t.integer "num_d18",               :default => 0
    t.integer "num_d19",               :default => 0
    t.integer "num_d20",               :default => 0
    t.integer "num_d21",               :default => 0
    t.integer "num_d22",               :default => 0
    t.integer "num_d23",               :default => 0
    t.integer "num_d24",               :default => 0
    t.integer "num_d25",               :default => 0
    t.integer "num_d26",               :default => 0
    t.integer "num_d27",               :default => 0
    t.integer "num_d28",               :default => 0
    t.integer "num_d29",               :default => 0
    t.integer "num_d30",               :default => 0
    t.integer "num_d90",               :default => 0
  end

  add_index "user_sdk_retention_reports", ["date", "sdk"], :name => "index_user_sdk_retention_reports_on_date_and_sdk", :unique => true
  add_index "user_sdk_retention_reports", ["sdk"], :name => "index_user_sdk_retention_reports_on_sdk"

  create_table "user_zone_id_activity_reports", :force => true do |t|
    t.date    "date",                    :null => false
    t.integer "zone_id",  :default => 0
    t.integer "total",    :default => 0
    t.integer "num_m5",   :default => 0
    t.integer "num_m10",  :default => 0
    t.integer "num_m15",  :default => 0
    t.integer "num_m20",  :default => 0
    t.integer "num_m25",  :default => 0
    t.integer "num_m30",  :default => 0
    t.integer "num_m35",  :default => 0
    t.integer "num_m40",  :default => 0
    t.integer "num_m45",  :default => 0
    t.integer "num_m50",  :default => 0
    t.integer "num_m55",  :default => 0
    t.integer "num_m60",  :default => 0
    t.integer "num_m120", :default => 0
    t.integer "num_m180", :default => 0
    t.integer "num_m300", :default => 0
    t.integer "m300plus", :default => 0
  end

  add_index "user_zone_id_activity_reports", ["date", "zone_id"], :name => "index_user_zone_id_activity_reports_on_date_and_zone_id", :unique => true
  add_index "user_zone_id_activity_reports", ["zone_id"], :name => "index_user_zone_id_activity_reports_on_zone_id"

  create_table "user_zone_id_retention_reports", :force => true do |t|
    t.date    "date",                   :null => false
    t.integer "zone_id", :default => 0
    t.integer "num_d0",  :default => 0
    t.integer "num_d1",  :default => 0
    t.integer "num_d2",  :default => 0
    t.integer "num_d3",  :default => 0
    t.integer "num_d4",  :default => 0
    t.integer "num_d5",  :default => 0
    t.integer "num_d6",  :default => 0
    t.integer "num_d7",  :default => 0
    t.integer "num_d8",  :default => 0
    t.integer "num_d9",  :default => 0
    t.integer "num_d10", :default => 0
    t.integer "num_d11", :default => 0
    t.integer "num_d12", :default => 0
    t.integer "num_d13", :default => 0
    t.integer "num_d14", :default => 0
    t.integer "num_d15", :default => 0
    t.integer "num_d16", :default => 0
    t.integer "num_d17", :default => 0
    t.integer "num_d18", :default => 0
    t.integer "num_d19", :default => 0
    t.integer "num_d20", :default => 0
    t.integer "num_d21", :default => 0
    t.integer "num_d22", :default => 0
    t.integer "num_d23", :default => 0
    t.integer "num_d24", :default => 0
    t.integer "num_d25", :default => 0
    t.integer "num_d26", :default => 0
    t.integer "num_d27", :default => 0
    t.integer "num_d28", :default => 0
    t.integer "num_d29", :default => 0
    t.integer "num_d30", :default => 0
    t.integer "num_d90", :default => 0
  end

  add_index "user_zone_id_retention_reports", ["date", "zone_id"], :name => "index_user_zone_id_retention_reports_on_date_and_zone_id", :unique => true
  add_index "user_zone_id_retention_reports", ["zone_id"], :name => "index_user_zone_id_retention_reports_on_zone_id"

  create_table "vip_level_report", :force => true do |t|
    t.integer "zone_id",                :default => 0
    t.string  "sdk",      :limit => 50,                :null => false
    t.string  "platform", :limit => 10,                :null => false
    t.date    "date",                                  :null => false
    t.integer "level",                  :default => 1
    t.integer "num",                    :default => 0
  end

  add_index "vip_level_report", ["date", "zone_id", "sdk", "platform"], :name => "index_vip_level_report_on_date_and_zone_id_and_sdk_and_platform"

  create_table "vip_purchase", :force => true do |t|
    t.integer "zone_id",                :default => 0
    t.string  "sdk",      :limit => 50,                :null => false
    t.string  "platform", :limit => 10,                :null => false
    t.date    "date"
    t.string  "tid",                                   :null => false
    t.integer "players",                :default => 0
    t.integer "consume",                :default => 0
    t.integer "num",                    :default => 0
  end

  add_index "vip_purchase", ["sdk", "platform", "zone_id"], :name => "index_vip_purchase_on_sdk_and_platform_and_zone_id"

  create_table "vip_purchase_report", :force => true do |t|
    t.integer "zone_id",                :default => 0
    t.string  "sdk",      :limit => 50,                :null => false
    t.string  "platform", :limit => 10,                :null => false
    t.date    "date"
    t.string  "tid",                                   :null => false
    t.integer "players",                :default => 0
    t.integer "consume",                :default => 0
    t.integer "num",                    :default => 0
  end

  add_index "vip_purchase_report", ["sdk", "platform", "zone_id"], :name => "index_vip_purchase_report_on_sdk_and_platform_and_zone_id"

  create_table "zone_accounts", :force => true do |t|
    t.string   "sid",                   :limit => 50,                    :null => false
    t.integer  "zone_id",                             :default => 1
    t.string   "platform",              :limit => 10, :default => "ios"
    t.string   "market",                :limit => 50
    t.string   "sdk",                   :limit => 50
    t.date     "reg_date"
    t.datetime "last_login_at"
    t.datetime "last_logout_at"
    t.integer  "login_times",                         :default => 0
    t.integer  "total_login_times",                   :default => 0
    t.integer  "active_days",                         :default => 0
    t.integer  "active_secs",                         :default => 0
    t.integer  "total_active_secs",                   :default => 0
    t.integer  "level",                               :default => 1
    t.integer  "coins",                 :limit => 8,  :default => 0
    t.integer  "credits",               :limit => 8,  :default => 0
    t.integer  "money",                 :limit => 8,  :default => 0
    t.integer  "vip_level",                           :default => 0
    t.integer  "login_days_count",                    :default => 0
    t.integer  "continuous_login_days",               :default => 0
    t.string   "level_group"
  end

  add_index "zone_accounts", ["last_login_at", "active_secs"], :name => "index_zone_accounts_on_last_login_at_and_active_secs"
  add_index "zone_accounts", ["last_login_at", "zone_id"], :name => "index_zone_accounts_on_last_login_at_and_zone_id"
  add_index "zone_accounts", ["last_login_at"], :name => "index_zone_accounts_on_last_login_at"
  add_index "zone_accounts", ["market"], :name => "index_zone_accounts_on_market"
  add_index "zone_accounts", ["platform"], :name => "index_zone_accounts_on_platform"
  add_index "zone_accounts", ["reg_date", "last_login_at", "market"], :name => "index_zone_accounts_on_reg_date_and_last_login_at_and_market"
  add_index "zone_accounts", ["reg_date", "last_login_at", "platform"], :name => "index_zone_accounts_on_reg_date_and_last_login_at_and_platform"
  add_index "zone_accounts", ["reg_date", "last_login_at", "sdk"], :name => "index_zone_accounts_on_reg_date_and_last_login_at_and_sdk"
  add_index "zone_accounts", ["reg_date", "last_login_at", "zone_id"], :name => "index_zone_accounts_on_reg_date_and_last_login_at_and_zone_id"
  add_index "zone_accounts", ["reg_date", "last_login_at"], :name => "index_zone_accounts_on_reg_date_and_last_login_at"
  add_index "zone_accounts", ["reg_date"], :name => "index_zone_accounts_on_reg_date"
  add_index "zone_accounts", ["sdk"], :name => "index_zone_accounts_on_sdk"
  add_index "zone_accounts", ["sid", "zone_id"], :name => "index_zone_accounts_on_sid_and_zone_id", :unique => true
  add_index "zone_accounts", ["zone_id"], :name => "index_zone_accounts_on_zone_id"

  create_table "zone_devices", :force => true do |t|
    t.string   "sid",               :limit => 70,                :null => false
    t.integer  "zone_id",                         :default => 1
    t.string   "market",            :limit => 50
    t.string   "sdk",               :limit => 50
    t.string   "platform",          :limit => 10
    t.date     "reg_date"
    t.datetime "last_login_at"
    t.datetime "last_logout_at"
    t.integer  "active_secs",                     :default => 0
    t.integer  "total_active_secs",               :default => 0
    t.integer  "active_days",                     :default => 0
  end

  add_index "zone_devices", ["last_login_at", "active_secs"], :name => "index_zone_devices_on_last_login_at_and_active_secs"
  add_index "zone_devices", ["last_login_at", "zone_id"], :name => "index_zone_devices_on_last_login_at_and_zone_id"
  add_index "zone_devices", ["last_login_at"], :name => "index_zone_devices_on_last_login_at"
  add_index "zone_devices", ["market"], :name => "index_zone_devices_on_market"
  add_index "zone_devices", ["platform"], :name => "index_zone_devices_on_platform"
  add_index "zone_devices", ["reg_date", "last_login_at", "market"], :name => "index_zone_devices_on_reg_date_and_last_login_at_and_market"
  add_index "zone_devices", ["reg_date", "last_login_at", "platform"], :name => "index_zone_devices_on_reg_date_and_last_login_at_and_platform"
  add_index "zone_devices", ["reg_date", "last_login_at", "sdk"], :name => "index_zone_devices_on_reg_date_and_last_login_at_and_sdk"
  add_index "zone_devices", ["reg_date", "last_login_at", "zone_id"], :name => "index_zone_devices_on_reg_date_and_last_login_at_and_zone_id"
  add_index "zone_devices", ["reg_date", "last_login_at"], :name => "index_zone_devices_on_reg_date_and_last_login_at"
  add_index "zone_devices", ["reg_date"], :name => "index_zone_devices_on_reg_date"
  add_index "zone_devices", ["sdk"], :name => "index_zone_devices_on_sdk"
  add_index "zone_devices", ["sid", "zone_id"], :name => "index_game_devices_on_device_id_and_zone_id", :unique => true
  add_index "zone_devices", ["zone_id"], :name => "index_zone_devices_on_zone_id"

  create_table "zone_users", :force => true do |t|
    t.string   "sid",                   :limit => 50,                    :null => false
    t.integer  "zone_id",                             :default => 1
    t.string   "platform",              :limit => 10, :default => "ios"
    t.string   "market",                :limit => 50
    t.string   "sdk",                   :limit => 50
    t.date     "reg_date"
    t.datetime "last_login_at"
    t.datetime "last_logout_at"
    t.integer  "login_times",                         :default => 0
    t.integer  "total_login_times",                   :default => 0
    t.integer  "active_days",                         :default => 0
    t.integer  "active_secs",                         :default => 0
    t.integer  "total_active_secs",                   :default => 0
    t.integer  "level",                               :default => 1
    t.integer  "coins",                 :limit => 8,  :default => 0
    t.integer  "credits",               :limit => 8,  :default => 0
    t.integer  "money",                 :limit => 8,  :default => 0
    t.integer  "vip_level",                           :default => 0
    t.integer  "login_days_count",                    :default => 0
    t.integer  "continuous_login_days",               :default => 0
    t.string   "level_group"
  end

  add_index "zone_users", ["last_login_at", "active_secs"], :name => "index_zone_users_on_last_login_at_and_active_secs"
  add_index "zone_users", ["last_login_at", "zone_id"], :name => "index_zone_users_on_last_login_at_and_zone_id"
  add_index "zone_users", ["last_login_at"], :name => "index_zone_users_on_last_login_at"
  add_index "zone_users", ["market"], :name => "index_zone_users_on_market"
  add_index "zone_users", ["platform"], :name => "index_zone_users_on_platform"
  add_index "zone_users", ["reg_date", "last_login_at", "market"], :name => "index_zone_users_on_reg_date_and_last_login_at_and_market"
  add_index "zone_users", ["reg_date", "last_login_at", "platform"], :name => "index_zone_users_on_reg_date_and_last_login_at_and_platform"
  add_index "zone_users", ["reg_date", "last_login_at", "sdk"], :name => "index_zone_users_on_reg_date_and_last_login_at_and_sdk"
  add_index "zone_users", ["reg_date", "last_login_at", "zone_id"], :name => "index_zone_users_on_reg_date_and_last_login_at_and_zone_id"
  add_index "zone_users", ["reg_date", "last_login_at"], :name => "index_zone_users_on_reg_date_and_last_login_at"
  add_index "zone_users", ["reg_date"], :name => "index_zone_users_on_reg_date"
  add_index "zone_users", ["sdk"], :name => "index_zone_users_on_sdk"
  add_index "zone_users", ["sid", "zone_id"], :name => "index_zone_users_on_sid_and_zone_id", :unique => true
  add_index "zone_users", ["zone_id"], :name => "index_zone_users_on_zone_id"

  create_table "zones", :force => true do |t|
    t.integer "zone_id", :default => 0
  end

  add_index "zones", ["zone_id"], :name => "index_zones_on_zone_id", :unique => true

end
