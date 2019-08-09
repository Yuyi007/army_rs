#金币总计
class AlterCreditTotalParser
  include Stats::StatsParser
  include Stats::ExcludePlayers

   public

  def on_start
    @stats = {}
  end

  def parse_command(record_time, command, param)
    reason, value, credits, cid, pid, zone_id = param.split(",").map{|x| x.strip}
    zone_id = zone_id.to_i
    pid = pid.downcase
    value = value.to_i

    if player_exclude?(pid)
       
      return 
    end

    @stats[zone_id] ||= {}
    zdata = @stats[zone_id]
    zdata[:total_inc] ||= 0
    zdata[:total_dec] ||= 0
    zdata[:total_inc] += value if value > 0
    zdata[:total_dec] += value if value < 0
    zdata[:users] ||= {}
    zdata[:users][pid] ||= {}
    zdata[:users][pid]['inc'] ||= 0
    zdata[:users][pid]['dec'] ||= 0
    zdata[:users][pid]['inc'] += value if value > 0
    zdata[:users][pid]['dec'] += value if value < 0
  end

  def on_finish
    date = @options[:date].to_date
    counter = 0

    @stats.each do |zone_id, zdata|
      counter += 1
      puts "#{Time.now} [AlterCreditTotalParser] #{counter} ".color(:cyan) + "records has been saved" if counter % 1000 == 0

      max = 0
      min = 0
      max_uid = ''
      min_uid = ''

      zdata[:users].each do |uid, v|
        if v['inc']>max
          max = v['inc']
          max_uid = uid
        end
        if v['dec']<min
          min = v['dec']
          min_uid = uid
        end
      end

      record = StatsModels::AlterCreditsTotalReport.where(:date => date, :zone_id => zone_id).first_or_initialize
      record.date = date
      record.zone_id = zone_id
      record.max_uid = max_uid
      record.min_uid = min_uid
      record.max = max
      record.min = min
      record.total_inc = zdata[:total_inc]
      record.total_dec = zdata[:total_dec]
      record.save
    end
    puts "#{Time.now} [AlterCreditTotalParser] #{counter}".color(:cyan) + " records has been saved, commit finished"
  end
end