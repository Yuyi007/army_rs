# handlers.rb
#

require 'handlers/update'
require 'handlers/keep_alive'
require 'handlers/get_open_zones'
require 'handlers/name_validator'
require 'handlers/user/register'
require 'handlers/user/register_guest'
require 'handlers/user/update_user'
require 'handlers/user/login'
require 'handlers/user/logout'
require 'handlers/user/cancel_queuing'
require 'handlers/user/get_verification_code'
require 'handlers/user/update_user_password'
require 'handlers/user/register_thirdparty'

require 'handlers/get_game_data'
require 'handlers/resume_game_data'
require 'handlers/delete_game_data'
require 'handlers/data_load_test'
require 'handlers/choose_instance'
require 'handlers/create_instance'
require 'handlers/cheat/cheat_game'
require 'handlers/upload_game_log'

require 'handlers/combat/get_room_list'
require 'handlers/combat/get_room_info'
require 'handlers/combat/create_room'
require 'handlers/combat/enter_room'
require 'handlers/combat/leave_room'
require 'handlers/combat/set_ready'
require 'handlers/combat/start_combat'
require 'handlers/combat/check_unfinished_combat'
require 'handlers/combat/confirm_combat_car'
require 'handlers/combat/sync_combat_data'
require "handlers/combat/clear_cur_room_id"

require 'handlers/mail/mail'
require 'handlers/mail/redeem_items'
require 'handlers/mail/update_gm_mail'
require 'handlers/mail/test_deliver_mail'

require 'handlers/avatar/avatar_purchase'
require 'handlers/avatar/avatar_equipped'
require 'handlers/avatar/save_drive_scheme'
require 'handlers/avatar/refresh_avatar'

require "handlers/team/create_team"
require "handlers/team/enter_team"
require "handlers/team/leave_team"
require "handlers/team/team_match_request"
require "handlers/team/team_match_confirm"
require "handlers/team/team_member_ready"
require "handlers/team/team_invit"
require "handlers/team/team_match_cancel"
require "handlers/team/team_kick_member"

require "handlers/social/send_channel_message"
require "handlers/social/register_listen_channel_message"
require "handlers/social/unregister_listen_channel_message"
require "handlers/social/register_channel"
require "handlers/social/unregister_channel"

require "handlers/social/send_friend_request"
require "handlers/social/search_friend_request"
require "handlers/social/get_friend_request_list"
require "handlers/social/accept_friend_request"
require "handlers/social/remove_friend"
require "handlers/social/get_friend_list"
require "handlers/social/reject_friend_request"
require "handlers/social/get_ten_friends"
require "handlers/social/get_player_info"
require "handlers/social/save_label_info"
require "handlers/social/get_player_combat_data"
require "handlers/social/change_name_request"
require "handlers/social/update_player_icon"
require "handlers/user/register_phone"

require "handlers/social/friend_chat_send_message"
require "handlers/social/friend_chat_get_content"
require "handlers/social/friend_chat_remove_chat"
require "handlers/social/team_invite_publish"
require "handlers/social/clear_friend_unread_msg"

require "handlers/item/get_items"
require "handlers/item/click_item"
require "handlers/item/sell_expired_items"
require "handlers/item/sell_item"
require "handlers/item/use_item"

require "handlers/shop/get_goods"
require "handlers/shop/shop_buy_item"

require 'handlers/get_notice_list'
require 'handlers/send_test_data'

class Handlers

  HANDLERS = {
  	100 => Update,
  	101 => Register,
    102 => Login,
  	103 => UpdateUser,
  	104 => RegisterGuest,
  	105 => CancelQueuing,
  	106 => Logout,
  	107 => GetOpenZones,
  	109	=> KeepAlive,
    110 => UpdateUserPassword,
    111 => RegisterThirdparty,
  	151 => GetGameData,
		152 => ResumeGameData,
		153 => DataLoadTest,
		154 => ChooseInstance,
		155 => CreateInstance,
		156 => CheatGame,
		157 => UploadGameLog,

    158 => GetRoomList,
    159 => GetRoomInfo,
    160 => CreateRoom, 
    161 => EnterRoom,
    162 => LeaveRoom,
    163 => StartCombat,
    164 => CheckUnfinishedCombat,
    165 => SyncCombatData,
    166 => SearchFriendRequest,
    167 => RemoveFriend,
    168 => GetFriendList,
    169 => SendFriendRequest,
    
    170 => SaveDriveScheme,
    171 => AvatarPurchase,
    172 => AvatarEquipped,
    173 => RejectFriendRequest,

    174 => ConfirmCombatCar,
    175 => AcceptFriendRequest,
    176 => GetFriendRequestList,
    177 => GetPlayerInfo,

    178 => SetMailsRead,
    179 => SetRead,
    182 => RedeemItems,
    184 => GetMails,
    185 => UpdateGmMail,

    186 => CreateTeam,
    187 => EnterTeam,
    188 => LeaveTeam,
    189 => TeamMatchRequest,
    190 => TeamMatchConfirm,
    191 => TeamMemberReady,
    192 => TeamInvit,
    193 => TeamMatchCancel,
    194 => SetReady,
    195 => GetTenFriends,

    196 => GetVerificationCode,
    197 => RegisterPhone,
    198 => TeamKickMember,
    199 => SaveLabelInfo,
    200 => GetPlayerCombatData,
    201 => ChangeNameRequest,
    202 => ClearCurRoomID,
    203 => SendChannelMessage,
    204 => RegisterListenChannelMessage,
    205 => RegisterChannel,
    206 => UnRegisterChannel,
    207 => FriendChatSendMessage,
    208 => GetFriendChatContent,
    209 => TeamInvitePublish,
    210 => TestDeliverMail,
    211 => GetItems,
    212 => ClickItem,
    213 => SellExpiredItems,
    214 => GetGoods,
    215 => ShopBuyItem,

    216 => UpdatePlayerIcon,
    217 => RefreshAvatar,
    218 => ClearFriendUnReadMsg,

    219 => SellItem,
    220 => UseItem,

    221 => UnregisterListenChannelMessage,
    223 => GetNoticeList,
    1001 => SendTestData,
  }	

end
