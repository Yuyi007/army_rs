# SessionManager.rb
#
# Session Table 存在于服务器内
# DB 上存储在线状态
#

module Boot

  class SessionManager

    MAX_ZONES ||= 5000

    include Loggable
    include RedisHelper

    @@sessions ||= {} # sid -> session
    @@players ||= {} # zone -> { uid -> session }

    def self.init
      reset
    end

    def self.reset
      info 'SessionManager.reset:'

      @@sessions = {}

      @@players.each do |zone, table|
        table.dup.each do |uid, _|
          redis.hdel(players_zone_key(zone), uid)
          redis.hdel(sessions_key, uid)
        end
      end

      (1..MAX_ZONES).each do |zone|
        @@players[zone] = {}
      end
    end

    # Cleanup inactive sessions
    # Avoid memory leak on inactive sessions
    #
    # @param inactive_timeout [Float] the inactive timeout value in seconds
    def self.cleanup_inactive_sessions(inactive_timeout = 1800.0)
      now = Time.now
      @@sessions.clone.each do |sid, session|
        puts "cleanup_inactive_sessions now:#{now}, last active:#{session.last_active}"
        inactive_time = now - session.last_active
        if inactive_time > inactive_timeout
          info "SessionManager.cleanup_inactive_sessions: #{session} last_active=#{session.last_active}"
          delete_session(sid)
        end
      end
    end

    # Add a session
    #
    # @param sid [Integer] the session id
    # @param session [Hash] the session object
    def self.add_session(sid, session)
      fail 'invalid session data!' if session.id != sid

      @@sessions[sid] = session
    end

    # Delete a session
    #
    # @param sid [Integer] the session id
    def self.delete_session(sid)
      fail 'invalid args!' if sid.nil?

      session = @@sessions[sid]
      info "SessionManager.delete_session: sid=#{sid} session=#{session}"

      if session then
        uid, zone = session.player_id, session.zone
        if (uid && zone && zone > 0)
          remove_player(uid, zone, sid)
        else
          @@sessions.delete(sid)
        end
      end
    end

    # Add a player
    #
    # @param uid [Integer] the player user id
    # @param zone [Integer] the player zone
    # @param sid [Integer] the session id
    # @param session [Hash] the session object
    def self.add_player(uid, zone, sid, session)
      info "SessionManager.add_player: uid=#{uid} zone=#{zone} sid=#{sid} session=#{session}"

      fail 'invalid args!' if zone.nil? || uid.nil? || sid.nil? || session.nil?
      fail 'invalid session data!' if session.id != sid || session.player_id != uid || session.zone != zone

      server = session.server
      fail 'server is nil!' if server.nil?

      table = @@players[zone.to_i]
      fail "zone #{zone} is nil!" unless table

      old_session = table[uid]
      if old_session and old_session.id != sid
        # remove the old player mapping to a different sid
        force_remove_player(uid, zone)
      end

      @@sessions[sid] = session
      table[uid] = session

      # set online user presence
      redis.hset(players_zone_key(zone), uid, AppConfig.server_id)
    end

    # Safely Remove a player
    # only remove a player if its sid matches the parameter
    #
    # When a player quickly unbinds and login again, we shall not
    # incorrectly remove the session that just logged in
    #
    # @param uid [Integer] the player user id
    # @param zone [Integer] the player zone
    # @param sid [Integer] the session id
    def self.remove_player(uid, zone, sid)
      info "SessionManager.remove_player: uid=#{uid} zone=#{zone} sid=#{sid}"

      fail 'invalid args!' if uid.nil? || zone.nil? || sid.nil?

      session = get(uid, zone)

      if session and session.id == sid
        force_remove_player(uid, zone)
      else
        info "SessionManager.remove_player: uid=#{uid} sid=#{sid} but session=#{session}"
        @@sessions.delete(sid)
      end
    end

    # Ensure the player is removed
    #
    # @param uid [Integer] the player user id
    # @param zone [Integer] the player zone
    def self.force_remove_player(uid, zone)
      info "SessionManager.force_remove_player: uid=#{uid} zone=#{zone}"

      fail 'invalid args!' if uid.nil? || zone.nil?

      table = @@players[zone.to_i]
      fail "zone #{zone} is nil!" unless table

      session = table.delete(uid)
      # fail "no such client to remove #{uid}" unless session

      if session
        sid = session.id
        @@sessions.delete(sid)
      end

      # delete online user presence
      redis.hdel(players_zone_key(zone), uid)
    end

    # Get a session by session id
    #
    # @param sid [Integer] the session id
    # @return session [Hash] the session object
    def self.get_by_sid(sid)
      @@sessions[sid]
    end

    # Get a session by player id and zone
    #
    # @param uid [Integer] the player id
    # @param zone [Integer] the player zone
    # @return session [Hash] the session object
    def self.get(uid, zone)
      table = @@players[zone.to_i]
      fail "zone #{zone} is nil!" unless table

      # info "SessionManager.get: #{table.keys}"

      table[uid]
    end

    def self.get_zone(zone)
      table = @@players[zone.to_i]
      fail "zone #{zone} is nil!" unless table

      table.dup
    end

    def self.get_all_zones
      merged_t = {}
      @@players.each { |_zone, table| merged_t.merge!(table) if table }

      merged_t
    end

    def self.get_all_sessions
      merged_t = {}
      @@sessions.each { |sid, session| merged_t[sid] = session }

      merged_t
    end

    def self.get_player_server_id(uid, zone)
      redis.hget(players_zone_key(zone), uid)
    end

    def self.remove_online(uid, zone)
      redis.hdel(players_zone_key(zone), uid)
    end

    # Caution! Use with care!
    def self.remove_all_onlines(zone)
      redis.del(players_zone_key(zone))
    end

    def self.online?(uid, zone)
      redis.hexists(players_zone_key(zone), uid)
    end

    def self.num_online(zone)
      redis.hlen(players_zone_key(zone))
    end

    def self.all_online_ids(zone)
      redis.hkeys(players_zone_key(zone))
    end

    def self.num_connected_sessions
      @@sessions.length
    end

    def self.num_player_sessions(zone)
      table = @@players[zone.to_i]
      return 0 if table.nil?
      table.length
    end

    def self.num_all_player_sessions
      @@players.inject(0) { |num, (_zone, table)| num + table.length }
    end

    def self.set_db_session(uid, session)
      uid ||= session.player_id
      redis.hset(sessions_key, uid, DBSession.new(session).dump)
    end

    def self.get_db_session(uid)
      res = DBSession.new
      raw = redis.hget(sessions_key, uid)
      if raw
        res.load!(raw)
      else
        res
      end
    end

    # dangerous! keep away unless you know what you are doing.
    def self.reset_all_db_sessions
      if redis.exists(sessions_key)
        info 'reset all online records (db sessions)'
        redis.del(sessions_key)
        (1..MAX_ZONES).each { |i| redis.del(players_zone_key(zone)) }
      else
        info 'online records not found'
      end
    end

    private

    def self.redis
      return @@redis if defined? @@redis and @@redis
      return get_redis :user
    end

    def self.redis= redis
      @@redis = redis
    end

    def self.sessions_key
      'clients:session'
    end

    def self.players_zone_key(zone)
      "clients:#{zone}"
    end
  end

  class DBSession
    attr_accessor :server_id
    attr_accessor :session_id

    include Jsonable

    def initialize(session = nil)
      @server_id = AppConfig.server_id
      @session_id = session.id if session
    end
  end

end
