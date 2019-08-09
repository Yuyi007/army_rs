# delegates.rb
# implement boot delegates for rs

class RsGameArchiveDataCriteria < Boot::StaticArchiveCriteria
  def should_archive_model?(model)
    cur_instance = model.cur_instance
    return false unless cur_instance
    #to do add condition to achieve player blob
    return true
  end
end

class ServerDelegate < Boot::DefaultServerDelegate
  def on_server_prefork(options = {})
    GameConfig.preload options[:base_path]
    GameDataFactory.preload options[:base_path]
    Resolv.init_udns_cache('as.dun.163yun.com')
  end

  def on_server_start(_options = {})
    ArchiveData.set_criteria RsGameArchiveDataCriteria.new
  end

  def on_app_config_loaded(path)
    CSRouter.init_checker_groups()
  end

  def on_pubsub_init
    Channel.subscribe_channels
  end
end

class ConnectionDelegate < Boot::DefaultConnectionDelegate
  include Loggable

  def create_session(id, server)
    RsSession.new id, server
  end

  def unbind(_server, session)
    session_id = session.id
    player_id = session.player_id
    zone = session.zone
    info "-- unbind session: #{session}"
    bi = nil

    if GameData.validate_id_zone(player_id, zone)
      SessionManager.remove_player(player_id, zone, session_id)
    #  TeamManager.remove_player(player_id, zone, session_id)
      

      ActionDb.log_action(player_id, zone, 'unbind')

      session_time = 0
      if session.login_time > 0
        session_time = Time.now.to_i - session.login_time
      end
      if session.logged_in?
        stat("-- logout, #{session.pid}, #{zone}, #{session.platform}, #{session_time}, #{session.device_id}")
      end

      # remove from queuing and notify other queued players
      remove_queuing(player_id, zone, session)
      renew_queuing(session)

      CachedGameData.take(player_id, zone) do |id, zone, model|
        instance = model.instance
        if instance
          pid = instance.player_id
          leave_room(instance, zone)

          instance.online = false
          instance.update_player
          
          # #移除非世界和世界频道本玩家,清除内存里的线上本玩家,非世界聊天频道人数为0移除该频道
          # UnregisterListenChannelMessage.process(session, nil, model) #删除世界频道玩家
          # ch_ids = ChannelChatDb.get_all_chids(zone)
          #  # puts ">>>pid:#{pid}"
          # ch_ids.each do |id|
          #   # puts ">>>id:#{id}"
          #   if id.to_i > 1
          #     ChannelChatDb.del_player(id, zone, pid) #删除非世界频道玩家
          #     ChannelChatDb.del_online_player(id, zone, pid)
          #     count = ChannelChatDb.get_channel_players_count(id, zone)
          #     # puts ">>>>>>count:#{count}"
          #     if count == 0 
          #       ChannelChatDb.del_channel_msgs(id, zone) #删除非世界频道聊天信息
          #       # ChannelChatDb.del_channel_id(id, zone)   #删除非世界聊天频道
          #       # ChannelChatDb.del_mey_channel_id(id)     #删除非世界内存里的频道
          #     end 
          #   end  
          # end
          # ChannelChatDb.del_all_msg(zone)
          
          #ChatChannel.delete_if_no_clients(cid,zone)
          # puts "pid is == #{pid}"
          # stat("-- game_data, #{pid}, #{session.zone},#{session.device_id}, #{session.platform}, #{session.sdk},"\
          #                    "#{instance.city_event.level}, #{instance.hero.faction}, #{instance.hero.level}, #{instance.credits}, #{instance.money}, #{instance.coins},"\
          #                    "#{instance.vip.level}")
          # remove all team applications from this player
          szone = session.zone



          args = {
            :cmd => 'remove_player',
            :player_id => pid,
            :session_id => session_id,
            :zone => zone
          }

          puts "unbind rpc", pid

          cid = CSRouter.get_zone_checker(zone)
          RedisRpc.call(TeamManager, cid, args)
        end
      end
      

      # MessageQueueHelper.archive_data_queue.enqueue(session.player_id, session.zone)

      if CachedGameData.has_cache?(player_id, zone)
        # stat("-- game_data,  #{player_id}, #{zone},#{session.device_id}, #{session.platform}, #{session.sdk},"\
        #                     "#{model.chief.level}, #{model.chief.sogs}, #{model.chief.credits}, #{model.chief.medals},"\
        #                     "#{model.chief.vip.level}, #{model.record.login.login_days_count}, #{model.record.login.continuous_login_days}")
        CachedGameData.put_back(player_id, zone)

        begin
          RedisRpc.cast(ArchiveDataJob, CSRouter.get_archive_checker(), player_id, zone)
        rescue => er
          error("cast archive data failed: #{session} #{er.message}")
        end
      end
    end

    bi
  end
 def leave_room(instance, zone)
    args=
    {
      :cmd =>'leave_room',
      :pid => instance.pid,
      :id => instance.cur_room_id
    } 
    cid = CSRouter.get_zone_checker(zone)
    res = RedisRpc.call(CombatRoom, cid, args)
    instance.cur_room_id = nil 
    res
 end

  def remove_queuing(player_id, zone, session)
    session.queue_rank = nil
    QueuingDb.remove(player_id, zone)

    if session.logged_in?
      if QueuingDb.exceeds_max_online?(zone) then
        info "#{session} logout but still exceeds max_online"
        return
      end

      # FIXME race condition for dequeue more than one players
      dequeue_num = QueuingDb.dequeue_num(zone)
      if dequeue_num > 0
        dequeue_players = QueuingDb.dequeue(dequeue_num, zone)
        if dequeue_players and dequeue_players.length > 0
          info "#{session} remove_queuing dequeued=#{dequeue_players}"
          hash = { 'dequeued' => dequeue_players }
          Channel.publish('queuing', zone, hash)
        end
      end
    end
  end

  def renew_queuing(session)
    if session.logged_in?
      QueuingDb.renew(session.player_id, session.zone)
    end
  end

  def on_send_success(server, session, res_packet)
    d { ">> result = #{res_packet.msg}" }
  end
