module Stats
	module NewPlayerRechargeGenerator
		def gen_new_player_recharge_report
			date = @options[:date].to_date
			records = StatsModels::recharge_record.all.to_a
			
			each_zone_sdk_platform do |zone_id, sdk, platform|

			end
		end
	end
end