# login.rb

class Login < Handler

  include RedisHelper

  def self.process(session, msg)
    id = msg['id']
    email = msg['email']
    zone = msg['zone'].to_i
    
    if id then
      user = User.read(id)
    elsif email then
      user = User.read_by_email(email)  
    end
    if email and user == nil then
       user = User.read_by_mobile(email)  
    end

    d {"user = #{user.to_json}"}
    success = (user != nil and user.pass == msg['pass'])

    if user and not UserValidator.validate_id(user.id)
      raise "player id should be an integer in valid range!"
    end

    player_id = user.id if success

    res = {}
    res = common_before(player_id, session, msg, res)

    if success then
      common_set_session(session, msg)

      session.player_id = player_id
      session.sdk = 'standard'
      session.zone = zone
      user.last_login_time=Time.now.to_i
      User.update(user)
    else
      if user == nil then
        res['reason'] = 'account_no_exist'
      else
        res['reason']= 'account_password_fail'
      end
    end
    res['success'] = success
    res['id'] = player_id

    res = common_res(session, msg, res)

    # Because we're changing nonce, we should push messages
    # only after the client and the gate both received the nonce
    #
    # This probably cause client cryption errors:
    # Helper.push_message(session, "hello login 000", 1000)
    # return res, BcastInfo.create([session.id], "hello login", 1000)
    #
    # This is less likely to cause client cryption errors:
    # EM::Synchrony.add_timer(3.0) do
    #   Helper.push_message(session, "hello login 000", 1000)
    # end

    return res
  end

  def self.common_before(cur_player_id, session, msg, res)
    prev_player_id = session.player_id
    if prev_player_id and prev_player_id != '$noauth$' then
      # if has previously logged in, logout first to put back game data
      info "#{session} has previous player #{prev_player_id} cur=#{cur_player_id}"
      if prev_player_id == cur_player_id
        session.player_id = nil
        SessionManager.remove_online(prev_player_id, session.zone)
      else
        Logout.process(session, nil)
      end
    end
    res
  end

  def self.common_set_session(session, msg)
    session.platform = msg['platform']
    session.location = msg['location'] || 'cn'
    session.device_id = msg['deviceId']
    session.device_model = msg['deviceModel']
    session.device_mem = msg['deviceMem']
    session.gpu_model = msg['gpuModel']
  end

  def self.common_res(session, msg, res)
    success = res['success']

    # quick return
    return res if not success

    player_id = session.player_id
    zone = msg['zone']

    # check zone validity
    if zone.nil? or zone <= 0 or zone > DynamicAppConfig.num_open_zones
      return { 'success' => false, 'reason' => 'zone_error' }
    end

    # check server maintainance
    reject, status = reject_with_maintainance?(player_id, session.sdk)
    if reject
      return { 'success' => false, 'reason' => 'maintainance',
        'start_at' => status.start_at, 'end_at' => status.end_at }
    end

    # check user permission
    if PermissionDb.deny_login?(player_id)
      return { "success" => false, 'reason' => 'gm_deny' }
    end

    begin
      lock_login(zone) do
        # check queuing:
        # TODO use enqueue_jump on vip users to gain a better position
        if QueuingDb.should_queue?(player_id, zone)
          QueuingDb.enqueue(player_id, zone)
          session.queue_rank = QueuingDb.rank(player_id, zone)
          return { 'success' => false, 'reason' => 'queue_rank', 'queue_rank' => session.queue_rank }
        end

        # register the player
        SessionManager.add_player(player_id, zone, session.id, session)
      end
    rescue => er
      error("lock_login error: #{session} #{er.message}")
      return { "success" => false, 'reason' => 'server_busy' }
    end

    SessionManager.set_db_session(player_id, session)

    # after all checks the player is allowed to login
    info "-- player #{player_id} logged in to zone #{session.zone}"

    # force encrypted msgpack
    if session.encoding != 'json-auto' and session.encoding != 'msgpack-auto'
      session.encoding = 'msgpack-auto'
    end

    session.login_time = Time.now.to_i

    ActionDb.log_action(player_id, session.zone, 'login',
      session.platform, session.sdk, session.location, session.device_id)

    # set nonce
    set_session_nonce(session, msg, res)

    zone_res = GetOpenZones.do_process(session, msg)
    res.merge!(zone_res)

    res['is_gm'] = true if in_id_whitelist?(player_id)
    res['allow_full_controller'] = true if AppConfig.server['allow_full_controller']
    res['disable_chongzhi'] = true if AppConfig.server['disable_chongzhi']

    res
  end

  @@lock_options = {:max_retry => 30, :lock_timeout => 5, :sane_expiry => 7}

  def self.lock_login(zone, &blk)
    RedisLock.new(get_redis, "login#{zone}", @@lock_options).lock do
      begin
        blk.call
      rescue => er
        error("Locked login failed: ", er)
      end
    end
  end

  def self.in_id_whitelist?(id)
    status = DynamicAppConfig.maintainance_status
    d{"[booth] 1 status:#{status}"}
    return false if status.nil?
    d{"[booth] 2  id:#{id}"}
    status.in_id_whitelist?(id)
  end

  def self.reject_with_maintainance?(id, sdk = nil)
    status = DynamicAppConfig.maintainance_status

    if status and status.on
      if id.nil?
        return true, status
      end
      if status.in_id_whitelist?(id)
        info "mtn: allow #{id}"
      elsif sdk && status.in_sdk_whitelist?(sdk)
        info "mtn: allow #{id} from #{sdk}"
      elsif (id < YousiPlayerIdManager::RESERVED_ID_RANGE) and status.enable_loadtest
        info "mtn: allow #{id} for loadtest"
      else
        return true, status
      end
    end

    return false
  end

end
