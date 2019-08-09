module EventsCampaignExpHelper
  def get_campaign_zone_name(tid)
    if tid and not tid.empty?
      "#{tid}-" + GameConfig.strings["str_#{tid}_name"].to_s
    else
      ''
    end
  end

  def get_campaign_zones
    ::Hash[GameConfig.campaigns.values.map do |x|
      [x.tid, x.tid + '-' + GameConfig.strings[x.name]]
    end]
  end
end
