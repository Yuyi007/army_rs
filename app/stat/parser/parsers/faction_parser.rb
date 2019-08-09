class FactionParser
  include Stats::StatsParser
  include Stats::ExcludePlayers

   public

  def on_start
    @stats = {}
  end

  def parse_command(record_time, command, param)
    zone_id, pid, faction = param.split(",").map{|x| x.strip}
    zone_id = zone_id.to_i
    return if player_exclude?(pid)

    @stats[zone_id] ||= {}
    @stats[zone_id][pid] = faction
  end

  def on_finish
    counter = 0
    @stats.each do |zone_id, zdata|
      zdata.each do |pid, faction|
        player = StatsModels::ZoneUser.where(:sid => pid.downcase).first
        next if player.nil? || player.sdk.nil? || player.platform.nil? 

        counter += 1
        puts "#{Time.now} [FactionParser] #{counter} ".color(:cyan) + "records has been saved" if counter % 1000 == 0
        record = StatsModels::AllFaction.where(:pid => pid, :zone_id => zone_id).first_or_initialize
        record.faction = faction
        record.sdk = player.sdk
        record.platform = player.platform
        record.save
      end
    end
    puts "#{Time.now} [FactionParser] #{counter}".color(:cyan) + "records has been saved, commit finished"

  end
end