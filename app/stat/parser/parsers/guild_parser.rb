class GuildParser
  include Stats::StatsParser

  public

  def on_start
    @stats = {}
    @players_map = {}
    @guild_data = {}  #by guild id

  end

  def parse_command(record_time, command, param)
    guild_id, zone_id, guild_level, guild_size  = param.split(",").map{|x| x.strip}
    @guild_data[guild_id.to_s] = {
      :zone => zone_id.to_i,
      :guild_level => guild_level.to_i,
      :guild_size => guild_size.to_i,
    }
  end

  def on_finish
    date = @options[:date].to_date
    @guild_data.each do |guild_id, guild_data|
        guild = StatsModels::Guild.where(:guild_id => guild_id, :zone => guild_data[:zone]).first_or_initialize
        guild.level = guild_data[:guild_level]
        guild.member_size = guild_data[:guild_size]
        guild.zone = guild_data[:zone]
        res = guild.save
    end
    puts "check date: #{date}"
    @guild_record = {}
    all_guilds = StatsModels::Guild.all
    if all_guilds
        all_guilds.each do |guild|
            str_guild_zone = guild.zone.to_s
            @guild_record[str_guild_zone] ||= {}
            level_str = get_level_str(guild.level)
            puts "check level #{guild.level}, #{level_str}"
            @guild_record[str_guild_zone][level_str] ||= 0
            @guild_record[str_guild_zone]["#{level_str}_person"] ||= 0
            @guild_record[str_guild_zone][level_str] += 1
            @guild_record[str_guild_zone]["#{level_str}_person"] += guild.member_size
        end
        @guild_record.each do |zone_s, record_data|
            puts "check guild data: #{zone_s}, #{record_data}"
            guild_record = StatsModels::GuildLevelRecord.where(:record_date => date, :zone => zone_s.to_i).first_or_initialize
            record_data.each do |key, value|
                puts "check key:#{key}, value:#{value}"
                guild_record.send("#{key}=", value)
            end
            guild_record.save()
        end
    end
  end

  def get_level_str(level)
    return "level_#{level}" if level <= 10
    return "level_11_15" if level <= 15
    return "level_16_20" if level <= 20
    return "level_21_25" if level <= 25
    return "level_26_30" if level <= 30
    return "level_over_30"
  end

end