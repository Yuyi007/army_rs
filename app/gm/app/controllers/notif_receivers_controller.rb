
class NotifReceiversController < ApplicationController

  include Statsable
  include RsRails

  layout 'main'

  protect_from_forgery

  before_filter :require_user, :only => [ :new, :create, :show, :edit, :update, :list, :index ]

  access_control do
    allow :admin, :p0
  end

  def new
    @receiver = NotifReceiver.new
  end

  def create
    @receiver = NotifReceiver.new(params[:notif_receiver])

    if @receiver.save
      flash[:notice] = "Receiver created!"
      current_user.site_user_records.create(
        :action => 'create_notif_receiver',
        :success => true,
      )
      redirect_to list_notif_receivers_url
    else
      flash[:notice] = "There was a problem creating receiver."
      render :action => :new
    end
  end

  def show
    @receiver = NotifReceiver.find(params[:id])
  end

  def edit
    @receiver = NotifReceiver.find(params[:id])
  end

  def update
    @receiver = NotifReceiver.find(params[:id])
    res = @receiver.update_attributes(params[:notif_receiver])

    current_user.site_user_records.create(
      :action => 'update_notif_receiver',
      :success => res,
    )

    if res
      flash[:notice] = "Receiver updated!"
      render :edit
    else
      flash[:error] = "Something wrong!"
      render :action => :edit
    end
  end

  def destroy
    @receiver = NotifReceiver.find(params[:id])
    res = @receiver.destroy()

    current_user.site_user_records.create(
      :action => 'delete_notif_receiver',
      :success => res,
    )

    if res
      flash[:notice] = "Receiver deleted!"
      redirect_to list_notif_receivers_url
    else
      flash[:error] = "Something wrong!"
      redirect_to list_notif_receivers_url
    end
  end

  def list
    @receivers = NotifReceiver.find(:all)
  end

  def index
    @receivers = NotifReceiver.find(:all)
    render :list
  end

end
