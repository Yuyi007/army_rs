class FriendRemove
  attr_accessor :player_id
  include Jsonable
end


class RemoveFriend < Handler
  def self.process(session, msg, model)
    instance = model.instance
    pid = msg['pid']
    return ng('Invalid param') if not pid
    if msg['type'].nil? then
      msg['type'] = 0
    end
    SocialDb.remove_friend(instance.player_id, pid, session.zone, msg['type'])
    RemoveFriendChat.process(session, msg, model)
    # model.social.on_frd_removed(pid, session.zone)


    #friend_remove_chat_channel
    ################################################
    # FriendChatDb.del_conversation(session.zone, session.player_id, pid)
    # FriendChatDb.del_conversation(session.zone, pid, session.player_id)
    ################################################

    #notify
    # FriendRemove.new.tap do |m|
    #   m.player_id = session.player_id
    #   NotifyCenter.notify(pid, session.zone, m)
    # end

    {'success' => true,
     'removed' => pid}
  end
end