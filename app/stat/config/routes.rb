Stat::Application.routes.draw do
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

  get 'users/login'
  post 'users/do_login'
  get 'users/regist'
  post 'users/do_regist'
  post 'users/do_logout'

  get 'users/role_manage'
  post 'users/role_list'
  post 'users/remove_role'
  post 'users/save_role'

  get 'users/right_manage'

  post 'users/func_list'
  post 'users/role_funcs'
  post 'users/save_role_rights'

  get 'users/user_manage'
  post 'users/user_list'
  post 'users/enable_account'
  get 'users/change_role'
  post 'users/do_change_role'


  get 'main/dashboard'
  post 'main/get_rights'

  get 'statsbin/gen_today'
  post 'statsbin/do_gen_today_stats'

  get 'statshelper/level_consume'
  post 'statshelper/get_lv_consume'
  post 'statshelper/get_zones'

  get 'statshelper/consume_report'
  post 'statshelper/get_consume_report'

  post 'statsexport/save_export_data'
  get 'statsexport/export_to_xls'

  get 'statsorign/total_active'
  post 'statsorign/get_total_active'

  get 'statsorign/active_report'
  post 'statsorign/get_active_report'
  post 'statsorign/get_sdk_plats'

  get 'statsorign/retention_report'
  post 'statsorign/get_retention_report'

  get 'statsorign/chief_level_report'
  post 'statsorign/get_chief_level_report'

  get 'statshelper/city_level_report'
  post 'statshelper/get_city_level_report'

  post 'statshelper/get_currency_records'
  get 'statshelper/credits_consume_report'
  get 'statshelper/credits_gain_report'
  get 'statshelper/coins_consume_report'
  get 'statshelper/coins_gain_report'
  get 'statshelper/money_consume_report'
  get 'statshelper/money_gain_report'
  get 'statshelper/voucher_consume_report'
  get 'statshelper/voucher_gain_report'

  get 'statshelper/shop_consume_report'
  post 'statshelper/get_shop_consume'

  get 'statshelper/start_campaign_report'
  get 'statshelper/active_factions_report'

  get 'statshelper/all_factions_report'
  post 'statshelper/get_all_factions_report'

  get 'statshelper/main_quest_cam_report'
  post 'statshelper/get_main_quest_cam'

  get 'statshelper/booth_trade_report'
  post 'statshelper/get_booth_trade'

  get 'realtimestats/new_users_report'
  post 'realtimestats/get_new_user_report'

  get 'realtimestats/active_users_report'
  post 'realtimestats/get_active_user_report'

  get 'realtimestats/max_online_report'
  post 'realtimestats/get_max_online_report'

  get 'realtimestats/ave_online_report'
  post 'realtimestats/get_ave_online_report'

  post 'statsbin/do_check_today_gen'

  get 'statshelper/chapter_quest_report'
  post 'statshelper/get_chapter_request_report'

  get 'statshelper/boss_practice_report'
  post 'statshelper/get_boss_practice_report'

  get 'statshelper/guild_level_record'
  post 'statshelper/get_guild_level_record'

  get 'statshelper/guild_skill_record'
  post 'statshelper/get_guild_skill_record'

  get 'statshelper/guild_active_record'
  post 'statshelper/get_guild_active_record'

  get 'recharge/player_recharge_record'
  post 'recharge/get_player_recharge_record'

  get 'recharge/player_recharge_report'
  post 'recharge/get_player_recharge_report'


  get 'recharge/new_player_recharge_report'
  post 'recharge/get_new_player_recharge_report'

  get 'loss/loss_consume_report'
  post 'loss/get_loss_consume_report'

  get 'loss/loss_recharge_report'
  post 'loss/get_loss_recharge_report'

  get 'statshelper/level_campaign_report'
  post 'statshelper/get_level_campaign_report'

  get 'statshelper/city_campaign_report'
  post 'statshelper/get_city_campaign_report'

  get 'statshelper/all_player_level_report'
  post 'statshelper/get_all_player_level_report'

  get 'statshelper/all_player_city_event_level_report'
  post 'statshelper/get_all_player_city_event_level_report'

  get 'statshelper/add_equip_report'
  post 'statshelper/get_add_equip_report'

  get 'statshelper/campaign_report'
  post 'statshelper/get_campaign_report'  

  get 'statshelper/main_quest_report'
  post 'statshelper/get_main_quest_report'

  get 'statshelper/main_quest_user_report'
  post 'statshelper/get_main_quest_user_report'


  get 'statshelper/vip_level_report'
  post 'statshelper/get_vip_level_report'
    
  get 'statshelper/vip_purchase_report'
  post 'statshelper/get_vip_purchase_report'

  get 'statshelper/share_award_report'
  post 'statshelper/get_share_award_report'

  get 'statshelper/born_quest_report'
  post 'statshelper/get_born_quest_report'
    
  get 'loss/loss_report'
  post 'loss/get_loss_report'
end
