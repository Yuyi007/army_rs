# archive_data.rb

module Boot

  ARCHIVE_MYSQL_NAME = 'archive'

  # an Archive is a point-to-time backup of player model data
  class ArchiveData

    include Loggable
    include Statsable

    def self.try_archive(player_id, zone)
      archiver = get_archiver zone
      criteria = get_criteria
      success = false

      cur_archive_times = archiver.get_archive_times(player_id, zone)
      d{ "try_archive: #{player_id} #{zone} archives #{cur_archive_times}"}

      if criteria.should_archive? cur_archive_times
        success, time = self.do_archive(archiver, criteria, player_id, zone)
        cur_archive_times << time if success
      else
        d{ "try_archive: ignoring #{player_id} #{zone}"}
      end

      del_archive_times = criteria.get_obsolete_archive_times cur_archive_times
      if del_archive_times
        d{ "try_archive: to delete #{player_id} #{zone} #{del_archive_times}"}
        archiver.delete(player_id, zone, del_archive_times)
      end

      success
    end

    def self.get_archive_times(player_id, zone)
      archiver = get_archiver zone
      archiver.get_archive_times(player_id, zone)
    end

    def self.get_archive_model(player_id, zone, time)
      archiver = get_archiver zone
      data = archiver.get_archive_data(player_id, zone, time)
      data ? Model.new.load!(data) : nil
    end

    def self.delete_archive(player_id, zone, time)
      archiver = get_archiver zone
      archiver.delete(player_id, zone, [ time ])
    end

    def self.delete_archive_older_than(zone, time)
      archiver = get_archiver zone
      archiver.delete_older_than zone, time
    end

    def self.set_criteria criteria
      @@criteria = criteria
    end

  private

    def self.get_criteria
      @@criteria ||= StaticArchiveCriteria.new
    end

    def self.get_archiver(zone)
      if MysqlFactory.mysql_cfg(ARCHIVE_MYSQL_NAME, zone)
        MysqlArchiver.new(zone)
      else
        DefaultArchiver.new(zone)
      end
    end

    def self.do_archive(archiver, criteria, player_id, zone)
      model = GameData.read(player_id, zone)

      if model
        if criteria.should_archive_model? model
          info "do_archive: save #{player_id} #{zone}"
          stats_increment_local "archiver.save"
          archiver.save(player_id, zone, model.dump)
        else
          info "do_archive: ignoring #{player_id} #{zone}"
          false
        end
      else
        error "do_archive: no model found for #{player_id} #{zone}!"
        false
      end
    end

  end

  # evict oldest archive
  class BasicArchiveCriteria

    # default values
    MAX_ARCHIVES = 10
    MIN_ARCHIVE_INTERVAL = 2 * 60 * 60 # seconds

    include Loggable

    def initialize max_archives = MAX_ARCHIVES, min_archive_interval = MIN_ARCHIVE_INTERVAL
      @max_archives = max_archives
      @min_archive_interval = min_archive_interval
    end

    # this is to be overrided with game model requires
    def should_archive_model? model
      (model != nil)
    end

    def should_archive? cur_archive_times
      cur_archive_times.length == 0 or
      (Time.now - cur_archive_times.sort.last).to_i >= @min_archive_interval
    end

    def get_obsolete_archive_times cur_archive_times
      n = cur_archive_times.length - @max_archives
      cur_archive_times.sort.first(n > 0 ? n : 0)
    end

  end

  # evict archives according to static rules
  class StaticArchiveCriteria < BasicArchiveCriteria

    # each duration segments allow max one archive
    # days =                    1       2   3   4    5    7    9   12   15   20   25   30
    HOURS = [ 3, 6, 9, 12, 18, 24, 36, 48, 72, 96, 120, 168, 216, 288, 360, 480, 600, 720 ]

    def initialize
      @max_archives = HOURS.length
      @min_archive_interval = MIN_ARCHIVE_INTERVAL
    end

    def get_obsolete_archive_times cur_archive_times
      n = cur_archive_times.length - @max_archives
      return nil if n <= 0

      now = Time.now
      obsolete = []
      marks = {}

      hours = cur_archive_times.map { |time| ((now - time) / 3600).to_f } # convert to hours
      d{ "hours=#{hours}"}

      hours.each_with_index do |hour, i|
        break if obsolete.length >= n
        match_hour = HOURS.last
        HOURS.reverse_each { |h| if hour < h then match_hour = h else break end }
        if not marks[match_hour]
          marks[match_hour] = 1
        else
          obsolete << cur_archive_times[i]
        end
      end

      d{ "marks=#{marks}"}
      d{ "obsolete=#{obsolete}"}
      obsolete
    end

  end

  #################################################
  # Archiver db layer

  class DefaultArchiver

    include Loggable

    def initialize(zone)
    end

    def get_archive_times(player_id, zone)
      []
    end

    def get_archive_data(player_id, zone, time)
      nil
    end

    def save(player_id, zone, data)
      d { "DefaultArchiver: #{player_id} #{zone}" }
      return true
    end

    def delete(player_id, zone, archive_times)
      return true
    end

    def delete_older_than(zone, time)
      return true
    end

  end

  class MysqlArchiver < DefaultArchiver

    TABLE_NAME = 'archive'

    include Loggable

    def initialize(zone)
      @db = MysqlFactory.mysql(ARCHIVE_MYSQL_NAME, zone)
    end

    def get_archive_times(player_id, zone)
      result = @db.query("SELECT updated_at from #{TABLE_NAME} WHERE player_id='%s' and zone='%d';" % [ player_id, zone ])
      res = []
      if result and result.count > 0
        result.each do |row|
          res << row['updated_at']
        end
      end
      res
    end

    def get_archive_data(player_id, zone, time)
      result = @db.query("SELECT data from #{TABLE_NAME} WHERE player_id='%s' and zone='%d' and updated_at = '%s';" %
        [ player_id, zone, time.strftime("%Y-%m-%d %H:%M:%S") ])

      if result and result.count > 0
        result.first['data']
      else
        nil
      end
    end

    def save(player_id, zone, data)
      data = @db.escape(data)
      now = Time.now

      result = @db.query("INSERT INTO #{TABLE_NAME} SET player_id = '%s', zone = '%d', data = '%s', updated_at = '%s';" %
        [ player_id, zone, data, now.strftime("%Y-%m-%d %H:%M:%S") ])
      d{ "save: #{player_id} #{zone} data=#{data.length} result=#{result}" }

      return true, now
    end

    def delete(player_id, zone, archive_times)
      archive_times.each do |time|
        result = @db.query("DELETE FROM #{TABLE_NAME} WHERE player_id = '%s' and zone = '%d' and updated_at = '%s';" %
          [ player_id, zone, time.strftime("%Y-%m-%d %H:%M:%S") ] )
        d{ "delete: #{player_id} #{zone} #{time} result=#{result}" }
      end

      return true
    end

    def delete_older_than(zone, time)
      result = @db.query("DELETE FROM #{TABLE_NAME} WHERE zone = '%d' and updated_at < '%s';" %
        [ zone, time.strftime("%Y-%m-%d %H:%M:%S") ] )
      d{ "delete_older_than: #{zone} #{time} result=#{result}" }

      return true
    end

  end

end