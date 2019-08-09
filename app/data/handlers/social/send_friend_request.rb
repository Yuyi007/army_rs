
class SendFriendRequest < Handler
  def self.process(session, msg, model)
    idname = msg['idname']
    return ng(res, 'Invalid param') if idname.nil?
    zone = session.zone
    instance = model.instance 

    player_info = Player.read_by_id(idname, zone)

    if player_info.nil?
      pid = Player.read_id_by_name(idname, zone)
      player_info = Player.read_by_id(pid, zone)
      return ng('notExist') if player_info.nil?
    end
    # puts "read_info:#{player_info}"
    frd_id = player_info.pid
    my_id = instance.player_id
    zone = session.zone


    my_frd_ids  = SocialDb.friends(my_id, zone)

    # info ">>>>>>>#{my_frd_ids.size} #{model.chief.max_friends_num}"
    if my_frd_ids.size >= model.chief.max_friends_num
      return  ng('max_friend')
    end

    #clear when add friend
    #############################################
    # SocialDb.clear_abandons(my_id, zone)
    # if SocialDb.is_abandon(my_id, zone, frd_id)
    #   return  ng2(res, 'abandonFriend')
    # end
    #############################################
    return ng('already_friend') if SocialDb.is_friend?(my_id, frd_id, zone)
    return ng('already_following') if SocialDb.is_following?(my_id, frd_id, zone)

    if my_id != frd_id
      if player_info
        SocialDb.add_friend(my_id, frd_id, zone)
        info = player_info.to_hash
        hash = {'pid' => my_id, 'frd' => frd_id}
        Channel.publish('friend_request', zone, hash)

        res = {'success' => true, 'friend' => info}
        return res
      end
    end

    {'success' => false}
  end
end