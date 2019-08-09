class ChiefLevelParser
  include Stats::StatsParser
  include Stats::ExcludePlayers

   public

  def on_start
    @users = {}
    @stats = {}
  end

  def parse_command(record_time, command, param)
    #puts "param is ====== #{param}"
    level, user_id, zone_id, deviceID, platform, sdk = param.split(",").map{|x| x.strip}
    
    zone_id = zone_id.to_i
    user_id = user_id.downcase

    return if player_exclude?(user_id)

    @users[zone_id] ||= {}
    [@users[zone_id]].each do |zdata|
      zdata ||= {}
      zdata[user_id] ||= {:level => level.to_i}
      #puts "zone_id is #{zone_id}, user_id is:#{user_id}, level is:#{level}}"

      if level.to_i > zdata[user_id][:level]
        zdata[user_id][:level] = level.to_i
      end
    end

  end

  def on_finish
    date = @options[:date].to_date
    counter = 0

    @users.each do|zid, zdata|
      @stats[zid] ||= {}
      zdata.each do|uid, udata|
        @stats[zid][udata[:level]] ||= {:num => 0}
        @stats[zid][udata[:level]][:num] += 1
      end
    end

    @stats.each do |zone_id, zdata|
      zdata.each do |level, data|
        counter += 1
        puts "#{Time.now} [ChiefLevelParser] #{counter} ".color(:cyan) + "records has been saved" if counter % 1000 == 0

        record = StatsModels::ChiefLevelReport.where(:date => date, :zone_id => zone_id, :level => level).first_or_initialize

        record.num = data[:num]

        record.save
      end
    end

    puts "#{Time.now} [ChiefLevelParser] #{counter}".color(:cyan) + " records has been saved, commit finished"
  end 
end