class GuildActiveParser
  include Stats::StatsParser
  include Stats::ExcludePlayers
  include Stats::GeneratorHelper 
  include Stats::GuildActiveGenerator

  public

  def on_start
    @stats = {}
  end

  def parse_command(record_time, command, param)
    active_type, zone_id, pid, guild_id  = param.split(",").map{|x| x.strip}
    return if player_exclude?(pid)
       
    @stats[active_type] ||= {}
    @stats[active_type][zone_id] ||= {}
    @stats[active_type][zone_id][guild_id] ||= {}
    @stats[active_type][zone_id][guild_id][pid] = true
  end

  def on_finish
    date = @options[:date].to_date
    # StatsModels::GuildActive.delete_all
    all = []
    counter = 0
    @stats.each do |active_type, active_zone_data|
      active_zone_data.each do |zone_id, active_zond_data|
        active_zond_data.each do |guild_id, guild_players|
          guild_players.each do |pid, _|
            player = StatsModels::ZoneUser.where(:sid => pid.downcase).first
            next if player.nil? || player.sdk.nil? || player.platform.nil? 
            
            counter += 1
            puts "#{Time.now} [GuildActiveParser] #{counter} ".color(:cyan) + "records has been saved"  if counter % 1000 == 0
            record = StatsModels::GuildActive.new
            record.date = date
            record.zone_id = zone_id
            record.sdk = player.sdk
            record.platform = player.platform
            record.guild_id = guild_id
            record.active_type = active_type
            all << record
          end
        end
      end
    end

    gen_giuld_active_report_by_records(all, date)
  end
end