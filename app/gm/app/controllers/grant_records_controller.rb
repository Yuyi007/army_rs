require_relative 'batch_add_module'

class GrantRecordsController < ApplicationController
  include RsRails
  include ApplicationHelper

  layout 'main'
  protect_from_forgery
  before_filter :require_user

  access_control do
    allow :admin, :p0, :p1, :p2
  end



  def index
    @res = params[:res]
    sort = 'created_at'
    direction = 'desc'

    @grant_records = GrantRecord.where("status = ?", 'new').order("#{sort} #{direction}")
      .paginate(:page => params[:page], :per_page => 10)
  end

  def old_requests
    sort = 'created_at'
    direction = 'desc'

    @old_grant_records = GrantRecord.where("status != ?", 'new').order("#{sort} #{direction}")
      .paginate(:page => params[:page], :per_page => 30)
  end

  def show
    @grant_record = GrantRecord.find(params[:id])
  end

  def new
    @grant_record = GrantRecord.new
  end

  def edit
    @grant_record = GrantRecord.find(params[:id])
  end

  def create
    @grant_record = GrantRecord.new(params[:grant_record])
    @grant_record.save
  end

  def update
    @grant_record = GrantRecord.find(params[:id])

    if @grant_record.update_attributes(params[:grant_record])
      flash[:notice] = "GrantRecord updated!"
      redirect_to edit_grant_record_url(@user)
    else
      flash[:error] = "GrantRecord updated failed!"
      render :edit
    end
  end

  def destroy
    @grant_record = GrantRecord.find(params[:id])
    @grant_record.destroy

    redirect_to grant_records_url
  end

  def reject
    @grant_record = GrantRecord.find(params[:id])
    @grant_record.update_attribute('status', 'rejected')

    respond_to do |format|
      if @grant_record.update_attribute('status', 'rejected')
        format.html { redirect_to :action => 'index' }
        format.js   {}
        format.json {}
      else
        format.html { redirect_to :action => 'index' }
        format.json { }
      end
    end
  end

  def grant
    @grant_record = GrantRecord.find(params[:id])
    return if @grant_record.status != 'new'
    updated = @grant_record.update_attribute('status', 'accepted')
    # @res = send(@grant_record.action, @grant_record.id)
    do_grant(@grant_record)

    respond_to do |format|
      if updated
        format.html { redirect_to :action => 'index' }
        format.js   {}
        format.json {}
      else
        format.html { redirect_to :action => 'index' }
        format.json { }
      end
    end
  end

