class AddEquipParser
  include Stats::StatsParser
  include Stats::ExcludePlayers

   public

  def on_start
    @stats = {}
	end

	def parse_command(record_time, command, param)
		reason, tid, level, star, grade, suit_id, skill_num, player_id, zone_id, hero_level = param.split(",").map{|x| x.strip}
		level = level.to_i
		star = star.to_i
		grade = grade.to_i
		skill_num = grade.to_i
		hero_level = hero_level.to_i
		zone_id = zone_id.to_i

    return  if player_exclude?(player_id)
    
		@stats[zone_id] ||= {}
      zdata = @stats[zone_id]

      zdata[reason] ||= {}
      rdata = zdata[reason]

      rdata[grade] ||= {}
      gdata = rdata[grade]

      gdata[star] ||= {:suits => 0, :scarces => 0, :normals => 0}
      sdata = gdata[star]

      if suit_id.nil? || suit_id.empty?
      	sdata[:suits] += 1
      elsif skill_num >= 0 
      	sdata[:scarces] += 1
      else
      	sdata[:normals] += 1
      end
	end

	def on_finish
    date = @options[:date].to_date
    counter = 0

    @stats.each do |zone_id, zdata|
    	zdata.each do |reason, rdata|
	    	rdata.each do |grade, gdata|
	    		gdata.each do |star, sdata|
	    			counter += 1
	    			record = StatsModels::AddEquipReport.where(:date => date, :zone_id => zone_id, :reason => reason, :grade => grade, :star => star).first_or_initialize
	    			record.suits = sdata[:suits]
	    			record.scarces = sdata[:scarces]
	    			record.normals = sdata[:normals]
            record.save
	    		end
	    	end
    	end
    end
    puts "#{Time.now} [AddEquipParser] #{counter}".color(:cyan) + " records has been saved, commit finished"
  end

end