end

class DispatchDelegate < Boot::DefaultDispatchDelegate
  include Loggable

  def create_default_model(session)
    model = GameDataFactory.new_default.init_new_created(session)
    model.chief.platform = session.platform
    model
  end

  def create_model
    GameDataModel.new
  end

  def all_handlers
    Handlers::HANDLERS
  end

  def get_handler(type)
    Handlers.get_handler(type)
  end

  def get_type(handler_name)
    Handlers.get_type(handler_name)
  end

  def can_batch?(session, type, _msg)
    # Login, Register etc. can't be batched as they change session.player_id
    # (type > 105)
    false
  end

  def on_before_process(session, type, _msg, model, res)
    if should_reject? session, type, res
      false # should not further process the request
    else
      true
    end
  end

  def on_process_success(sesion, type, msg, model, res, handler)
    if model && model.cur_instance_exist? && model.cur_instance
      instance = model.cur_instance
     
      #to do apply extra data into result 
    end

    if msg.class.to_s == 'Hash' && defined? msg['client_time']
      res['client_time'] = msg['client_time']
      res['server_time'] = {}
      res['server_time']['time'] = Time.now.to_i
      res['server_time']['reset_time'] = Helper.reset_time
    end

    # puts("------- res:#{Helper.to_json(res)}")
    res['md_ver'] = model.version if model
  end

  def on_process_failed(session, type, msg, model, res, handler)
    # nothing to do here
  end

  def on_before_update(session, model)
  end

  def on_update_success(session, params)
  end

  private

  def should_reject?(session, type, res)
    # Login and ResumeGameData handlers allow pass without checking multi-login
    # d { "should_reject? type=#{type} session=#{session}"}
    if (type > 152 ) && session.player_id
      cs = SessionManager.get_db_session(session.player_id)
      # d { "db session is #{cs}" }
      if cs.session_id.nil?
        # res['user_offline'] = true
        # return true
        return false
      else
        if cs.session_id != session.id
          info "-- reject with multi_login, cs: #{cs}  session: #{session}"
          res['reason'] = 'multi_login'
          return true
        end
      end
    end

    false
  end
end

class RpcDispatchDelegate < Boot::DefaultRpcDispatchDelegate
  include Loggable

  def all_functions
    {}
  end

  def on_rpc_success(session, _res_packet, result, bi)
    if bi
      d { ">> result = #{result} bi = #{bi}" }
    else
      d { ">> result = #{result}" }
    end
  end
end