private
  include ModuleBatchAdd

  def addCredits(*args)
    @grant_record = GrantRecord.find(args[0])
    ids = @grant_record.target_id.split(',')
    res = {}
    first_record = nil
    ids.each do |id|
      id.to_i
      zone = @grant_record.target_zone.to_i
      count = @grant_record.item_amount.to_i

      success = false
      success, code = canAddCredits?(id, zone, count)

      if success
        success = false
        RsRails.lockGameData(id, zone) do |id, zone|
          model = RsRails.loadGameData(id, zone)
          if model
            model.gmChongzhi(count, 'gm.tuo')
            success = RsRails.saveGameData(id, zone, model)
            RsRails.sendNotifyGiveMail(id, zone, "credits", count)
          end
        end
        first_record ||= current_user.site_user_records.create(
          :action => 'add_gm_credits',
          :success => success,
          :target => id,
          :zone => zone,
          :count => count,
        )
        scode = success ? 'add_credit_successed' : 'add_credit_failed'
        res[id] = {:success => success, :code => '', :request_id => args[0]}
      else
        res[id] = {:success => success, :code => code, :request_id => args[0]}
      end
    end

    SiteUserMailer.give_item_warning(current_user, first_record).deliver if first_record and first_record.count > 5000
    res
  end

  def addPaymentCredits(*args)
    @grant_record = GrantRecord.find(args[0])
    ids = @grant_record.target_id.split(',')
    res = {}
    first_record = nil
    ids.each do |id|
      id.to_i
      zone = @grant_record.target_zone.to_i
      count = @grant_record.item_amount.to_i

      success = false

      RsRails.lockGameData(id, zone) do |id, zone|
        model = RsRails.loadGameData(id, zone)
        if model
          model.gmChongzhi(count, 'gm.payment')
          success = RsRails.saveGameData(id, zone, model)
          RsRails.sendNotifyGiveMail(id, zone, "credits", count)
        end
      end

      first_record ||= current_user.site_user_records.create(
        :action => 'add_payment_credits',
        :success => success,
        :target => id,
        :zone => zone,
        :count => count,
      )
      res[id] = {:success => success, :code => '', :request_id => args[0]}
    end

    SiteUserMailer.give_item_warning(current_user, first_record).deliver if first_record and first_record.count > 5000
    res
  end

  def addCreditsOnly(*args)
    @grant_record = GrantRecord.find(args[0])
    ids = @grant_record.target_id.split(',')
    res = {}
    first_record = nil
    ids.each do |id|
      id.to_i
      zone = @grant_record.target_zone.to_i
      count = @grant_record.item_amount.to_i

      success = false
      success, code = canAddCreditsOnly?(id, zone, count)

      if success
        success = false
        RsRails.lockGameData(id, zone) do |id, zone|
          model = RsRails.loadGameData(id, zone)
          if model
            model.chief.alterCredit('gm', count)
            success = RsRails.saveGameData(id, zone, model)
            RsRails.sendNotifyGiveMail(id, zone, "credits", count)
          end
        end

        first_record ||= current_user.site_user_records.create(
          :action => 'add_credits_only',
          :success => success,
          :target => id,
          :zone => zone,
          :count => count,
        )
        res[id] = {:success => success, :code => '', :request_id => args[0]}
      else
        res[id] = {:success => success, :code => code, :request_id => args[0]}
      end
    end

    SiteUserMailer.give_item_warning(current_user, first_record).deliver if first_record and first_record.count > 5000
    res
  end

  def addHero(*args)
    @grant_record = GrantRecord.find(args[0])
    ids = @grant_record.target_id.split(',')
    res = {}
    first_record = nil
    ids.each do |id|
      id.to_i
      zone = @grant_record.target_zone.to_i
      tid = @grant_record.item_id
      count = @grant_record.item_amount.to_i

      success = false

      RsRails.lockGameData(id, zone) do |id, zone|
        model = RsRails.loadGameData(id, zone)
        if model
          model.addHeroByTid(tid)
          success = RsRails.saveGameData(id, zone, model)
          RsRails.sendNotifyGiveMail(id, zone, tid, -1)
        end
      end
      first_record ||= current_user.site_user_records.create(
        :action => 'add_hero',
        :success => success,
        :target => id,
        :zone => zone,
        :tid => tid,
        :count => 1,
      )
      res[id] = {:success => success, :code => '', :request_id => args[0]}
    end

    SiteUserMailer.give_item_warning(current_user, first_record).deliver if first_record and first_record.tid =~ /^HA/
    res
  end

  def addSouls(*args)
    @grant_record = GrantRecord.find(args[0])
    ids = @grant_record.target_id.split(',')
    res = {}
    ids.each do |id|
      id.to_i
      zone = @grant_record.target_zone.to_i
      tid = @grant_record.item_id
      count = @grant_record.item_amount.to_i

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
      res[id] = {:success => success, :code => '', :request_id => args[0]}
    end
    res
  end

  def addEquipment(*args)
    @grant_record = GrantRecord.find(args[0])
    ids = @grant_record.target_id.split(',')
    res = {}
    first_record = nil
    ids.each do |id|
      id.to_i
      zone = @grant_record.target_zone.to_i
      tid = @grant_record.item_id
      count = @grant_record.item_amount.to_i

      success = false

      RsRails.lockGameData(id, zone) do |id, zone|
        model = RsRails.loadGameData(id, zone)
        if model
          model.addEquipment(tid)
          success = RsRails.saveGameData(id, zone, model)
          RsRails.sendNotifyGiveMail(id, zone, tid, 1)
        end
      end
      first_record ||= current_user.site_user_records.create(
        :action => 'add_equipment',
        :success => success,
        :target => id,
        :zone => zone,
        :tid => tid,
        :count => 1,
      )
      res[id] = {:success => success, :code => '', :request_id => args[0]}
    end

    SiteUserMailer.give_item_warning(current_user, first_record).deliver if first_record and first_record.tid =~ /^EA/
    res
  end

  def addParts(*args)
    @grant_record = GrantRecord.find(args[0])
    ids = @grant_record.target_id.split(',')
    res = {}
    ids.each do |id|
      id.to_i
      zone = @grant_record.target_zone.to_i
      tid = @grant_record.item_id
      count = @grant_record.item_amount.to_i

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
      res[id] = {:success => success, :code => '', :request_id => args[0]}
    end
    res
  end

  def addFormation(*args)
    @grant_record = GrantRecord.find(args[0])
    ids = @grant_record.target_id.split(',')
    res = {}
    ids.each do |id|
      id.to_i
      zone = @grant_record.target_zone.to_i
      tid = @grant_record.item_id
      count = @grant_record.item_amount.to_i

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
      res[id] = {:success => success, :code => '', :request_id => args[0]}
    end
    res
  end

  def addSkill(*args)
    @grant_record = GrantRecord.find(args[0])
    ids = @grant_record.target_id.split(',')
    res = {}
    ids.each do |id|
      id.to_i
      zone = @grant_record.target_zone.to_i
      tid = @grant_record.item_id
      count = @grant_record.item_amount.to_i

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
      res[id] = {:success => success, :code => '', :request_id => args[0]}
    end
    res
  end

  def addItems(*args)
    @grant_record = GrantRecord.find(args[0])
    ids = @grant_record.target_id.split(',')
    res = {}
    ids.each do |id|
      id.to_i
      zone = @grant_record.target_zone.to_i
      tid = @grant_record.item_id
      count = @grant_record.item_amount.to_i

      success = false

      RsRails.lockGameData(id, zone) do |id, zone|
        model = RsRails.loadGameData(id, zone)
        if model
          if count > 0
            BonusHelper.giveBonus(model, tid, count)
            success = RsRails.saveGameData(id, zone, model)
            RsRails.sendNotifyGiveMail(id, zone, tid, count)
          elsif count < 0
            BonusHelper.deductItem(model, tid, count)
            success = RsRails.saveGameData(id, zone, model)
          end
        end
      end

      current_user.site_user_records.create(
        :action => count > 0 ? 'add_items' : 'deduct_item',
        :success => success,
        :target => id,
        :zone => zone,
        :tid => tid,
        :count => count,
      )
      res[id] = {:success => success, :code => '', :request_id => args[0]}
    end
    res
  end

  def addKoujue(*args)
    @grant_record = GrantRecord.find(args[0])
    ids = @grant_record.target_id.split(',')
    res = {}
    ids.each do |id|
      id.to_i
      zone = @grant_record.target_zone.to_i
      tid = @grant_record.item_id
      count = @grant_record.item_amount.to_i

      success = false

      RsRails.lockGameData(id, zone) do |id, zone|
        model = RsRails.loadGameData(id, zone)
        if model
          model.addKoujue(tid)
          success = RsRails.saveGameData(id, zone, model)
          RsRails.sendNotifyGiveMail(id, zone, tid, 1)
        end
      end
      current_user.site_user_records.create(
        :action => 'add_koujue',
        :success => success,
        :target => id,
        :zone => zone,
        :tid => tid,
        :count => 1,
      )
      res[id] = {:success => success, :code => '', :request_id => args[0]}
    end
    res
  end

  def modifyZhuwei(*args)
    @grant_record = GrantRecord.find(args[0])
    logger.info("*********************item_id=#{@grant_record.item_id}")
    index, hid, aid = @grant_record.item_id.split(',')
    logger.info("*********************index=#{index} hid=#{hid} aid=#{aid}")
    ids = @grant_record.target_id.split(',')
    res = {}
    ids.each do |id|
      id.to_i
      zone = @grant_record.target_zone.to_i

      success = false

      RsRails.lockGameData(id, zone) do |id, zone|
        model = RsRails.loadGameData(id, zone)
        if model and model.zhuwei and model.zhuwei.slots and not model.zhuwei.slots[index.to_i].nil?
          model.zhuwei.slots[index.to_i].goodHero = RsRails.getGameConfig('zhuwei')['heroes'].find {|hero| hero.tid == hid }
          if index.to_i < 3 then
            attrList = RsRails.getGameConfig('zhuwei')['attributes']
          else
            idx = index.to_i + 1
            attrList = RsRails.getGameConfig('zhuwei')['sky_attributes'][idx.to_s]
          end
          model.zhuwei.slots[index.to_i].attribute = attrList.find {|att| att.tid == aid}

          success = RsRails.saveGameData(id, zone, model)
        end
      end
      current_user.site_user_records.create(
        :action => 'modify_zhuwei',
        :success => success,
        :target => id,
        :zone => zone,
        :param1 => index,
        :param2 => hid,
        :param3 => aid,
      )
      res[id] = {:success => success, :code => '', :request_id => args[0]}
    end
    res
  end

  def modifyXiulian(*args)
    @grant_record = GrantRecord.find(args[0])
    logger.info("*********************item_id=#{@grant_record.item_id}")
    hid, att = @grant_record.item_id.split(',')
    count = @grant_record.item_amount
    logger.info("*********************hid=#{hid} att=#{att} count=#{count}")
    ids = @grant_record.target_id.split(',')
    res = {}
    ids.each do |id|
      id.to_i
      zone = @grant_record.target_zone.to_i

      success = false

      RsRails.lockGameData(id, zone) do |id, zone|
        model = RsRails.loadGameData(id, zone)
        if model and model.heroes and model.heroes[hid] and model.heroes[hid].xiulian_status
          model.heroes[hid].xiulian_status.addValue(att, count)
          success = RsRails.saveGameData(id, zone, model)
        end
      end
      current_user.site_user_records.create(
        :action => 'modify_xiulian',
        :success => success,
        :target => id,
        :zone => zone,
        :param1 => hid,
        :param2 => att,
        :param3 => count,
      )
      res[id] = {:success => success, :code => '', :request_id => args[0]}
    end
    res
  end

  def canAddCredits?(id, zone, count)
    if Bill.where("playerId = ? AND zone = ?", id, zone).sum("price") > 648
      return false, 'add_credit_fail1'
    end

    #RsRails.lockGameData(id, zone) do |id, zone|
    #  model = RsRails.loadGameData(id, zone)
    #  if model and model.chief and model.chief.totalRmb
    #    finalCount = model.chief.totalRmb + count
    #    case model.chief.level
    #    when 1..10
    #      return false, 'add_credit_fail2' if finalCount > 6480
    #    when 11..20
    #      return false, 'add_credit_fail3' if finalCount > 19400
    #    when 20..32
    #      return false, 'add_credit_fail4' if finalCount > 32400
    #    end
    #  end
    #end

    return true
  end

  def canAddCreditsOnly?(id, zone, count)
    return true
    RsRails.lockGameData(id, zone) do |id, zone|
      model = RsRails.loadGameData(id, zone)
      if model and model.chief and model.chief.credits
        return true if model.chief.vip_level > 14

        finalCount = model.chief.credits + count
        vip = (model.chief.vip_level + 1).to_s

        limit = RsRails.getGameConfig('vipsystem')[vip]['money']
        logger.info("************* vip_level = #{model.chief.vip_level} finalCount = #{finalCount} limit = #{limit}")
        if finalCount >= limit
          return false, 'add_credit_only_fail'
        end
      else
        return false, 'player_not_found'
      end
    end

    return true
  end

end
