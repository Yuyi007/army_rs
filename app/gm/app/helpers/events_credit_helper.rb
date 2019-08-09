module EventsCreditHelper
  def getPackageContent(package)
    return '' if package.nil?
    package.drops.map do |x|
      get_config_name(x['tid']) + 'x' + x['num'].to_s
    end.join("\n")
  end

  def getRewardsContent(rewards)
    rewards.each do |x|
      x.content = getPackageContent(x.package)
    end
    rewards.map.with_index do |x, index|
      ["=================", x.content].join("\n")
    end.join("\n\n")
  end

  def get_config_name(tid)
    GameConfig.strings["str_#{tid}_name"].to_s + "[#{tid}]"
  end
end
