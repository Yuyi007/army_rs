# rs.rb

require 'boot'
include Boot

require 'helpers/math_ext'
# require 'helpers/lua_ext'
require 'helpers/enum'
require 'helpers/time_helper'
require 'helpers/channel_helper'
require 'helpers/checker_rpc'
require 'helpers/tencent_sms'
require 'helper'
require 'cs_router'


require 'config/hash_wrapper'

require 'model/chief'
require 'model/instance_alter'
require 'model/instance'
require 'model/item'
require 'model/vip'
require 'model/record'
require 'model/garage'
require 'model/model'

require 'model/combat/combat_stat'
require 'model/combat/player_combat_stat'
require 'model/combat/combat_record'
require 'model/combat/combat_data'

require 'model/time_stamp_value'
require 'model/car_avatar/avatar_data'
require 'model/car_avatar/avatar_item'
require 'model/car_avatar/car_equipped'
require 'model/car_avatar/equipped_data'

require 'model/recharge/recharge_record'
require 'model/recharge/growth_fund'
require 'model/recharge/month_card'


require 'db/events/game_event'
require 'db/events/eventable'
require 'db/events/configurable'
require 'db/events/game_events_db'

require 'db/yousi_player_manager'
require 'db/player'
require 'db/anti_manipulation_db'
require 'db/anti_cheat_db'
require 'db/pay_db'
require 'db/pay_order'
require 'db/player_zones'
require 'db/channel'
require 'db/notify_center'

require 'db/game_data_model'
require 'db/client_hot_patch_db'

require 'db/mail/mail_box'
require 'db/mail/group_mail_db'
require 'db/mail/mail_content'

require "db/permission/permission_db"

require 'db/periodic_update'
require 'db/stats/stats_db'

require 'db/gm/schedule_chat'
require 'db/gm/schedule_chat_db'

#race combat
require 'db/combat/combat_server_db'
require 'db/combat/combat_player_data'
require 'db/combat/room_info'
require 'db/combat/combat_room'
require 'db/combat/combat_info_db'
require 'db/combat/combat_data_db'
require 'db/combat/combat_room_status_db'

#chat
require 'db/social/channel_chat_db'
require 'db/social/friend_chat_db'
require 'db/social/social_db'
require 'db/social/friend_talk_msg'

#team_match
require 'db/match/pool_profile'
require 'db/match/match_pools_db'
require 'db/match/team_manager'
require 'db/match/team_match_5v5'
require 'db/match/team_match_3v3'
require 'db/match/team_match_1v1'
require 'db/match/team_match_2v2'
require 'db/match/team_match_4v4'
require 'db/match/match_manager_periodic'
require 'db/match/match_manager'
require 'db/match/team_info'
require 'db/match/match_pool_router'
require 'db/match/robot_base'
require 'db/match/robot_manager'

require 'db/account/account_man'

require 'jobs/batch_edit_data_job'
require 'jobs/test_tool_jobs'

require 'game/game_config'
require 'game/game_data_factory'
require 'rpc/rpc_functions'

require 'payment/goods_dispatcher'
require 'helpers/enum'

require 'session'
require 'handlers'
require 'delegates'

module RsGame
  def self.new_boot_config
    config = BootConfig.new do |cfg|
      cfg.app_name = 'rs'
      cfg.root_path = File.expand_path(File.join(File.dirname(__FILE__), '../..'))

      cfg.auto_load_paths = lambda do
        paths = Dir.glob('app/data/**/*.rb')
        paths << 'game-config/config.json'
        aps = Dir.glob('app/data/**/*_funcs.lua')
        paths += aps if aps
        # paths << 'game-data/default.json'
      end

      cfg.auto_load_on_file_changed = lambda do |name|
        if name.end_with? 'game_config.rb'
          load name
          puts '$$ GameConfig.reload'
          EM::Synchrony.next_tick do
            GameConfig.reload
          end
          true
        elsif name.end_with? 'config.json' or name.end_with? 'config.dat'
          puts '$$ GameConfig.reload'
          require 'game/game_config'
          EM::Synchrony.next_tick do
            GameConfig.reload
          end
          true
        elsif name.end_with? 'default.json'
          puts '$$ GameDataFactory.reload'
          require 'game/game_data_factory'
          GameDataFactory.reload
          true
        elsif name.end_with? 'group_funcs.lua'
          puts '$$ GroupFuncs.reload'
          require 'db/group/group_funcs'
          EM::Synchrony.next_tick do
            GroupFuncs.reload
          end
          true
        else
          false
        end
      end

      cfg.server_delegate = ServerDelegate.new
      cfg.connection_delegate = ConnectionDelegate.new
      cfg.dispatch_delegate = DispatchDelegate.new
      cfg.rpc_dispatch_delegate = RpcDispatchDelegate.new
    end
  end
end

# set boot config
Boot.set_config(RsGame.new_boot_config)
