module Stats
	module GeneratorHelper
		def each_zone_sdk_platform
	    zones = StatsModels::Zone.select("distinct zone_id").order(:zone_id)
	    sdks = StatsModels::Sdk.where("sdk is not null").select("distinct sdk").order(:sdk)
	    platforms = StatsModels::Platform.where("platform is not null").select("distinct platform").order(:platform)

	    return if zones.nil? || sdks.nil? || platforms.nil?

	    zones << 0
	    platforms << 'all'
	    zones.each do |czone|
        platforms.each do |cplatform|
          zone_id = czone
          zone_id = czone.zone_id if czone != 0

          platform = cplatform
          platform = cplatform.platform if cplatform != 'all'

          yield zone_id, 'all', platform if block_given?
        end
	    end

	    sdks.each do |csdk|
	    	platforms.each do |cplatform|
		    	sdk = csdk.sdk 
		    	platform = cplatform
          platform = cplatform.platform if cplatform != 'all'
		    	yield 0, sdk, platform if block_given?
		    end
	    end
	  end
	end
end