module EventsXuezhanHelper
  def getRewardName(tid)
    e = GameConfig.xuezhanNewConfig.activeBonus[tid]
    "#{e.tid}-#{e.heroNum}" if e
  end
end
