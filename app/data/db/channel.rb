# channel.rb

class Channel

  include Loggable
  include Statsable
  include Pubsub

  @@last_queuing_progress_tm = 0

  def self.publish_channel_chat zone, hash
    Channel.publish('channel_chat', zone, hash)
  end

  def self.publish_chat session, to_pid, msg
    id = Helper.get_cid_by_pid(to_pid)
    # puts "publish_chat: session=#{session} to_pid=#{to_pid} id=#{id} msg=#{msg}"
    return if id == session.player_id
    Channel.publish("chat:#{id}", session.zone, msg)
  end

  private

  def self.subscribe_channels
    # will subscribe to all zones

    #######################################
    # 1002
    Pubsub.subscribe('notice') do |_channel, zone, hash|
      client_each(zone, nil) do |_uid, session|
        Helper.push_message(session, hash, 1002)
      end
      stats_increment_local 'pubsub.notice'
    end

    #######################################
    # 1003
    # multiple login notification
    Pubsub.psubscribe(/m:(.+)/) do |channel, zone, hash|
      EM::Synchrony.next_tick do
        begin
          uid = channel[2..-1]
          d { "notify user for multiple login: #{uid} - zone - #{zone} - #{hash}" }
          Helper.push_message_player(uid, zone, hash, 1003)
          SessionManager.force_remove_player(uid, zone)
        rescue => er
          error('Channel Error: ', er)
        end
      end
      stats_increment_local 'pubsub.notification_multiple_login'
    end

    #######################################
    # 1003
    # personal notification channels
    # also used for payment complete notifications
    Pubsub.psubscribe(/u:(.+)/) do |channel, zone, hash|
      EM::Synchrony.next_tick do
        begin
          uid = channel[2..-1]
          d { "notify user: #{uid} - zone - #{zone} - #{hash}" }
          Helper.push_message_player(uid, zone, hash, 1003)
        rescue => er
          error('Channel Error: ', er)
        end
      end
      stats_increment_local 'pubsub.notification'
    end


    #######################################
    # 1004
    Pubsub.subscribe('announcement') do |_channel, _zone, hash|
      client_each_all(nil) do |_uid, session|
        Helper.push_message(session, hash, 1004)
      end
      stats_increment_local 'pubsub.announcement'
    end

    #######################################
    # 1005
    # combat room activities or match notifications
    Pubsub.subscribe('pvpcombat') do |channel, zone, hash|
      EM::Synchrony.next_tick do
        pids = hash['pids']
        pids.each do |pid|
          d { "notify user: #{pid} - zone - #{zone} - #{hash}" }
         Helper.push_message_with_pid(pid, hash['content'], 1005)
        end
      end
      stats_increment_local 'pubsub.notification'
    end

    #######################################
    # 1006
    Pubsub.psubscribe(/chat:(.+)/) do |channel, zone, hash|
      EM::Synchrony.next_tick do
        begin
          uid = channel[5..-1]
          #puts(">>>>>>>>>>>uid:#{uid}")
          d { "notify user: #{uid} - zone - #{zone} - #{hash}" }
          chat_msg = hash['chat_msg']
          if chat_msg and chat_msg['content']['blocked']
            if chat_msg['pid'].include?(uid)
              Helper.push_message_player(uid, zone, hash, 1006)
            end
          else
            Helper.push_message_player(uid, zone, hash, 1006)
          end
        rescue => er
          error('Channel Error: ', er)
        end
      end
      stats_increment_local 'pubsub.chat'
    end

    #######################################
    # 1007
    Pubsub.psubscribe(/follow:(.+)/) do |channel, zone, hash|
      EM::Synchrony.next_tick do
        begin
          uid = channel[7..-1]
          d { "notify user: #{uid} - zone - #{zone} - #{hash}" }
          Helper.push_message_player(uid, zone, hash, 1007)
        rescue => er
          error('Channel Error: ', er)
        end
      end
      stats_increment_local 'pubsub.follow'
    end

    #######################################
    # 1008
    Pubsub.psubscribe(/mail:(.+)/) do |channel, zone, hash|
      EM::Synchrony.next_tick do
        begin
          uid = channel[5..-1]
          d { "notify user mail: #{uid} - zone - #{zone} - #{hash}" }
          Helper.push_message_player(uid, zone, hash, 1008)
        rescue => er
          error('Channel Error: ', er)
        end
      end
      stats_increment_local 'pubsub.mail'
    end

    #######################################
    # 1009
    # => ChannelChatDb.get_players(chid, zone)
    Pubsub.subscribe('channel_chat') do |channel, zone, hash|
      EM::Synchrony.next_tick do
        begin
          chid = hash['chid']
          pids = ChannelChatDb.get_players(chid, zone)
          d{">>>>>>[pids]:#{pids}"}
          msg  = {'chat' => hash['msg'] }
          if not pids.nil?
            pids.each do |pid|
              Helper.push_message_with_pid(pid, msg, 1009)
            end
          end
        rescue => er
          error("Channel Error: ", er)
        end
      end
      stats_increment_local 'pubsub.channel_chat'
    end
    
    #######################################
    # 1010
    Pubsub.subscribe('system_message') do |_channel, zone, hash|
      if hash.uid
        uid = Helper.get_cid_by_pid(hash.uid)
        Helper.push_message_player(uid, zone, hash, 1010)
      elsif hash.pids
        hash.pids.each do |pid|
          Helper.push_message_with_pid(pid, hash.message, 1010)
        end
      else
        client_each(zone, nil) do |_uid, session|
          Helper.push_message(session, hash, 1010)
        end
      end
      stats_increment_local 'pubsub.system_message'

    end
    


    #######################################
    # 1011
    # queuing system messages
    Pubsub.subscribe('queuing') do |_channel, zone, hash|
      handle_queuing_message(zone, hash, 1011)
      stats_increment_local 'pubsub.queuing'
    end

    #######################################
    # 1911
    # notify client to upload
    Pubsub.subscribe('upload_logs') do |channel, zone, hash|
      d { "upload_logs: #{hash}" }
      uid = hash['uid']
      Helper.push_message_player(uid, zone, hash, 1911)
      stats_increment_local 'pubsub.upload_logs'
    end

    #######################################
    # 1012
    Pubsub.subscribe('send_addteam') do |channel, zone, hash|
      EM::Synchrony.next_tick do
        uid = hash['topid']
        #fromuid = hash['frompid']
        d { "notify user: #{uid} - zone - #{zone} - #{hash}" }
        Helper.push_message_with_pid(uid,hash, 1012)
      end
      stats_increment_local 'pubsub.send_addteam'
    end

    #######################################
    # 1013
    Pubsub.subscribe('team_message') do |channel, zone, hash|
      EM::Synchrony.next_tick do
        

        pids = hash['pids']
        pids.each do |pid|
          d { "notify user: #{pid} - zone - #{zone} - #{hash}" }
         Helper.push_message_with_pid(pid, hash['content'], 1013)
        end
      end
      stats_increment_local 'pubsub.notification'
    end
    #######################################
    # 1014
    Pubsub.subscribe('friend_chat') do |channel, zone, hash|
      EM::Synchrony.next_tick do
        begin
          pids = hash['pids']
          msg  = {'chat' => hash['msg'] }
          if not pids.nil?
            pids.each do |pid|
              Helper.push_message_with_pid(pid, msg, 1014)
            end
          end
        rescue => er
          error("Channel Error: ", er)
        end
      end
      stats_increment_local 'pubsub.friend_chat'
    end
    #######################################
    # 1015
    Pubsub.subscribe('friend_request') do |channel, zone, hash|
      EM::Synchrony.next_tick do
        begin
          frd = hash['frd']
          if not frd.nil?
            Helper.push_message_with_pid(frd, hash, 1015)
          end
        rescue => er
          error("Channel Error: ", er)
        end
      end
      stats_increment_local 'pubsub.friend_request'
    end
    
  end

  def self.handle_queuing_message(zone, hash, proto_num)
    zone = zone.to_i
    dequeued = hash['dequeued']
    broadcast_progress = false

    now = Time.now.to_f
    if now - @@last_queuing_progress_tm >= 3.5
      @@last_queuing_progress_tm = now
      broadcast_progress = true
    end

    d { "Channel: queuing received hash=#{hash} broadcast_progress=#{broadcast_progress}" }

    client_each_all_sessions(nil) do |_uid, session|
      # d { "Channel: queuing check #{session} dequeued=#{dequeued}"}
      player_id, player_zone = session.player_id, session.zone

      if player_id and player_zone == zone and session.queue_rank
        d { "Channel: queuing notify #{player_id} #{zone} rank=#{session.queue_rank}"}
        if dequeued.include? player_id
          # notify the player to login now
          session.queue_rank = nil
          Helper.push_message(session, { 'dequeue' => true }, proto_num)
        else
          # speculate queue_rank in memory
          session.queue_rank -= dequeued.length
          # notify the player about queuing progress
          if session.queue_rank < 1
            # fix queue_rank here
            session.queue_rank = QueuingDb.rank(player_id, zone)
          end
          if session.queue_rank == nil
            # it's possible when handling two queuing messages at the same time,
            # due to async nature of the server. push dequeue for safety
            info "#{session} queue_rank is nil!"
            Helper.push_message(session, { 'dequeue' => true }, proto_num)
          elsif broadcast_progress
            Helper.push_message(session, { 'queue_rank' => session.queue_rank }, proto_num)
          end
        end
      end
    end
  end

end
