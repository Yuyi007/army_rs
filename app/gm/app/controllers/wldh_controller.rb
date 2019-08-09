class WldhController < ApplicationController

  layout 'main'

  protect_from_forgery

  before_filter :require_user

  access_control do
    allow :admin, :p0, :p1
  end



  def list
    @auth = curAuth()
    @wulins = RsRails.getAllWulins
    curPage = params[:curPage]
    @page = PageGen.genPage({"dataSource" => @wulins, "sort" => 'startTime', "direction" => 'DESC', "dataType" => 'model', "perPage" => 20, "curPage" => curPage.to_i, "pageUrl" => wldh_list_url})
    @wulins
  end

  def new
    @wulin = RsRails.newWulin
  end

  def create
    userInfo = curUserInfo()
    params[:wulin_model].zones = trimZones(params[:wulin_model].zones)
    res, repeatedZones = alreadyContained?(params[:wulin_model].zones)
    if(!res)
      @wulin = WulinModel.from_param(params[:wulin_model])
      if @wulin.is_started? and (not GameEventsHelper.authEqualAdmin(userInfo['auth']))
        flash[:error] = t(:error_no_auth)
        redirect_to :action => :new
      else
        GameEventsHelper.setGrantStatusToEvent(userInfo, @wulin, :needGrant)
        RsRails.createWulin(@wulin)

        current_user.site_user_records.create(
          :action => 'create_wulin',
          :param1 => @wulin.id,
          :success => true,
        )

        flash[:notice] = t(:create_success, :name => "#{t(:wulin)} #{@wulin.id}")
        redirect_to :action => :list
      end
    else
      current_user.site_user_records.create(
        :action => 'create_wulin',
        :success => false,
      )

      flash[:error] = t(:create_failed, :name => "#{t(:wulin)}", :repeatedZones => "#{repeatedZones.collect {|z| z + 1}}")
      redirect_to :action => :new
    end
  end

  def show
    @wulin = RsRails.readWulin(params[:id])
  end

  def show_stages
    @wulin = RsRails.readWulin(params[:id])
    @stage = params[:stage].to_sym # FIXME filter invalid stage names
  end

  def show_stages_player
    @id = params[:id]
    @stage = params[:stage].to_sym # FIXME filter invalid stage names
    @player_id = params[:player_id]
    @zone = params[:zone]
  end

  def show_stages_fight
    @id = params[:id]
    @mode = params[:mode]
    @stage = params[:stage].to_sym # FIXME filter invalid stage names
    @fight_id = params[:fight_id]
    @fight = WulinDb.getFight(@id, @mode, @stage, @fight_id)
  end

  def edit
    @wulin = RsRails.readWulin(params[:id])
  end

  def update
    userInfo = curUserInfo()
    res, repeatedZones = alreadyContainedByOthers?(params[:id], params[:wulin_model].zones)
    if not res
      @wulin = RsRails.readWulin(params[:id])
      newWulin = WulinModel.from_param(params[:wulin_model])
      if (@wulin.is_started? or newWulin.is_started?) and (not GameEventsHelper.authEqualAdmin(userInfo['auth']))
        flash[:error] = t(:error_no_auth)
        redirect_to :action => :edit, :id => params[:id]
      else
        @wulin.maxPlayers = params[:wulin_model].maxPlayers.to_i
        @wulin.minPlayers = params[:wulin_model].minPlayers.to_i
        @wulin.baseTid = params[:wulin_model].baseTid
        @wulin.rewardTid = params[:wulin_model].rewardTid
        @wulin.zones = trimZones(params[:wulin_model].zones)
        @wulin.startTime = TimeHelper.parse_date_time(params[:wulin_model].start_time).to_i
        @wulin.counter = params[:wulin_model].counter.to_i
        @wulin.division = params[:wulin_model].division.to_i
        GameEventsHelper.setGrantStatusToEvent(userInfo, @wulin, :needGrant)
        RsRails.updateWulin(@wulin)

        current_user.site_user_records.create(
          :action => 'update_wulin',
          :param1 => params[:id],
          :success => true,
        )

        flash[:notice] = t(:update_success, :name => "#{t(:wulin)} #{@wulin.id}")
        redirect_to :action => :list
      end
    else
      current_user.site_user_records.create(
        :action => 'update_wulin',
        :param1 => params[:id],
        :success => false,
      )

      flash[:error] = t(:update_failed, :name => "#{t(:wulin)}", :repeatedZones => "#{repeatedZones.collect {|z| z + 1}}")
      redirect_to :action => :edit, :id => params[:id]
    end
  end

  def destroy
    userInfo = curUserInfo()
    oldWulin = RsRails.readWulin(params[:id])
    if oldWulin and oldWulin.is_started? and (not GameEventsHelper.authEqualAdmin(userInfo['auth']))
      flash[:error] = t(:error_no_auth)
      redirect_to wldh_list_url
    else
      id = params[:id]
      RsRails.deleteWulin(id)

      current_user.site_user_records.create(
        :action => 'delete_wulin',
        :param1 => id,
        :success => true,
      )

      flash[:notice] = t(:delete_success, :name => "#{t(:wulin)} #{id}")
      redirect_to wldh_list_url
    end
  end

  def trimZones(zones)
    # remove the blank zone from client
    res = []
    zones.each {|z| res << z.to_i if z != ''}
    res
  end
  def alreadyContained?(zones)
    # check if the zone has been added
    repeatedZones = []
    zones.each do |z|
      list().each {|w| if w.is_active? and w.containsZone?(z) then repeatedZones << z end}
    end

    if repeatedZones.length != 0
      return true, repeatedZones
    else
      return false, nil
    end
  end

  def alreadyContainedByOthers?(id, zones)
    # check if the zone has been added
    repeatedZones = []
    zones.each do |z|
      list().each do |w|
        if w.is_active? and w.id.to_i != id.to_i
          repeatedZones << z if(w.containsZone?(z))
        end
      end
    end

    if repeatedZones.length != 0
      return true, repeatedZones
    else
      return false, nil
    end
  end

  # def activate
  #   id = params[:id]
  #   RsRails.activateWulin(id)

  #   current_user.site_user_records.create(
  #     :action => 'activate_wulin',
  #     :param1 => id,
  #     :success => true,
  #   )

  #   flash[:notice] = t(:activate_success, :name => "#{t(:wulin)} #{id}")
  #   redirect_to wldh_list_url
  # end

  def boost
    userInfo = curUserInfo()
    if (not GameEventsHelper.authEqualAdmin(userInfo['auth']))
      flash[:error] = t(:error_no_auth)
    else
      id = params[:id]
      wulin = RsRails.boostWulin(id)

      logger.info("boost wulin #{id} cur=#{wulin.startTime}")

      current_user.site_user_records.create(
        :action => 'boost_wulin',
        :param1 => id,
        :param2 => wulin.stage_name,
        :success => true,
      )

      flash[:notice] = t(:boost_success, :name => "#{t(:wulin)} #{id}")
    end
    redirect_to wldh_list_url
  end

  def self.is_enrolling?(id)
    system("ps x | grep '[t]estWulin.rb -w #{id}'")
  end

  def enroll
    userInfo = curUserInfo()
    if (not GameEventsHelper.authEqualAdmin(userInfo['auth']))
      flash[:error] = t(:error_no_auth)
    else
      id = params[:id]
      num = params[:num].to_i

      logger.info("enroll wulin #{id} #{num}")

      if WldhController.is_enrolling?(id)
        flash[:error] = t(:enroll_error, :name => "#{t(:wulin)} #{id}")
        success = false
      else
        Thread.new do
          base = Gm::Application.config.rs_base
          env = Gm::Application.config.rs_environment
          logger.info "ruby #{base}/lib/load/testWulin.rb -w #{id} -v #{env} -P -m random -t #{num} -e enroll"
          system("ruby #{base}/lib/load/testWulin.rb -w #{id} -v #{env} -P -m random -t #{num} -e enroll")
        end

        flash[:notice] = t(:enroll_success, :name => "#{t(:wulin)} #{id}")
        success = true
      end

      current_user.site_user_records.create(
        :action => 'enroll_wulin',
        :param1 => id,
        :param2 => num,
        :success => success,
      )
    end

    redirect_to wldh_list_url
  end

  def reset_stages
    userInfo = curUserInfo()
    if (not GameEventsHelper.authEqualAdmin(userInfo['auth']))
      flash[:error] = t(:error_no_auth)
    else
      id = params[:id]
      wulin = RsRails.resetWulinStages(id)

      logger.info("reset wulin stages #{id}")

      current_user.site_user_records.create(
        :action => 'reset_wulin_stages',
        :param1 => id,
        :success => true,
      )

      flash[:notice] = t(:reset_stages_success, :name => "#{t(:wulin)} #{id}")
    end
    redirect_to wldh_list_url
  end

  def grant
    userInfo = curUserInfo()
    grantType = :granted
    if params[:grant].to_i == 1
      grantType = :granted
    elsif params[:grant].to_i == 2
      grantType = :rejected
    else
      flash[:error] = t(:operation_failed)
      redirect_to wldh_list_url
      return
    end

    if (not GameEventsHelper.authEqualAdmin(userInfo['auth']))
      flash[:error] = t(:error_no_auth)
    else
      wulin = RsRails.readWulin(params[:id])
      if wulin.nil?
        flash[:error] = t(:operation_failed)
      else
        GameEventsHelper.setGrantStatusToEvent(userInfo, wulin, grantType)
        RsRails.updateWulin(wulin)

        current_user.site_user_records.create(
          :action => 'grant_wulin',
          :param1 => params[:id],
          :param2 => grantType,
          :success => true,
        )

        flash[:notice] = t(:operation_success)
      end
    end
    redirect_to wldh_list_url
  end

  def viewWulinRanks
    @wulins = RsRails.getAllWulins.select {|w| w.is_history? }
    @wulins.sort! {|x, y| y.id <=> x.id }
    @wulins
  end

