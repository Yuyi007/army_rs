class GuildSkillParser
  include Stats::StatsParser
  include Stats::ExcludePlayers

  public

  def on_start
    @stats = {}
    @players_map = {}
    @player_guild_skills = {}  #by guild id

  end

  def parse_command(record_time, command, param)
    pid, zone_id, guild_skill_1, guild_skill_2, guild_skill_3, guild_skill_4, guild_skill_5, guild_skill_6  = param.split(",").map{|x| x.strip}
    return if player_exclude?(pid)
      
    @player_guild_skills[pid.to_s] = {
      :zone_id => zone_id.to_i,
      :guild_skill_1 => guild_skill_1.to_i,
      :guild_skill_2 => guild_skill_2.to_i,
      :guild_skill_3 => guild_skill_3.to_i,
      :guild_skill_4 => guild_skill_4.to_i,
      :guild_skill_5 => guild_skill_5.to_i,
      :guild_skill_6 => guild_skill_6.to_i,
    }
  end

  def on_finish
    date = @options[:date].to_date
    @player_guild_skills.each do |pid, player_guild_data|
      player = StatsModels::ZoneUser.where(:sid => pid.downcase).first
      next if player.nil? || player.sdk.nil? || player.platform.nil? 

      record = StatsModels::GuildSkill.where(:pid => pid, :zone_id => player_guild_data[:zone_id]).first_or_initialize
      record.guild_skill_1 = player_guild_data[:guild_skill_1]
      record.guild_skill_2 = player_guild_data[:guild_skill_2]
      record.guild_skill_3 = player_guild_data[:guild_skill_3]
      record.guild_skill_4 = player_guild_data[:guild_skill_4]
      record.guild_skill_5 = player_guild_data[:guild_skill_5]
      record.guild_skill_6 = player_guild_data[:guild_skill_6]

      record.sdk = player.sdk
      record.platform = player.platform
      record.zone_id = player_guild_data[:zone_id]
      record.save
    end
  end

  def get_level_index(level)
    return -1 if level <= 0
    return ((level - 0.5) / 5).to_i
  end

end