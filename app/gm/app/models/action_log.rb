
class ActionLog < ActiveRecord::Base

  attr_accessible :player_id, :zone, :t, :created_at, :param1, :param2, :param3, :param4, :param5, :param6

  self.per_page = 50

  def self.search(player_id, zone, t, created_at_s, created_at_e,
    param1, param2, param3, param4, param5, param6,
    sort, direction, page, per_page)

    sort = (not sort.nil? or ActionLog.column_names.include? sort) ? sort : 'created_at'
    direction = (direction.nil? or direction.downcase == 'desc') ? 'desc' : 'asc'
    page = 1 if page.to_i == 0
    per_page = self.per_page if per_page.to_i == 0

    queries = []
    fields = {}
    unless player_id.blank?
      queries << 'player_id = :player_id'
      fields[:player_id] = player_id
    end
    unless zone.blank?
      queries << 'zone = :zone'
      fields[:zone] = zone
    end
    unless t.blank?
      queries << 't = :t'
      fields[:t] = t
    end
    unless created_at_s.blank?
      queries << 'created_at >= :created_at_s'
      fields[:created_at_s] = TimeHelper.parse_date_time(created_at_s)
    end
    unless created_at_e.blank?
      queries << 'created_at <= :created_at_e'
      fields[:created_at_e] = TimeHelper.parse_date_time(created_at_e)
    end
    unless param1.blank?
      queries << 'param1 like :param1'
      fields[:param1] = param1
    end
    unless param2.blank?
      queries << 'param2 like :param2'
      fields[:param2] = param2
    end
    unless param3.blank?
      queries << 'param3 like :param3'
      fields[:param3] = param3
    end
    unless param4.blank?
      queries << 'param4 like :param4'
      fields[:param4] = param4
    end
    unless param5.blank?
      queries << 'param5 like :param5'
      fields[:param5] = param5
    end

    unless param6.blank?
      queries << 'param6 like :param6'
      fields[:param6] = param5
    end

    where(queries.join(' AND '), fields)
    .order("#{sort} #{direction}")
    .paginate(:page => page, :per_page => per_page)
  end

  def self.process_remain_logs
    total = 0

    while true do
      data = ActionDb.redis.rpop(ActionDb.key)
      break unless data
      log = MessagePack.unpack(data)
      hash = { :player_id => log[0], :zone => log[1], :t => log[2], :created_at => Time.at(log[3]) }
      hash[:param1] = log[4] if log.length > 4
      hash[:param2] = log[5] if log.length > 5
      hash[:param3] = log[6] if log.length > 6
      hash[:param4] = log[7] if log.length > 7
      hash[:param5] = log[8] if log.length > 8
      hash[:param6] = log[9] if log.length > 9

      puts ">>>>>action hash:#{hash}"
      ActionLog.create(hash)

      total += 1
    end

    total
  end

  def self.delete_old(days)
    where("created_at >= :old_time",
      [ :old_time => Time.now.to_i - days.to_i * 3600 * 24 ]).destroy_all
  end

end