end

class WulinModel

  include ActiveModel::Validations
  include ActiveModel::Conversion
  extend ActiveModel::Naming

  def self.from_param(p)
    wulin = WulinModel.new(TimeHelper.parse_date_time(p[:start_time]))
    wulin.id = p[:id]
    wulin.maxPlayers = p[:maxPlayers].to_i
    wulin.minPlayers = p[:minPlayers].to_i
    wulin.zones = p[:zones]
    wulin.baseTid = p[:baseTid]
    wulin.rewardTid = p[:rewardTid]
    wulin.counter = p[:counter].to_i
    wulin.division = p[:division].to_i
    wulin
  end

  def persisted?
    false
  end

  def start_time
    if startTime > 0
      TimeHelper.gen_date_time(Time.at(startTime))
    else
      ''
    end
  end

  def start_time=(time)
    startTime = TimeHelper.parse_date_time(time).to_i
  end

  def stage_name
    I18n.t(stageSymbol)
  end

  def is_active?
    WulinDb.isActive?(id, true)
  end

  def is_history?
    WulinDb.isHistory?(id)
  end

  def num_enroll(mode)
    WulinDb.numEnroll(id, mode)
  end

  def is_enrolling?
    WldhController.is_enrolling?(id)
  end

  def is_started?
    startTime.to_i <= Time.now.to_i
  end

end