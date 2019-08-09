
class EditdataController < ApplicationController

  include RsRails

  layout 'main'

  protect_from_forgery

  before_filter :require_user

  http_basic_authenticate_with :name => "firevale", :password => 'fire#86*vale'

  access_control do
    allow :admin, :p0
    allow :p1, :to => [ :view, :load, :export, :give,
      :addHero, :addSouls, :addItems, :addParts,
      :addEquipment, :addFormation, :addSkill, :addCoins, :addCredits, :actionlog, :player]
    allow :p2, :p3, :to => [ :view, :load, :actionlog, :export, :player]
  end



  def index
    id = params[:id]
    zone = params[:zone].to_i
    @model = RsRails.loadGameData(id, zone)
  end

  def edit
    id = params[:id]
    zone = params[:zone].to_i
    @model = RsRails.loadGameData(id, zone)
  end

  def give
  end

  def load
    id = params[:id]
    zone = params[:zone].to_i
    model = RsRails.loadGameData(id, zone)
    render :json => model.to_hash
  end

  def save
    id = params[:id]
    zone = params[:zone].to_i
    object = ActiveSupport::JSON.decode(params[:model])

    success = RsRails.saveGameDataHashForce(id, zone, object)

    current_user.site_user_records.create(
      :action => 'save_data',
      :success => success,
      :target => id,
      :zone => zone,
    )

    render :json => { 'success' => success }
  end

  def delete
    id = params[:id]
    zone = params[:zone].to_i

    success = RsRails.deleteGameData(id, zone)

    current_user.site_user_records.create(
      :action => 'delete_data',
      :success => success,
      :target => id,
      :zone => zone,
    )

    render :json => { 'success' => success }
  end

  def export
    id = params[:id]
    zone = params[:zone].to_i
    model = RsRails.loadGameData(id, zone)
    render :json => ActiveSupport::JSON.encode(model.to_hash)
  end

  def import
  end

  def addHero
    id = params[:id]
    ids = params[:ids]
    zone = params[:zone].to_i
    tid = params[:tid]

    if id
      render :json => { 'success' =>  _addHero(id, zone, tid) }
    else
      res = {}
      ids.each { |id| res[id] = _addHero(id, zone, tid) }
      render :json => { 'success' => res }
    end
  end

  def addSouls
    id = params[:id]
    ids = params[:ids]
    zone = params[:zone].to_i
    tid = params[:tid]
    count = params[:count].to_i

    if id
      render :json => { 'success' => _addSouls(id, zone, tid, count) }
    else
      res = {}
      ids.each { |id| res[id] = _addSouls(id, zone, tid, count) }
      render :json => { 'success' => res }
    end
  end

  def addItems
    id = params[:id]
    ids = params[:ids]
    zone = params[:zone].to_i
    tid = params[:tid]
    count = params[:count].to_i

    if id
      render :json => { 'success' => _addItems(id, zone, tid, count) }
    else
      res = {}
      ids.each { |id| res[id] = _addItems(id, zone, tid, count) }
      render :json => { 'success' => res }
    end
  end

  def addParts
    id = params[:id]
    ids = params[:ids]
    zone = params[:zone].to_i
    tid = params[:tid]
    count = params[:count].to_i

    if id
      render :json => { 'success' => _addParts(id, zone, tid, count) }
    else
      res = {}
      ids.each { |id| res[id] = _addParts(id, zone, tid, count) }
      render :json => { 'success' => res }
    end
  end

  def addEquipment
    id = params[:id]
    ids = params[:ids]
    zone = params[:zone].to_i
    tid = params[:tid]

    if id
      render :json => { 'success' => _addEquipment(id, zone, tid) }
    else
      res = {}
      ids.each { |id| res[id] = _addEquipment(id, zone, tid) }
      render :json => { 'success' => res }
    end
  end

  def addFormation
    id = params[:id]
    ids = params[:ids]
    zone = params[:zone].to_i
    tid = params[:tid]

    if id
      render :json => { 'success' => _addFormation(id, zone, tid) }
    else
      res = {}
      ids.each { |id| res[id] = _addFormation(id, zone, tid) }
      render :json => { 'success' => res }
    end
  end

  def addSkill
    id = params[:id]
    ids = params[:ids]
    zone = params[:zone].to_i
    tid = params[:tid]

    if id
      render :json => { 'success' => _addSkill(id, zone, tid) }
    else
      res = {}
      ids.each { |id| res[id] = _addSkill(id, zone, tid) }
      render :json => { 'success' => res }
    end
  end

  def addCoins
    id = params[:id]
    ids = params[:ids]
    zone = params[:zone].to_i
    count = params[:count].to_i

    if id
      render :json => { 'success' => _addCoins(id, zone, tid) }
    else
      res = {}
      ids.each { |id| res[id] = _addCoins(id, zone, count) }
      render :json => { 'success' => res }
    end
  end

  def addCredits
    id = params[:id]
    ids = params[:ids]
    zone = params[:zone].to_i
    count = params[:count].to_i

    if id
      render :json => { 'success' => _addCredits(id, zone, count) }
    else
      res = {}
      ids.each { |id| res[id] = _addCredits(id, zone, count) }
      render :json => { 'success' => res }
    end
  end

  def addPaymentCredits
    id = params[:id]
    ids = params[:ids]
    zone = params[:zone].to_i
    count = params[:count].to_i

    if id
      render :json => { 'success' => _addPaymentCredits(id, zone, count) }
    else
      res = {}
      ids.each { |id| res[id] = _addPaymentCredits(id, zone, count) }
      render :json => { 'success' => res }
    end
  end

  def skipFtue
    id = params[:id]
    ids = params[:ids]
    zone = params[:zone].to_i

    if id
      render :json => { 'success' => _skipFtue(id, zone) }
    else
      res = {}
      ids.each { |id| res[id] = _skipFtue(id, zone) }
      render :json => { 'success' => res }
    end
  end

  def actionlog
    id = params[:id]
    zone = params[:zone]
    startTime = params[:startTime]
    endTime = params[:endTime]
    render :json => { 'res' => ActionLog.search(id,zone,startTime,endTime) }# RsRails.getActionLog(id, zone,startTime,endTime) }
  end

  def getUserPermission
    id = params[:id]
    res = RsRails.getUserPermission(id)
    # if res.nil?
    #   res = {}
    # end
    # RsRails.getUserPermission(id).nil?
    render :json => {"res" => res }
  end
  def updateUserPermission
    id = params[:id]
    type = params[:type]
    zones = params[:zones].split(' ')

    render :json => { 'success' => RsRails.updateUserPermission(id, type, zones) }
  end
