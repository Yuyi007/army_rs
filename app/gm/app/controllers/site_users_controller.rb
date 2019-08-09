
class SiteUsersController < ApplicationController

  include Statsable
  include RsRails

  layout 'main'

  protect_from_forgery

  before_filter :require_no_user, :only => [ :new, :create ]
  before_filter :require_user, :only => [ :show, :edit, :update, :list,
    :edit_super, :update_super, :edit_role, :update_role,
    :edit_active, :update_active, :reset_failed_login_count,
    :deliver_verification_instructions ]

  access_control do
    allow :admin
    allow all, :to => [ :new, :create ]
    allow :p0, :p1, :p2, :p3, :p4, :to => [ :show, :edit, :update ]
  end

  def new
    @user = SiteUser.new
  end

  def create
    @user = SiteUser.new(params[:site_user])

    # Saving without session maintenance to skip
    # auto-login which can't happen here because
    # the User has not yet been activated
    if @user.save
      flash[:notice] = "Thanks for signing up, we've delivered an email to you with instructions on how to complete your registration!"
      @user.site_user_records.create(
        :action => 'create_user',
        :success => true,
      )
      @user.deliver_verification_instructions!
      stats_increment_global 'gm.user.create.success'
      redirect_to root_url
    else
      flash[:notice] = "There was a problem creating you."
      stats_increment_global 'gm.user.create.failure'
      render :action => :new
    end

  end

  def show
    if current_user.role_name == 'admin'
      @user = SiteUser.find(params[:id])
      render :show_super
    else
      @user = current_user
    end
  end

  def edit
    @user = current_user
  end

  def update
    @user = current_user # makes our views "cleaner" and more consistent
    params[:site_user].delete(:email)
    res = @user.update_attributes(params[:site_user])

    @user.site_user_records.create(
      :action => 'update_user',
      :success => res,
    )

    if res
      flash[:notice] = "Account updated!"
      stats_increment_global 'gm.user.update.success'
      render :edit
    else
      flash[:error] = "Something wrong!"
      stats_increment_global 'gm.user.failure.success'
      render :action => :edit
    end
  end

  # super

  def list
    @users = SiteUser.find(:all)
  end

  def edit_super
    @user = SiteUser.find(params[:id])
  end

  def update_super
    @user = SiteUser.find(params[:id])

    if @user.can_edit_by? current_user
      params[:site_user].delete(:email)
      success = @user.update_attributes(params[:site_user])
    else
      success = false
    end

    record = current_user.site_user_records.create(
      :action => 'update_user_super',
      :success => success,
      :param1 => params[:id],
    )

    SiteUserMailer.edit_user_warning(current_user, @user, record).deliver

    if success
      flash[:notice] = "Account updated!"
      stats_increment_global 'gm.user.update_super.success'
      render :edit_super
    else
      flash[:error] = "Something wrong!"
      stats_increment_global 'gm.user.update_super.failure'
      render :edit_super
    end
  end

  def edit_role
    @user = SiteUser.find(params[:id])
  end

  def update_role
    role_id = params[:site_user][:role_id].to_i
    @user = SiteUser.find(params[:id])

    @user.role_ids = [ role_id ]
    success = true

    # TODO ensure there at least one admin

    record = current_user.site_user_records.create(
      :action => 'update_user_role',
      :success => success,
      :param1 => params[:id],
    )

    SiteUserMailer.edit_user_warning(current_user, @user, record).deliver

    if success
      flash[:notice] = "Privileges updated!"
      stats_increment_global 'gm.user.update_role.success'
      render :edit_role
    else
      flash[:error] = "Something wrong!"
      stats_increment_global 'gm.user.update_role.failure'
      render :action => :edit_role
    end
  end

  def edit_active
    @user = SiteUser.find(params[:id])
  end

  def update_active
    active = params[:site_user][:active]
    @user = SiteUser.find(params[:id])

    # TODO ensure there at least one admin

    current_user.site_user_records.create(
      :action => 'update_user_active',
      :success => true,
      :param1 => params[:id],
    )

    @user.active = (active == '1')
    @user.reset_persistence_token unless @user.active
    success = (@user.save)

    if success
      flash[:notice] = "Privileges updated!"
      stats_increment_global 'gm.user.update_active.success'
      render :edit_active
    else
      flash[:error] = "Something wrong!"
      stats_increment_global 'gm.user.update_active.failure'
      render :edit_active
    end
  end

  def reset_failed_login_count
    @user = SiteUser.find(params[:id])

    old_count = @user.failed_login_count
    @user.failed_login_count = 0
    success = (@user.save)

    current_user.site_user_records.create(
      :action => 'reset_failed_login_count',
      :success => success,
      :param1 => params[:id],
      :param2 => old_count,
    )

    if success
      flash[:notice] = "Reset failed login count success!"
      stats_increment_global 'gm.user.reset_failed_login_count.success'
      render :edit_active
    else
      flash[:error] = "Something wrong!"
      stats_increment_global 'gm.user.reset_failed_login_count.failure'
      render :edit_active
    end
  end

  def deliver_verification_instructions
    @user = SiteUser.find(params[:id])

    if @user.verified
      success = false
    else
      success = @user.deliver_verification_instructions! rescue false
    end

    current_user.site_user_records.create(
      :action => 'deliver_verification_instructions',
      :success => success,
      :param1 => params[:id],
    )

    if success
      flash[:notice] = "Success! Verification instructions will be delivered in a few seconds"
      stats_increment_global 'gm.user.deliver_verification_instructions.success'
      render :show_super
    else
      flash[:error] = "Something wrong!"
      stats_increment_global 'gm.user.deliver_verification_instructions.failure'
      render :show_super
    end
  end

  def skip_verification
    @user = SiteUser.find(params[:id])

    if @user.verified
      success = false
    else
      @user.verify!
      success = true
    end

    current_user.site_user_records.create(
      :action => 'skip_verification',
      :success => success,
      :param1 => params[:id],
    )

    if success
      flash[:notice] = "Skip Verfication Success!"
      stats_increment_global 'gm.user.skip_verification.success'
      render :show_super
    else
      flash[:error] = "Something wrong!"
      stats_increment_global 'gm.user.skip_verification.failure'
      render :show_super
    end
  end

end
