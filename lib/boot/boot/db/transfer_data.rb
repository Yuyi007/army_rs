# TransferData.rb

module Boot

  class TransferDataWorker

    include Loggable
    include RedisHelper

    def work_loop
      @shutdown = false
      @redis = get_redis
      @cold_data_days = AppConfig.server['cold_data_days'] || 7
      @idle_threshold = [(60 * 60 * 24 * @cold_data_days).to_i, 60].max

      info "TransferDataWorker: idle_threshold=#{@idle_threshold}"
      info "TransferDataWorker: starting work loop..."

      loop do
        break if @shutdown
        info "TransferDataWorker: prepare to scan zones..."
        begin
          (1..DynamicAppConfig.num_open_zones).to_a.shuffle.each do |zone|
            info "TransferDataWorker: scanning zone #{zone}..."
            @cursor = '0'
            loop do
              begin
                @cursor, keys = @redis.hscan(Player.player_key(zone), @cursor, :count => 8)
                # info "TransferDataWorker: cursor=#{@cursor} keys=#{keys}"
                keys.each do |key|
                  pid, _data = key[0], key[1]
                  zone2, player_id, _iid = Helper.decode_player_id(pid)
                  if player_id and zone2.to_i == zone then
                    cold_key = GameData.blob_key(player_id, zone)
                    idletime = @redis.object('idletime', cold_key)
                    if (idletime != nil and idletime > @idle_threshold)
                      dumped = false
                      begin
                        dumped = (@redis.get(cold_key) == MysqlBackup::BACKUP_TAG)
                      rescue Redis::CommandError => e
                        # if wrong key type, means not dumped yet
                        if e.message !~ TransferData::WRONG_KIND_OF_VALUE_REGEX
                          raise e
                        end
                      end
                      if not dumped
                        info "TransferDataWorker: idle player #{player_id} #{zone}"
                        TransferData.to_db(player_id, zone)
                      end
                    end
                  end
                end
              rescue => er2
                error("TransferDataWorker Error: ", er2)
              end
              Boot::Helper.sleep 0.5
              break if @cursor == '0'
            end
          end
        rescue => er
          error("TransferDataWorker Error: ", er)
        end
      end

      info "TransferDataWorker: work loop stopped."
    end

    def shutdown!
      @shutdown = true
      @redis = nil
    end

  end

  class TransferData

    WRONG_KIND_OF_VALUE_REGEX ||= /Operation against a key holding the wrong kind of value/

    include Loggable
    include Statsable
    include RedisHelper

    def self.restorable?(value)
      return (value == MysqlBackup::BACKUP_TAG)
    end

    def self.transferrable_keys(player_id, zone)
      [ GameData.blob_key(player_id, zone) ]
    end

    def self.to_db(player_id, zone)
      GameData.lock(player_id, zone) do |player_id, zone|
        redis = get_redis zone
        backup = MysqlBackup.new(zone)

        keys = transferrable_keys(player_id, zone)
        success = 0

        keys.each do |key|
          begin
            dumped = false
            dumped = (redis.get(key) == backup.tag)
          rescue Redis::CommandError => e
            # if wrong key type, means not dumped yet
            if e.message !~ WRONG_KIND_OF_VALUE_REGEX
              raise e
            end
          end

          unless dumped
            val = redis.dump(key)
            if val
              val = val.force_encoding('utf-8')
              set = backup.set(key, val)
              if set
                val2 = backup.get(key)
                val2 = val2.force_encoding('utf-8') if val2
                if val2 == val
                  redis.set(key, backup.tag)
                  info "to_db: success #{key}"
                  stats_increment_local "transfer.to_db.success"
                  success += 1
                else
                  error "to_db: failed #{key}"
                  stats_increment_local "transfer.to_db.failure"
                end
              else
                error "to_db: not set #{key}"
              end
            else
              d{ "to_db: no value #{key}" }
            end
          else
            error "to_db: already dumped #{key}"
          end
        end

        return success
      end

      return success
    end

    DEL_RESTORE =
<<EOF
  if redis.call('get', KEYS[1]) == ARGV[2] then
    redis.call('del', KEYS[1])
    return redis.call('restore', KEYS[1], 0, ARGV[1])
  else
    return false
  end
EOF

    def self.from_db(player_id, zone)
      redis = get_redis zone
      backup = MysqlBackup.new(zone)

      keys = transferrable_keys(player_id, zone).reverse
      success = 0

      keys.each do |key|
        begin
          dumped = false
          dumped = (redis.get(key) == backup.tag)
        rescue Redis::CommandError => e
          # if wrong key type, means not dumped yet
          if e.message !~ WRONG_KIND_OF_VALUE_REGEX
            raise e
          end
        end

        if dumped
          val = backup.get(key)
          if val
            val = val.force_encoding('utf-8')
            res = redis.evalsmart(DEL_RESTORE,
              :keys => [ key ], :argv => [ val, backup.tag ])
            if res then
              info "from_db: success #{key}"
              stats_increment_local "transfer.from_db.success"
              success += 1
            else
              error "from_db: restore failed #{key}"
              stats_increment_local "transfer.from_db.failure"
              return success
            end
          else
            error "from_db: no value #{key}"
          end
        else
          # info "from_db: not dumped #{key}"
        end
      end

      stats_increment_local 'load.restore'

      return success
    end

  private

  end

  class KyotoBackup

    BACKUP_TAG = '#kyoto#'

    def initialize(zone)
      @db = KyotoFactory.kyoto(zone)
    end

    def tag
      BACKUP_TAG
    end

    def get(key)
      @db.get(key)
    end

    def set(key, value)
      @db.set(key, value)
    end

  end

  class MysqlBackup

    DATA_MYSQL_NAME = 'data'
    BACKUP_TAG = '#mysql#'
    TABLE_NAME = 'data'

    def initialize(zone)
      @db = MysqlFactory.mysql(DATA_MYSQL_NAME, zone)
    end

    def tag
      BACKUP_TAG
    end

    def get(key)
      result = @db.query("SELECT v from #{TABLE_NAME} WHERE k='%s';" % [ key ])
      if result and result.count > 0
        result.first['v']
      else
        nil
      end
    end

    def set(key, value)
      value = @db.escape(value)
      result = @db.query("SELECT k from #{TABLE_NAME} WHERE k = '%s';" % [ key ])

      if result and result.count > 0
        if result.first['k'] == key
          # case matches
          @db.query("UPDATE #{TABLE_NAME} SET v = '%s', updated_at = '%s' WHERE k = '%s';" %
            [ value, Time.now.strftime("%Y-%m-%d %H:%M:%S"), key ])
          return true
        else
          # fail for case not matching
          return false
        end
      else
        @db.query("INSERT INTO #{TABLE_NAME} SET k = '%s', v = '%s', created_at = '%s';" %
          [ key, value, Time.now.strftime("%Y-%m-%d %H:%M:%S") ])
        return true
      end
    end

  end

end