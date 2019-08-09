class EventsRaidController < ApplicationController
  layout 'main'
  protect_from_forgery

  before_filter :require_user

  access_control do
    allow :admin, :p0, :p1 #, :p2, :p3
  end



  def list
  end

  def new
  end

  def save
    res = {'success' => true}
    zones = params[:zones]
    startTime = TimeHelper.parse_date_time(params[:startTime]).to_i
    endTime = TimeHelper.parse_date_time(params[:endTime]).to_i
    if zones.length>=0
      z = zones[0]
      data =
      {
        "zone" => z,
        "startTime" => startTime,
        "endTime" => endTime,
        "multiple" => params[:multiple].to_i,
        "bSpecial" => params[:bSpecial],
        "bOpenNpc" => params[:bOpenNpc],
        "bOpenMiniBoss" => params[:bOpenMiniBoss],
        "bOpenBigBoss" => params[:bOpenBigBoss],
        "bOpenWelfare" => params[:bOpenWelfare],
      }
      evt = RaidEvent.new(data)
      bSuc, reason = evt.save
      logger.info "======#{startTime} #{endTime} raidevent:#{evt}"
      if not bSuc
        res['success'] = false
        res['reason'] = reason
      end
    end
    render :json => res
  end

  def edit
    @zone = params[:zone]
  end

  def deleteEvent
    res = {'success' => true}
    zone = params[:zone]
    RsRails.deleteRaidEvent(zone)
    render :json=>res
  end

  def deleteBatch
    res = {'success' => true}
    zones = params[:zones]
    zones.each do |zone|
      RsRails.deleteRaidEvent(zone)
    end
    render :json=>res
  end

  def getEvent
    @zone = params[:zone]
    evt = RsRails.getRaidEvent(@zone)
    res = {}
    evt.startTime = TimeHelper.gen_date_time(Time.at(evt.startTime))
    evt.endTime = TimeHelper.gen_date_time(Time.at(evt.endTime))
    res['event'] = evt.to_hash

    render :json => res
  end


  def create
    res = {'success' => true}
    zones = params[:zones]
    startTime = TimeHelper.parse_date_time(params[:startTime]).to_i
    endTime = TimeHelper.parse_date_time(params[:endTime]).to_i
    multiple = params[:multiple].to_i
    bSpecial = params[:bSpecial]
    bOpenNpc = params[:bOpenNpc]
    bOpenMiniBoss = params[:bOpenMiniBoss]
    bOpenBigBoss = params[:bOpenBigBoss]
    bOpenWelfare = params[:bOpenWelfare]
    zones.each do |z|
      data =
      {
        "zone" => z,
        "startTime" => startTime,
        "endTime" => endTime,
        "multiple" => multiple,
        "bSpecial" => bSpecial,
        "bOpenNpc" => bOpenNpc,
        "bOpenMiniBoss" => bOpenMiniBoss,
        "bOpenBigBoss" => bOpenBigBoss,
        "bOpenWelfare" => bOpenWelfare,
      }
      evt = RaidEvent.new(data)
      bSuc, reason = evt.save
      logger.info "======#{startTime} #{endTime} raidevent:#{evt}"
      if not bSuc
        res['success'] = false
        res['reason'] = reason
        break
      end
    end
    render :json => res
  end

  def accelerate
    @zone = params[:zone]
    bSuc, reason = RsRails.accelerateRaid(@zone)
    res = {'success' => true}
    if not bSuc
      res['success'] = false
      res['reason'] = reason
    end
    render :json => res
  end

  def history
  end

  def getHistories
    @zone = params[:zone]
    data = RsRails.getRaidEventHistories(@zone)
    res = {}
    res['histories'] = data.map{|x|
      x.startTime = TimeHelper.gen_date_time(Time.at(x.startTime))
      x.endTime = TimeHelper.gen_date_time(Time.at(x.endTime))
      x.to_hash
     }
    logger.info "======getHistories res:#{res}"
    render :json => res
  end

  def getCreatedZones
    events = RsRails.getRaidEventsAll
    zones = events.map{|x| x.zone}
    res = {}
    res['zones'] = zones
    render :json => res
  end

  def getEvents
    evtsData = RsRails.getRaidEventsAll
    res = {}
    evts = []
    evtsData.each do |evt|
      logger.info "======raidevent:#{evt}"
      e = {
        :zone => evt.zone,
        :startTime => TimeHelper.gen_date_time(Time.at(evt.startTime)),
        :endTime => TimeHelper.gen_date_time(Time.at(evt.endTime)),
        :multiple => evt.multiple,
        :bSpecial => evt.bSpecial,
        :bOpenNpc => evt.bOpenNpc,
        :bOpenMiniBoss => evt.bOpenMiniBoss,
        :bOpenBigBoss => evt.bOpenBigBoss,
        :bOpenWelfare => evt.bOpenWelfare,
      }
      evts << e
    end

    evts.sort_by{|x| x[:zone].to_i}
    res['events'] = evts
    render :json => res
  end
end