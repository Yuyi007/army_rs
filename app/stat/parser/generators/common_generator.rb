module Stats
	module CommonGenerator
		def gen_retentions
      gen_retention(StatsModels::GameUser, StatsModels::UserRetentionReport)
      gen_retention(StatsModels::GameAccount, StatsModels::AccountRetentionReport)
      gen_retention(StatsModels::GameDevice, StatsModels::DeviceRetentionReport)

      gen_retention_by_key(StatsModels::ZoneUser, StatsModels::UserZoneIdRetentionReport, :zone_id)
      gen_retention_by_key(StatsModels::ZoneAccount, StatsModels::AccountZoneIdRetentionReport, :zone_id)
      gen_retention_by_key(StatsModels::ZoneDevice, StatsModels::DeviceZoneIdRetentionReport, :zone_id)

      num_sdk = StatsModels::Sdk.select("count(distinct sdk) as total").first.total

      if num_sdk > 1
        gen_retention_by_key(StatsModels::GameUser, StatsModels::UserSdkRetentionReport, :sdk)
        gen_retention_by_key(StatsModels::GameAccount, StatsModels::AccountSdkRetentionReport, :sdk)
        gen_retention_by_key(StatsModels::GameDevice, StatsModels::DeviceSdkRetentionReport, :sdk)
      end

      num_market = StatsModels::Market.select("count(distinct market) as total").first.total

      if num_market > 1
        gen_retention_by_key(StatsModels::GameUser, StatsModels::UserMarketRetentionReport, :market)
        gen_retention_by_key(StatsModels::GameAccount, StatsModels::AccountMarketRetentionReport, :market)
        gen_retention_by_key(StatsModels::GameDevice, StatsModels::DeviceMarketRetentionReport, :market)
      end

      num_platform = StatsModels::Platform.select("count(distinct platform) as total").first.total

      if num_platform > 1
        gen_retention_by_key(StatsModels::GameUser, StatsModels::UserPlatformRetentionReport, :platform)
        gen_retention_by_key(StatsModels::GameAccount, StatsModels::AccountPlatformRetentionReport, :platform)
        gen_retention_by_key(StatsModels::GameDevice, StatsModels::DevicePlatformRetentionReport, :platform)
      end

      puts "[ReportGenerator.gen_retentions]".color(:green)+" complete"
    end

    def gen_retention_by_key(dataModel, reportModel, key)
      date = @options[:date].to_date
      days = *(0..30)
      days << 90
      days.to_a.each do |n|
        reg_date = date - n
        records = dataModel.where(["reg_date = :reg_date and last_login_at between :last_login_at_start and :last_login_at_end and #{key} is not null", \
                                  {reg_date: reg_date, last_login_at_start: date, last_login_at_end: date + 1}]) \
                  .select("#{key}, count(distinct sid) as total") \
                  .group(key)

        records.each do |record|
          report = reportModel.where(:date => reg_date, key => record.send(key)).first_or_initialize
          report.send("num_d#{n}=".to_sym, record.total)
          report.save if record.total > 0
        end
      end
    end

    def gen_retention(dataModel, reportModel)
      date = @options[:date].to_date
      days = *(0..30)
      days << 90
      days.to_a.each do |n|
        reg_date = date - n
        records = dataModel.where(["reg_date = :reg_date and last_login_at between :last_login_at_start and :last_login_at_end", \
                                  {reg_date: reg_date, last_login_at_start: date, last_login_at_end: date + 1}]) \
                  .select("count(distinct sid) as total")

        records.each do |record|
          report = reportModel.where(:date => reg_date).first_or_initialize
          report.send("num_d#{n}=".to_sym, record.total)
          report.save if record.total > 0
        end
      end
    end

    def gen_activities
      gen_activity(StatsModels::GameUser, StatsModels::UserActivityReport)
      gen_activity(StatsModels::GameAccount, StatsModels::AccountActivityReport)
      gen_activity(StatsModels::GameDevice, StatsModels::DeviceActivityReport)

      gen_activity(StatsModels::GameUser, StatsModels::NewUserActivityReport, nil, true)
      gen_activity(StatsModels::GameAccount, StatsModels::NewAccountActivityReport, nil, true)
      gen_activity(StatsModels::GameDevice, StatsModels::NewDeviceActivityReport, nil, true)

      gen_activity(StatsModels::ZoneUser, StatsModels::UserZoneIdActivityReport, :zone_id)
      gen_activity(StatsModels::ZoneUser, StatsModels::NewUserZoneIdActivityReport, :zone_id, true)

      gen_activity(StatsModels::ZoneAccount, StatsModels::AccountZoneIdActivityReport, :zone_id)
      gen_activity(StatsModels::ZoneAccount, StatsModels::NewAccountZoneIdActivityReport, :zone_id, true)

      gen_activity(StatsModels::ZoneDevice, StatsModels::DeviceZoneIdActivityReport, :zone_id)
      gen_activity(StatsModels::ZoneDevice, StatsModels::NewDeviceZoneIdActivityReport, :zone_id, true)

      num_sdk = StatsModels::Sdk.select("count(distinct sdk) as total").first.total

      if num_sdk > 1
        gen_activity(StatsModels::GameUser, StatsModels::UserSdkActivityReport, :sdk)
        gen_activity(StatsModels::GameUser, StatsModels::NewUserSdkActivityReport, :sdk, true)

        gen_activity(StatsModels::GameAccount, StatsModels::AccountSdkActivityReport, :sdk)
        gen_activity(StatsModels::GameAccount, StatsModels::NewAccountSdkActivityReport, :sdk, true)

        gen_activity(StatsModels::GameDevice, StatsModels::DeviceSdkActivityReport, :sdk)
        gen_activity(StatsModels::GameDevice, StatsModels::NewDeviceSdkActivityReport, :sdk, true)
      end

      num_platform = StatsModels::Platform.select("count(distinct platform) as total").first.total

      if num_platform > 1
        gen_activity(StatsModels::GameUser, StatsModels::UserPlatformActivityReport, :platform)
        gen_activity(StatsModels::GameUser, StatsModels::NewUserPlatformActivityReport, :platform, true)

        gen_activity(StatsModels::GameAccount, StatsModels::AccountPlatformActivityReport, :platform)
        gen_activity(StatsModels::GameAccount, StatsModels::NewAccountPlatformActivityReport, :platform, true)

        gen_activity(StatsModels::GameDevice, StatsModels::DevicePlatformActivityReport, :platform)
        gen_activity(StatsModels::GameDevice, StatsModels::NewDevicePlatformActivityReport, :platform, true)
      end

      puts "[ReportGenerator.gen_activities]".color(:green)+" complete"
    end

    def gen_activity(dataModel, reportModel, type = nil, isNew = false)
      date = @options[:date].to_date
      records = nil

      if type.nil?
        if not isNew 
          records = dataModel.where(["last_login_at between :last_login_at_start and :last_login_at_end", \
                                          {last_login_at_start: date, last_login_at_end: date + 1}]) \
                                   .select("round(active_secs / 300) as min, count(distinct sid) as subtotal") \
                                   .group(:min)

        else
          records = dataModel.where(["reg_date = :reg_date and last_login_at between :last_login_at_start and :last_login_at_end", \
                                          {reg_date: date, last_login_at_start: date, last_login_at_end: date + 1}]) \
                                   .select("round(active_secs / 300) as min, count(distinct sid) as subtotal") \
                                   .group(:min)
        end
      else
        if not isNew 
          records = dataModel.where(["last_login_at between :last_login_at_start and :last_login_at_end and #{type} is not null", \
                                          {last_login_at_start: date, last_login_at_end: date + 1}]) \
                                   .select("#{type}, round(active_secs / 300) as min, count(distinct sid) as subtotal") \
                                   .group(type, :min)

        else
          records = dataModel.where(["reg_date = :reg_date and last_login_at between :last_login_at_start and :last_login_at_end and #{type} is not null", \
                                          {reg_date: date, last_login_at_start: date, last_login_at_end: date + 1}]) \
                                   .select("#{type}, round(active_secs / 300) as min, count(distinct sid) as subtotal") \
                                   .group(type, :min)
        end
      end

      data = {}

      records.each do |record|
        if not type.nil?
          key = record.send(type)
        else
          key = 'all'        
        end

        data[key] ||= {}

        if record.min >= 0
          if record.min < 12
            data[key]["num_m#{(record.min+1)*5}"] ||= 0
            data[key]["num_m#{(record.min+1)*5}"] += record.subtotal
          else 
            if record.min < 24 && record.min >= 12
              data[key]['num_m120'] ||= 0
              data[key]['num_m120'] += record.subtotal
            elsif record.min < 48 && record.min >= 24
              data[key]['num_m180'] ||= 0
              data[key]['num_m180'] += record.subtotal
            elsif record.min < 60 && record.min >= 48
              data[key]['num_m300'] ||= 0
              data[key]['num_m300'] += record.subtotal
            else
              data[key]['m300plus'] ||= 0
              data[key]['m300plus'] += record.subtotal
            end
          end
        end
      end

      # generate reports
      data.each do |key, zdata|
        report = nil

        if type.nil?
          report = reportModel.where(:date => date).first_or_initialize
        else
          report = reportModel.where(:date => date, type => key).first_or_initialize
        end

        total = 0

        zdata.each do |column, value|
          total += value
          report.send("#{column}=".to_sym, value)
        end

        report.total = total

        report.save
      end
    end


    def gen_basics
      date = @options[:date].to_date
      records = StatsModels::ZoneUser.where(:reg_date => date).select("distinct sdk").order(:sdk)
      records.each do |record|
        unless record.sdk.nil? or record.sdk.strip.empty?
          sdk = StatsModels::Sdk.where(:sdk => record.sdk).first_or_initialize
          sdk.sdk = record.sdk
          sdk.save
        end
      end

      records = StatsModels::ZoneUser.where(:reg_date => date).select("distinct platform").order(:platform)

      records.each do |record|
        unless record.platform.nil? or record.platform.strip.empty?
          platform = StatsModels::Platform.where(:platform => record.platform).first_or_initialize
          platform.platform = record.platform
          platform.save
        end
      end

      records = StatsModels::ZoneUser.where(:reg_date => date).select("distinct market").order(:market)

      records.each do |record|
        unless record.market.nil? or record.market.strip.empty?
          market = StatsModels::Market.where(:market => record.market).first_or_initialize
          market.market = record.market
          market.save
        end
      end

      records = StatsModels::ZoneUser.where(:reg_date => date).select("distinct zone_id").order(:zone_id)

      records.each do |record|
        unless record.zone_id.nil? or record.zone_id == 0
          zone = StatsModels::Zone.where(:zone_id => record.zone_id).first_or_initialize
          zone.zone_id = record.zone_id
          zone.save
        end
      end
    end
	end
end