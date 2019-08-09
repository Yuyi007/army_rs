module Stats
  module MainQuestUserGenerator
    def gen_main_quest_user_report
      date = @options[:date].to_date
      records = StatsModels::MainQuestUsers.all
      each_zone_sdk_platform do |zone_id, sdk, platform|
        data = {}
        records.each do |rc|
        
          data[zone_id] ||= {}
          next if rc.zone_id != zone_id && zone_id != 0

          data[zone_id][sdk] ||= {}
          next if rc.sdk != sdk && sdk != 'all'

          data[zone_id][sdk][platform] ||= {}
          next if rc.platform != platform && platform != 'all'

          data[zone_id][sdk][platform][rc.qid] ||= 0
          data[zone_id][sdk][platform][rc.qid] += 1 
        end
      
        data.each do |zone_id, zdata|
          zdata.each do |sdk, sdata|
            sdata.each do |platform, pdata|
              pdata.each do |qid, num|
                cond = {
                  :date => date, 
                  :zone_id => zone_id.to_i, 
                  :platform => platform, 
                  :sdk => sdk, 
                  :qid => qid
                }
                mqur = StatsModels::MainQuestUsersReport.where(cond).first_or_initialize
                mqur.num = num
                mqur.save
              end
            end
          end
        end
      end
      puts "[MainQuestUserGenerator.gen_main_quest_user_report]".color(:green)+" complete"
    end
  end
end