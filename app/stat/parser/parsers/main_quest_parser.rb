class MainQuestParser
  include Stats::StatsParser
  include Stats::ExcludePlayers

   public

  def on_start
  	@stats = {}
  end

  def parse_command(record_time, command, param)
  	zone, pid, tid = param.split(",").map{|x| x.strip}
    zone_id = zone.to_i
    return if player_exclude?(pid)

    @stats[zone_id] ||= {}
    zdata = @stats[zone_id]
    zdata[pid] = tid
  end

  def on_finish
  	counter = 0
  	date = @options[:date].to_date
  	data = {}
    users = {}

  	@stats.each do |zone_id, zdata|
  		data[zone_id] ||= {}
      users[zone_id] ||= {}

  		z = data[zone_id]
      u = users[zone_id]

  		zdata.each do |pid, tid|
  			z[tid] ||= 0
  			z[tid] += 1
        u[pid] = tid
  		end
  	end

    counter = 0
    users.each do |zone_id, zdata|
      zdata.each do |pid, tid|
        player = StatsModels::ZoneUser.where(:sid => pid.downcase).first
        next if player.nil? || player.sdk.nil? || player.platform.nil? 

        counter += 1
        puts "#{Time.now} [MainQuestParser][MainQuestUsers] #{counter}".color(:cyan) + " records has been saved" if counter % 1000 == 0  
        cond = {
          :zone_id => zone_id, 
          :pid => pid,
          :sdk => player.sdk,
          :platform => player.platform
        }
        rc = StatsModels::MainQuestUsers.where(cond).first_or_initialize
        rc.qid = tid
        rc.save
      end
    end
    puts "#{Time.now} [MainQuestParser][MainQuestUsers] #{counter}".color(:cyan) + " records has been saved, commit finished" if counter % 1000 == 0  

    counter = 0
    #玩家记录提供流失查询
    users.each do |zone_id, zdata|
      zdata.each do |pid, tid|
        counter += 1
        puts "#{Time.now} [MainQuestParser][PlayerRecord] #{counter}".color(:cyan) + " records has been saved" if counter % 1000 == 0  
        #主线任务
        player_record = StatsModels::PlayerRecord.where(:pid => pid.downcase, :kind => 'main_quest').first_or_initialize
        player_record.data = tid
        player_record.save
      end
    end
    puts "#{Time.now} [MainQuestParser][PlayerRecord] #{counter}".color(:cyan) + " records has been saved, commit finished" if counter % 1000 == 0  

    counter = 0
  	data.each do |zone_id, zdata|
  		zdata.each do |tid, num|
  			counter += 1
        puts "#{Time.now} [MainQuestParser][MainQuestReport] #{counter}".color(:cyan) + " records has been saved" if counter % 1000 == 0  
	  		rc = StatsModels::MainQuestReport.where(:date => date, :zone_id => zone_id, :tid => tid).first_or_initialize
	  		rc.num = num
	  		rc.save
	  	end
  	end

  	puts "#{Time.now} [MainQuestParser][MainQuestReport] #{counter}".color(:cyan) + " records has been saved, commit finished" 
  end
end