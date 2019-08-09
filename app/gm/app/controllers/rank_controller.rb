class RankController < ApplicationController

  include RsRails

  layout 'main'

  protect_from_forgery

  before_filter :require_user

  access_control do
    allow :admin, :p0, :p1, :p2, :p3
  end


  def index
  end

  def getList
    time = TimeHelper.parse_date_time(params[:time]).to_i
    zone = params[:zone].to_i
    board = params[:board]

    render :json => RsRails.getXuzhanRank(zone, time, board)
  end

  def getCreditList
    time = TimeHelper.parse_date_time(params[:time]).to_i
    zone = params[:zone].to_i
    type = params[:type]
    rankBonus = params[:rankBonus]

    render :json => RsRails.getCreditRank(zone, time, type, rankBonus)
  end

  def cantloss
  end

  def getCantlossList
    time = params[:time].to_i
    zone = params[:zone].to_i
    startTime = findResetTime(time)
    endTime = startTime + 3600*24
    ranks = RsRails.getCantlossRanks(zone, startTime, endTime)
    times = ranks.map do |r|
      t = Time.at(r.spawntime)
      t.hour
    end
    render :json => times
  end

  def getCantlossResult
    time = params[:time].to_i
    zone = params[:zone].to_i
    hour = params[:board].to_s.split(':')[0].to_i
    t = Time.at(time)
    ct = Time.new(t.year, t.month, t.day, hour).to_i
    res = RsRails.getCantlossRanks(zone, ct, ct)[0]

    res.topPlayers.map! do |v|
      b = v.readAdditionalData(zone, ct)
      v.to_hash.merge(b)
    end
    res.bossKiller.map! do |v|
      b = v.readAdditionalData(zone, ct)
      v.to_hash.merge(b)
    end

    jhash = res.to_hash
    jhash['bossName'] = res.getBossName()
    jhash['bossTime'] = res.endtime.to_i - res.spawntime.to_i
    jhash['bossKilled'] = res.bossKiller.size > 0

    # puts jhash

    render :json => jhash
  end

  def getYunbiaoResult
    rankIndex = params[:rankIndex].to_i
    rankData = RsRails.getYunbiaoRank(rankIndex).map do |data|
      data.to_hash
    end
    render :json => rankData
  end

  def findResetTime(time)
    t = Time.at(time)
    return Time.new(t.year, t.month, t.day).to_i
  end

end
