class CityEventLevelParser
  include Stats::StatsParser
  include Stats::ExcludePlayers

   public

  def on_start
    @players1 = {}
    @stats1 = {}
  end

  def parse_command(record_time, command, param)
    level, uid, zone_id, platform = param.split(",").map{|x| x.strip}
    zone_id = zone_id.to_i
    uid = uid.downcase

    return if player_exclude?(uid)

    @players1[zone_id] ||= {}
    [@players1[zone_id]].each do |zdata|
      zdata ||= {}
      zdata[uid] ||= {:level => level.to_i}

      if level.to_i > zdata[uid][:level]
        zdata[uid][:level] = level.to_i
      end
    end

  end

  def on_finish
    date = @options[:date].to_date
    counter = 0

    @players1.each do|zid, zdata|
      @stats1[zid] ||= {}
      zdata.each do|uid, udata|
        @stats1[zid][udata[:level]] ||= {:num => 0}
        @stats1[zid][udata[:level]][:num] += 1
      end
    end

    @stats1.each do |zone_id, zdata|
      zdata.each do |level, data|
        counter += 1
        puts "#{Time.now} [CityEventLevelParser] #{counter} ".color(:cyan) + "records has been saved" if counter % 1000 == 0

        record = StatsModels::CityEventLevelReport.where(:date => date, :zone_id => zone_id, :level => level).first_or_initialize

        record.num = data[:num]

        record.save
      end
    end

    puts "#{Time.now} [CityEventLevelParser] #{counter}".color(:cyan) + " records has been saved, commit finished"
  end
end