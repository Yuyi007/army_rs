class CampaignReportParser
  include Stats::StatsParser
  include Stats::ExcludePlayers

   public

  def on_start
  	@stats = {}
  	@players = {}
  end

  def parse_command(record_time, command, param)
  	case command
  	when 'start_campaign'
  		parse_start(record_time, param)
  	when 'finish_campaign'
			parse_finish(record_time, param)
		end
  end

  def parse_start(record_time, param)
  	cid, kind, uid, level, zone, level, city_id, guild_sid = param.split(",").map{|x| x.strip}
  	zone_id = zone.to_i

    return if player_exclude?(uid)

  	@players['start'] ||= {}
  	@stats['start'] ||= {}

  	sdata = @stats['start'] 
  	sdata[zone_id] ||= {}

  	psdata = @players['start']
  	psdata[zone_id] ||= {}

  	zdata = sdata[zone_id]
  	zdata[cid] ||= {:num => 0, :players => 0}
  	pzdata = psdata[zone_id]
  	pzdata[cid] ||= {}

  	cdata = zdata[cid]
  	cdata[:num] += 1

  	pcdata = pzdata[cid]
  	if pcdata[uid].nil? 
	  	cdata[:players] += 1
	  	pcdata[uid] = true
	  end
  end

  def parse_finish(record_time, param)
  	cid, win, type, uid, level, zone = param.split(",").map{|x| x.strip}
  	zone_id = zone.to_i
    
    return  if player_exclude?(uid)

  	@players['finish'] ||= {}
  	@stats['finish'] ||= {}

  	sdata = @stats['finish'] 
  	sdata[zone_id] ||= {}

  	psdata = @players['finish']
  	psdata[zone_id] ||= {}

  	zdata = sdata[zone_id]
  	zdata[cid] ||= {:num => 0, :players => 0}
  	pzdata = psdata[zone_id]
  	pzdata[cid] ||= {}

  	cdata = zdata[cid]
  	cdata[:num] += 1

  	pcdata = pzdata[cid]
  	if pcdata[uid].nil? 
	  	cdata[:players] += 1
	  	pcdata[uid] = true
	  end
  end

  def on_finish
  	date = @options[:date].to_date
    counter = 0
  	@stats.each do |cat, cadata|
  		cadata.each do |zone_id, zdata|
  			zdata.each do |cid, cdata|
  				counter += 1
  				num = cdata[:num]
  				players = cdata[:players]
  				record = StatsModels::CampaignReport.where(:date => date, :zone_id => zone_id, :cid => cid, :cat => cat).first_or_initialize
  				record.num = num
  				record.players = players
  				record.save
  			end
  		end
  	end
  	puts "#{Time.now} [CampaignReportParser] #{counter} ".color(:cyan) + "records has been saved" 
  end
 end