private

  def _addHero(id, zone, tid)
    success = false
    RsRails.lockGameData(id, zone) do |id, zone|
      model = RsRails.loadGameData(id, zone)
      if model
        model.addHeroByTid(tid)
        success = RsRails.saveGameData(id, zone, model)
        RsRails.sendNotifyGiveMail(id, zone, tid, -1)
      end
    end
    current_user.site_user_records.create(
      :action => 'add_hero',
      :success => success,
      :target => id,
      :zone => zone,
      :tid => tid,
      :count => 1,
    )
    success
  end

  def _addSouls(id, zone, tid, count)
    success = false
    RsRails.lockGameData(id, zone) do |id, zone|
      model = RsRails.loadGameData(id, zone)
      if model
        model.addSouls(tid, count)
        success = RsRails.saveGameData(id, zone, model)
        RsRails.sendNotifyGiveMail(id, zone, tid, count)
      end
    end
    current_user.site_user_records.create(
      :action => 'add_souls',
      :success => success,
      :target => id,
      :zone => zone,
      :tid => tid,
      :count => count,
    )
    success
  end

  def _addItems(id, zone, tid, count)
    success = false
    RsRails.lockGameData(id, zone) do |id, zone|
      model = RsRails.loadGameData(id, zone)
      if model
        model.addItems(tid, count)
        success = RsRails.saveGameData(id, zone, model)
        RsRails.sendNotifyGiveMail(id, zone, tid, count)
      end
    end
    current_user.site_user_records.create(
      :action => 'add_items',
      :success => success,
      :target => id,
      :zone => zone,
      :tid => tid,
      :count => count,
    )
    success
  end

  def _addParts(id, zone, tid, count)
    success = false
    RsRails.lockGameData(id, zone) do |id, zone|
      model = RsRails.loadGameData(id, zone)
      if model
        model.addParts(tid, count)
        model.addComposesByPart(tid, count)
        success = RsRails.saveGameData(id, zone, model)
        RsRails.sendNotifyGiveMail(id, zone, tid, count)
      end
    end
    current_user.site_user_records.create(
      :action => 'add_parts',
      :success => success,
      :target => id,
      :zone => zone,
      :tid => tid,
      :count => count,
    )
    success
  end

  def _addEquipment(id, zone, tid)
    success = false
    RsRails.lockGameData(id, zone) do |id, zone|
      model = RsRails.loadGameData(id, zone)
      if model
        model.addEquipment(tid)
        # model.record.recordEquip(model, tid)
        success = RsRails.saveGameData(id, zone, model)
        RsRails.sendNotifyGiveMail(id, zone, tid, 1)
      end
    end
    current_user.site_user_records.create(
      :action => 'add_equipment',
      :success => success,
      :target => id,
      :zone => zone,
      :tid => tid,
      :count => 1,
    )
    success
  end

  def _addFormation(id, zone, tid)
    success = false
    RsRails.lockGameData(id, zone) do |id, zone|
      model = RsRails.loadGameData(id, zone)
      if model
        model.addFormation(tid)
        success = RsRails.saveGameData(id, zone, model)
        RsRails.sendNotifyGiveMail(id, zone, tid, 1)
      end
    end
    current_user.site_user_records.create(
      :action => 'add_formation',
      :success => success,
      :target => id,
      :zone => zone,
      :tid => tid,
      :count => 1,
    )
    success
  end

  def _addSkill(id, zone, tid)
    success = false
    RsRails.lockGameData(id, zone) do |id, zone|
      model = RsRails.loadGameData(id, zone)
      if model
        model.addSkill(tid)
        success = RsRails.saveGameData(id, zone, model)
        RsRails.sendNotifyGiveMail(id, zone, tid, 1)
      end
    end
    current_user.site_user_records.create(
      :action => 'add_skill',
      :success => success,
      :target => id,
      :zone => zone,
      :tid => tid,
      :count => 1,
    )
    success
  end

  def _addCoins(id, zone, count)
    success = false
    RsRails.lockGameData(id, zone) do |id, zone|
      model = RsRails.loadGameData(id, zone)
      if model
        model.chief.coins += count
        success = RsRails.saveGameData(id, zone, model)
        RsRails.sendNotifyGiveMail(id, zone, "coins", count)
      end
    end
    current_user.site_user_records.create(
      :action => 'add_coins',
      :success => success,
      :target => id,
      :zone => zone,
      :count => count,
    )
    success
  end

  def _addCredits(id, zone, count)
    success = false
    RsRails.lockGameData(id, zone) do |id, zone|
      model = RsRails.loadGameData(id, zone)
      if model
        model.gmChongzhi(count, 'gm.tuo')
        success = RsRails.saveGameData(id, zone, model)
        RsRails.sendNotifyGiveMail(id, zone, "credits", count)
      end
    end
    current_user.site_user_records.create(
      :action => 'add_gm_credits',
      :success => success,
      :target => id,
      :zone => zone,
      :count => count,
    )
    success
  end

  def _addPaymentCredits(id, zone, count)
    success = false
    RsRails.lockGameData(id, zone) do |id, zone|
      model = RsRails.loadGameData(id, zone)
      if model
        model.gmChongzhi(count, 'gm.payment')
        success = RsRails.saveGameData(id, zone, model)
        RsRails.sendNotifyGiveMail(id, zone, "credits", count)
      end
    end

    current_user.site_user_records.create(
      :action => 'add_payment_credits',
      :success => success,
      :target => id,
      :zone => zone,
      :count => count,
    )
    success
  end

  def _skipFtue(id, zone)
    success = false
    RsRails.lockGameData(id, zone) do |id, zone|
      model = RsRails.loadGameData(id, zone)
      if model
        model.record.ftueDone = true
        success = RsRails.saveGameData(id, zone, model)
      end
    end
    current_user.site_user_records.create(
      :action => 'skipFtue',
      :success => success,
      :target => id,
      :zone => zone,
      :count => 1,
    )
    success
  end

end
