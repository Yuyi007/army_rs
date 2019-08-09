Gm::Application.routes.draw do


  get "limit_event/list"
  get "limit_event/edit"
  get "limit_event/new"
  get "limit_event/delete"
  post "limit_event/create"
  post "limit_event/update"

  get "normal_event/list"
  get "normal_event/edit"
  get "normal_event/new"
  get "normal_event/delete"
  post "normal_event/create"
  post "normal_event/update"

  get "events_campaign_exp/list"

  get "cdkeys/index"
  get "cdkeys/search"
  get "cdkeys/manage"
  post "cdkeys/generate"
  post "cdkeys/process_redeemed_cdkeys"
  post "cdkeys/import_from_local"
  post "cdkeys/import"
  post "cdkeys/export_all"

  get "cdkey/index"

  root :to => "application#index"

  match "i18n" => 'application#i18n', :via => :put
  match "logout" => 'user_sessions#destroy', :via => :get

  post 'api/client_version'
  post 'api/maintainance'
  post 'api/list_zones'
  post 'api/list_user_zones'
  post 'api/is_valid_cdkey'
  post 'api/use_cdkey'
  post 'api/list_user_zones'
  post "api/get_game_characters"
  post 'api/process_action_log'
  post 'api/process_redeemed_cdkeys'


  get 'site_users/list'
  match 'site_users/:id/update_super' => 'site_users#update_super', :via => :put
  match 'site_users/:id/update_role' => 'site_users#update_role', :via => :put
  match 'site_users/:id/update_active' => 'site_users#update_active', :via => :put
  match 'site_users/:id/reset_failed_login_count' => 'site_users#reset_failed_login_count', :via => :post
  match 'site_users/:id/edit_role' => 'site_users#edit_role', :via => :get, :as => :edit_site_user_role
  match 'site_users/:id/edit_active' => 'site_users#edit_active', :via => :get, :as => :edit_site_user_active
  match 'site_users/:id/edit_super(.:format)' => 'site_users#edit_super', :via => :get, :as => :edit_site_user_super
  match 'site_users/:id/deliver_verification_instructions' => 'site_users#deliver_verification_instructions', :via => :post, :as => :deliver_verification_instructions
  match 'site_users/:id/skip_verification' => 'site_users#skip_verification', :via => :post, :as => :skip_verification
  match 'site_user_verification/:token' => 'site_user_verification#show', :via => :get, :as => :site_user_verification
  get 'site_user_records/index'
  get 'site_user_records/search'

  get 'notif_alerts/list', :as => :list_notif_alerts
  post 'notif_alerts/check_all' => 'notif_alerts#check_all', :as => :check_notif_alert_all
  match 'notif_alerts/:id/edit' => 'notif_alerts#edit', :via => :get, :as => :edit_notif_alert
  post 'notif_alerts/:id/check' => 'notif_alerts#check', :as => :check_notif_alert

  get 'notif_receivers/list', :as => :list_notif_receivers
  match 'notif_receivers/:id/edit' => 'notif_receivers#edit', :via => :get, :as => :edit_notif_receiver

  match 'grant_records/grant'  => 'grant_records#grant', :via => :post
  match 'grant_records/reject' => 'grant_records#reject', :via => :post
  match 'grant_records/old_requests' => 'grant_records#old_requests', :via => :get
  resources :grant_records

  get 'wldh/list'
  match 'wldh/:id/stages/:stage' => 'wldh#show_stages', :via => :get, :as => :stages_wldh
  match 'wldh/:id/stages/:stage/:zone/:player_id' => 'wldh#show_stages_player', :via => :get, :as => :stages_player_wldh
  match 'wldh/:id/stages/:stage/fights/:mode/:fight_id' => 'wldh#show_stages_fight', :via => :get, :as => :stages_fight_wldh
  match 'wldh/:id/activate' => 'wldh#activate', :via => :post, :as => :activate_wldh
  match 'wldh/:id/boost' => 'wldh#boost', :via => :post, :as => :boost_wldh
  match 'wldh/:id/enroll' => 'wldh#enroll', :via => :post, :as => :enroll_wldh
  match 'wldh/:id/reset_stages' => 'wldh#reset_stages', :via => :post, :as => :reset_wldh_stages
  match 'wldh/grant/:id/:grant' => 'wldh#grant', :via => :post, :as => :grant_wldh
  match 'wldh/viewWulinRanks' => 'wldh#viewWulinRanks', :via => :get

  get 'data_query/index'
  post 'data_query/cache'
  post 'data_query/debug'
  post 'data_query/submit'
  match 'data_query/log/:id' => 'data_query#showlog', :via => :get
  match 'data_query/log/:id' => 'data_query#deletelog', :via => :delete

  match 'cdkey/queryKey/:key' => 'cdkey#queryKey', :via => :get

  resources :user_sessions
  resources :site_users
  resources :site_user_records
  resources :notif_alerts
  resources :notif_receivers
  resources :wldh

  get 'client_version/index'
  get 'client_version/edit'
  post 'client_version/publish'

  get 'app_version/index'
  get 'app_version/edit'
  post 'app_version/publish'

  get 'zone/index'
  post 'zone/saveNumOpenZones'

  get 'maintainance/index'
  post 'maintainance/update'

  get 'gm_pay/index'
  post 'gm_pay/add'
  # post 'maintainance/saveOnMaintainance'
  # match 'maintainance/status/:location' => 'maintainance#status'

  get 'server_settings/index'
  post 'server_settings/dev_mode'
  post 'server_settings/save'
  post 'server_settings/delete'
  post 'server_settings/reload_server_list'
  post 'server_settings/garbage_collect_all'

  get 'zone_settings/index'
  post 'zone_settings/save'
  post 'zone_settings/open_zone_auto_set'
  post 'zone_settings/restore_default_settings'
  post 'zone_settings/delete'

  get 'queuing_settings/index'
  post 'queuing_settings/save'
  post 'queuing_settings/delete'

  get "bills/index"
  get "bills/search"
  get 'bills/total'
  get 'bills/low_search'

  get 'data/view'
  get 'data/player'
  get 'data/give'
  get "/data/query_guild"
  post "/data/guild_search"
  
  get 'editdata/edit'

  match 'actionlog' => 'data#actionlog', :via => :get
  match 'actionlogSpecial' => 'data#actionlogSpecial', :via => :get

  get "wushuplayer/raw"
  get "wushuplayer/load"

  get "action_logs/index"
  get "action_logs/search"
  get "action_logs/manage"
  post "action_logs/delete_old"
  post "action_logs/process_remain_logs"

  get "elastic_action_log/index"
  get "elastic_action_log/search"

  get "anti_cheat/index"
  get "anti_cheat/search_cheater", :as => :search_cheater
  post "anti_cheat/add_cheater", :as => :add_cheater
  post "anti_cheat/del_cheater", :as => :del_cheater
  post "anti_cheat/clear_cheaters", :as => :clear_cheaters
  get "anti_cheat/search_monitor", :as => :search_monitor
  post "anti_cheat/add_monitor", :as => :add_monitor
  post "anti_cheat/del_monitor", :as => :del_monitor
  post "anti_cheat/clear_monitors", :as => :clear_monitors

  match 'archive/:zone/:id' => 'archive#find', :via => :get, :as => :archive_find
  match 'archive/:zone/:id/:time' => 'archive#load', :via => :get, :as => :archive_view
  match 'archive/:zone/:id/:time/delete' => 'archive#delete', :via => :post, :as => :archive_delete

  get 'config/complete/:type' => 'config#complete'

  match 'archive/:zone/:id' => 'archive#find', :via => :get, :as => :archive_find
  match 'archive/:zone/:id/:time' => 'archive#load', :via => :get, :as => :archive_view
  match 'archive/:zone/:id/:time/delete' => 'archive#delete', :via => :post, :as => :archive_delete

  get 'data/view'
  get 'data/history'
  get 'data/raw'
  get 'data/give'
  get 'data_batch/edit'
  post 'data_batch/save'
  post 'data_batch/batch_save'

  match 'data/:zone/:id' => 'data#load', :via => :get
  match 'data/:zone/:id/json' => 'data#export', :via => :get
  match 'data/:zone/:id/json' => 'data#import', :via => :put
  match 'data/:zone/:id' => 'data#save', :via => :put
  match 'data/:zone/:id' => 'data#delete', :via => :delete

  post "player/set_permission"
  post "player/permission_list"
  post "player/get_permission"
  post "player/get_block_detail"
  post "player/unlock_block"
  post "player/set_player_permission"
  get "player/index"
  match "player/:zone/:name" => 'player#byName', :via => :get
  match "player/kick/:zone/:id" => 'player#kick', :via => :post


  get "user/index"
  post "user/query"
  post "user/query_player"
  match "user/by_email" => 'guser#by_email', :via => :get
  match "user/:id" => 'guser#by_id', :via => :get

  match 'permissions' => 'permissions#show', :via => :get
  match 'permissions/create' => 'permissions#create', :via => :post, :as => :permissions_create
  match 'permissions/update' => 'permissions#update', :via => :post, :as => :permissions_update
  match 'permissions/delete' => 'permissions#destroy', :via => :post, :as => :permissions_delete
  match 'permissions/sort' => 'permissions#sort', :via => :post, :as => :permissions_sort

  get "channel/index"
  post "channel/notice"
  post "channel/chat"
  post "channel/add_chat_schedule"
  post "channel/remove_chat_schedule"

  get "sms/index"

  get "events_zhaoxian/index"
  get "events_zhaoxian/list"
  get "events_zhaoxian/new"
  get "events_zhaoxian/edit"
  post 'events_zhaoxian/create_zhaoxian'
  post 'events_zhaoxian/update'
  match "events_zhaoxian/delete" => 'events_zhaoxian#delete_zhaoxian', :via => :post
  post "events_zhaoxian/delete_zhaoxian"
  match 'events_zhaoxian/copy/:zone/:id/' => 'events_zhaoxian#copy', :via => :post
  match 'events_zhaoxian/:zone/copy_list' => 'events_zhaoxian#copy_list', :via => :post

  get "events_campaign_exp/index"
  get "events_campaign_exp/list"
  get "events_campaign_exp/new"
  get "events_campaign_exp/edit"
  post 'events_campaign_exp/create_campaign_exp'
  post 'events_campaign_exp/update'
  match "events_campaign_exp/delete" => 'events_campaign_exp#delete_campaign_exp', :via => :post
  post "events_campaign_exp/delete_campaign_exp"
  match 'events_campaign_exp/copy/:zone/:id/' => 'events_campaign_exp#copy', :via => :post
  match 'events_campaign_exp/:zone/copy_list' => 'events_campaign_exp#copy_list', :via => :post

  get "events_zonemarket/index"
  get "events_zonemarket/list"
  get "events_zonemarket/new"
  get "events_zonemarket/edit"
  post 'events_zonemarket/create_zonemarket'
  post 'events_zonemarket/update'
  match "events_zonemarket/delete" => 'events_zonemarket#delete_zonemarket', :via => :post
  post "events_zonemarket/delete_zonemarket"
  match 'events_zonemarket/copy/:zone/:id/' => 'events_zonemarket#copy', :via => :post
  match 'events_zonemarket/:zone/copy_list' => 'events_zonemarket#copy_list', :via => :post

  get "events_soul/index"
  get 'events_soul/list'
  match 'events_soul/new' => 'events_soul#new', :via => :get
  match 'events_soul/edit/:zone/:id' => 'events_soul#edit', :via => :get
  match 'events_soul/get_events/:zone' => 'events_soul#get_list', :via => :get
  match 'events_soul/get/:zone/:id' => 'events_soul#get', :via => :get
  match 'events_soul/create/:zone' => 'events_soul#create', :via => :post
  match 'events_soul/:zone/copy_list' => 'events_soul#copy_list', :via => :post
  match 'events_soul/save/:zone/:id' => 'events_soul#save', :via => :post
  match 'events_soul/delete/:zone/:id' => 'events_soul#delete', :via => :post
  match 'events_soul/copy/:zone/:id/' => 'events_soul#copy', :via => :post

  get "events_raid/list"
  match 'events_raid/getEvents' => 'events_raid#getEvents', :via => :get
  match 'events_raid/history' => 'events_raid#history', :via => :get
  match 'events_raid/getHistories/:zone' => 'events_raid#getHistories', :via => :get
  match 'events_raid/new' => 'events_raid#new', :via => :get
  match 'events_raid/create' => 'events_raid#create', :via => :post
  match 'events_raid/getEvent/:zone' => 'events_raid#getEvent', :via => :get
  match 'events_raid/edit/:zone' => 'events_raid#edit', :via => :get
  match 'events_raid/save' => 'events_raid#save', :via => :post
  match 'events_raid/delete/:zone' => 'events_raid#deleteEvent', :via => :post
  match 'events_raid/getCreatedZones' => 'events_raid#getCreatedZones', :via => :get
  match 'events_raid/deleteBatch/' => 'events_raid#deleteBatch', :via => :post
  match 'events_raid/accelerate/:zone' => 'events_raid#accelerate', :via => :get
  
  #get "events_campaigndrop/index"
  get "events_campaigndrop/list"
  match 'events_campaigndrop/save_campaign_drop/:zone/:id' => 'events_campaigndrop#save', :via => :post
  match 'events_campaigndrop/get_campaign_drop/:zone/:id' => 'events_campaigndrop#get', :via => :get
  match 'events_campaigndrop/copy_campaign_drop/:zone/:id/copy' => 'events_campaigndrop#copy', :via => :post
  match 'events_campaigndrop/edit/:zone/:id' => 'events_campaigndrop#edit', :via => :get
  match 'events_campaigndrop/new' => 'events_campaigndrop#new', :via => :get
  match 'events_campaigndrop/getEvents/:zone' => 'events_campaigndrop#get_list', :via => :get
  match 'events_campaigndrop/:zone/copys' => 'events_campaigndrop#copy_list', :via => :post
  match 'events_campaigndrop/create/:zone' => 'events_campaigndrop#create', :via => :post
  match 'events_campaigndrop/delete/:zone/:id' => 'events_campaigndrop#delete', :via => :post
  match 'events_campaigndrop/grant/:eventType' => 'events_campaigndrop#grant', :via => :post
  match 'events_campaigndrop/reject/:eventType' => 'events_campaigndrop#reject', :via => :post

  get "mysteryshop/shoplist"
  match "mysteryshop/getshoplist/:zone" => 'mysteryshop#getshoplist', :via => :get
  match "mysteryshop/edit/:zone/:npc" => 'mysteryshop#edit', :via => :get
  match "mysteryshop/edit" => 'mysteryshop#edit', :via => :get
  match "mysteryshop/save" => 'mysteryshop#save', :via => :post
  match "mysteryshop/start/:zone/:npc" => 'mysteryshop#start', :via => :get
  match "mysteryshop/remove/:zone/:npc" => 'mysteryshop#remove', :via => :get

  get  "booth/list"
  get  "booth/group_list"
  get  "booth/edit_group"
  post "booth/save_group"
  post "booth/delete_group"
  post "booth/frozen_goods"
  post "booth/unfrozen_goods"
  post "booth/remove_goods"

  get "person/view_base"
  match 'person/:pid/:curPage/view_avatar(.:format)' => 'person#view_avatar', :via => :get, :as => :person_view_avatar
  match 'person/:pid/:curPage/view_unread_message_senders(.:format)' => 'person#view_unread_message_senders', :via => :get, :as => :person_view_unread_message_senders
  match 'person/:pid/:curPage/view_followers(.:format)' => 'person#view_followers', :via => :get, :as => :person_view_followers
  match 'person/:pid/:curPage/view_following(.:format)' => 'person#view_following', :via => :get, :as => :person_view_following
  match 'person/:pid/:curPage/view_blocklist(.:format)' => 'person#view_blocklist', :via => :get, :as => :person_view_blocklist
  match 'person/:pid/:curPage/view_followed(.:format)' => 'person#view_followed', :via => :get, :as => :person_view_followed
  match 'person/:pid/:curPage/view_npcs(.:format)' => 'person#view_npcs', :via => :get, :as => :person_view_npcs
  match 'person/:pid/:curPage/view_recent_contacts(.:format)' => 'person#view_recent_contacts', :via => :get, :as => :person_view_recent_contacts
  match 'person/:pid/:curPage/view_timeline(.:format)' => 'person#view_timeline', :via => :get, :as => :person_view_timeline
  match 'person/:pid/:curPage/view_tweets(.:format)' => 'person#view_tweets', :via => :get, :as => :person_view_tweets
  match 'person/:pid/:curPage/view_news_tweets(.:format)' => 'person#view_news_tweets', :via => :get, :as => :person_view_news_tweets
  match 'person/:pid/:id/:curPage/view_tweet_bonus(.:format)' => 'person#view_tweet_bonus', :via => :get, :as => :tweet_view_bonus
  match 'person/:pid/:id/:curPage/view_tweet_bonus_commenters(.:format)' => 'person#view_tweet_bonus_commenters', :via => :get, :as => :tweet_view_bonus_commenters
  match 'person/:pid/:id/:curPage/view_tweet_bonus_liked(.:format)' => 'person#view_tweet_bonus_liked', :via => :get, :as => :tweet_view_bonus_liked
  match 'person/:pid/:id/:curPage/view_tweet_comments(.:format)' => 'person#view_tweet_comments', :via => :get, :as => :tweet_view_comments

  get "rewards/packagelist"
  get "rewards/storelist"
  get 'rewards/packageedit'
  get 'rewards/storeedit'
  get "rewards/packagenew"
  get "rewards/storenew"
  get 'rewards/getPackage'
  get 'rewards/getStore'
  match 'rewards/getPackage/:id' => 'rewards#getPackage', :via => :get
  match 'rewards/createPackage' => 'rewards#createPackage', :via => :post
  match 'rewards/updatePackage' => 'rewards#updatePackage', :via => :post
  match 'rewards/deletePackage/:id' => 'rewards#deletePackage', :via => :delete
  match 'rewards/exportPackage/:id' => 'rewards#exportPackage', :via => :get
  match 'rewards/exportStoreItem/:tid' => 'rewards#exportStoreItem', :via => :get
  match 'rewards/importPackage' => 'rewards#importPackage', :via => :post
  match 'rewards/importStoreItem' => 'rewards#importStoreItem', :via => :post
  match 'rewards/getStore/:tid' => 'rewards#getStore', :via => :get
  match 'rewards/createStore' => 'rewards#createStore', :via => :post
  match 'rewards/updateStore' => 'rewards#updateStore', :via => :post
  match 'rewards/deleteStore/:tid' => 'rewards#deleteStore', :via => :delete
  match 'rewards/grant/:tid' => 'rewards#grantStore', :via => :post
  match 'rewards/reject/:tid' => 'rewards#rejectStore', :via => :post
  resources :rewards

  get "functions/index"
  match 'functions/cantloss/:zone' => 'functions#isCantLossOpen', :via => :get
  match 'functions/cantloss/:zone' => 'functions#setCantLossOpen', :via => :post

  match 'functions/arenabonus/:zone' => 'functions#isArenaBonusOpen', :via => :get
  match 'functions/arenabonus/:zone' => 'functions#setArenaBonusOpen', :via => :post

  match 'functions/yunbiao' => 'functions#isYunbiaoOpen', :via => :get
  match 'functions/yunbiao' => 'functions#setYunbiaoOpen', :via => :post

  get "rank/index"
  match 'rank/xuezhanRank' => 'rank#getList', :via => :get


  get "rank/cantloss"
  match 'rank/cantlossRank' => 'rank#getCantlossList', :via => :get
  match 'rank/cantlossResult' => 'rank#getCantlossResult', :via => :get

  get "rank/yunbiao"
  match 'rank/yunbiaoResult' => 'rank#getYunbiaoResult', :via => :get

  get "notice/list"
  get "notice/delete"
  get "notice/edit"
  post "notice/update"
  post "notice/create"
  get "notice/new"
  post "notice/mailNotice"
  post "notice/deleteAll"


  get "wushu/list"
  get "wushu/delete"
  get "wushu/edit"
  post "wushu/update"
  post "wushu/create"
  get "wushu/new"

  get "online/index"
  post "online/fix"
  post "online/clear"

  get "push/index"
  post "push/apple"

  match "user_level/:zone/:id" => 'user_level#query', :via => :get
  match "user_id/:zone/:name" => 'user_id#query', :via => :get
  match "user_level" => 'user_level#query2', :via=>:get
  match "user_query" => 'user_level#query2', :via=>:get

  get  "mail/index"
  post "mail/send_mail"

  get "check_payment_item_packages/index"
  get "check_payment_item_packages/:tid" => "check_payment_item_packages#content"
  get "check_payment_item_packages/package/:tid" => "check_payment_item_packages#package"
  get "check_payment_item_packages/item/:tid" => "check_payment_item_packages#item"
  match 'check_payment_item_packages/getByDate' => "check_payment_item_packages#getByDate", :via => :post

  get "check_credit_rank_bonus/index"


  get "check_gmarket/index"

  get "events_xuezhan/index"
  get "events_xuezhan/list"
  get "events_xuezhan/new"
  get "events_xuezhan/edit"
  post 'events_xuezhan/create_xuezhan'
  post 'events_xuezhan/update'
  match "events_xuezhan/delete" => 'events_xuezhan#delete_xuezhan', :via => :post
  post "events_xuezhan/delete_xuezhan"
  match 'events_xuezhan/copy/:zone/:id/' => 'events_xuezhan#copy', :via => :post
  match 'events_xuezhan/:zone/copy_list' => 'events_xuezhan#copy_list', :via => :post

  get "events_credit/index"
  get "events_credit/list"
  get "events_credit/ranking"
  get "events_credit/new"
  get "events_credit/edit"
  post 'events_credit/create_credit'
  post 'events_credit/update'
  match "events_credit/delete" => 'events_credit#delete_credit', :via => :post
  post "events_credit/delete_credit"
  match 'events_credit/copy/:zone/:id/' => 'events_credit#copy', :via => :post
  match 'events_credit/:zone/copy_list' => 'events_credit#copy_list', :via => :post

  get "test_assist/skill_tools"
  match 'test_assist/unlock_all_skills' => 'test_assist#unlock_all_skills', :via => :post

  get "test_assist/pass_campaign"
  match 'test_assist/do_pass_campaign' => 'test_assist#do_pass_campaign', :via => :post

  get "test_assist/player_tools"
  match 'test_assist/send_item' => 'test_assist#send_item', :via => :post
  match 'test_assist/send_ability_items' => 'test_assist#send_ability_gifts', :via => :post
  match 'test_assist/send_gift_items' => 'test_assist#send_gifts', :via => :post
  match 'test_assist/send_equip' => 'test_assist#send_equip', :via => :post
  match 'test_assist/clear_bag' => 'test_assist#clear_bag', :via => :post
  match 'test_assist/reset_position' => 'test_assist#reset_position', :via => :post
  match 'test_assist/set_credit' => 'test_assist#set_credit', :via => :post
  match 'test_assist/set_energy' => 'test_assist#set_energy', :via => :post
  match 'test_assist/send_debug_suit' => 'test_assist#send_debug_suit', :via => :post
  match 'test_assist/notify_upload_log' => 'test_assist#notify_upload_log', :via => :post
  match 'test_assist/show_auto_log' => 'test_assist#show_auto_log', :via => :post
  match 'test_assist/send_do_drop' => 'test_assist#send_do_drop', :via => :post

  get "test_assist/quest_tools"
  match 'test_assist/set_main_quest' => 'test_assist#set_main_quest', :via => :post
  match 'test_assist/add_branch_quest' => 'test_assist#add_branch_quest', :via => :post
  match 'test_assist/add_story_quest' => 'test_assist#add_story_quest', :via => :post
  match 'test_assist/reset_all_quest' => 'test_assist#reset_all_quest', :via => :post
  match 'test_assist/unlock_all' => 'test_assist#unlock_all', :via => :post
  get 'test_assist/all_firevale_ids'
  get 'test_assist/all_chongzhi_ids'


  get "test_assist/city_tools"
  match 'test_assist/skip_to_next_city_time' => 'test_assist#skip_to_next_city_time', :via => :post
  match 'test_assist/clear_city_time_offset' => 'test_assist#clear_city_time_offset', :via => :post
  match 'test_assist/skip_to_next_weather' => 'test_assist#skip_to_next_weather', :via => :post


  get "hot_patch/server_tools"
  match 'hot_patch/patch_ruby_code' => 'hot_patch#patch_ruby_code', :via => :post
  match 'hot_patch/patch_elixir_code' => 'hot_patch#patch_elixir_code', :via => :post
  match 'hot_patch/reload_server_config' => 'hot_patch#reload_server_config', :via => :post

  get "hot_patch/client_tools"
  match 'hot_patch/patch_client_code' => 'hot_patch#patch_client_code', :via => :post
  match 'hot_patch/clear_patch_client_code' => 'hot_patch#clear_patch_client_code', :via => :post

  get "group_mail/list"
  match 'group_mail/save/:id' => 'group_mail#save', :via => :post
  match 'group_mail/get_mail/:id' => 'group_mail#get_mail', :via => :get
  match 'group_mail/edit/:id' => 'group_mail#edit', :via => :get
  match 'group_mail/new' => 'group_mail#new', :via => :get
  match 'group_mail/get_mails' => 'group_mail#get_mails', :via => :get
  match 'group_mail/create' => 'group_mail#create', :via => :post
  match 'group_mail/delete/:id' => 'group_mail#delete', :via => :post
  match 'group_mail/saveIndex' => 'group_mail#save_index', :via => :post
  match 'group_mail/publish/:id' => 'group_mail#publish', :via => :post

  get   "matching_pools/list"
  get   "matching_pools/new"
  get   "matching_pools/edit"
  post  "matching_pools/save"
  post  "matching_pools/delete"

  get "control_matching_pools/index"
  post "control_matching_pools/list"
  post "control_matching_pools/set_matching_close_status"
  post "control_matching_pools/set_create_room_status"

  get "control_combat/index"
  post "control_combat/list"
  post "control_combat/get_zone_online_num"

  # The priority is based upon order of creation:
  # first created -> highest priority.

  # Sample of regular route:
  #   match 'products/:id' => 'catalog#view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   match 'products/:id/purchase' => 'catalog#purchase', :as => :purchase
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Sample resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Sample resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Sample resource route with more complex sub-resources
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', :on => :collection
  #     end
  #   end

  # Sample resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end

  # You can have the root of your site routed with "root"
  # just remember to delete public/index.html.
  # root :to => 'welcome#index'

  # See how all your routes lay out with "rake routes"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id))(.:format)'
end
