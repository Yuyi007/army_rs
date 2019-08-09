class ArchiveController < ApplicationController

  layout 'main'

  protect_from_forgery

  include RsRails

  before_filter :require_user

  access_control do
    allow :admin, :p0, :p1
  end

  def find
    @id = params[:id]
    @zone = params[:zone].to_i
    @archive_times = ArchiveData.get_archive_times(@id, @zone)
    render :index
  end

  def load
    id = params[:id]
    zone = params[:zone].to_i
    time = params[:time]
    model = ArchiveData.get_archive_model(id, zone, Time.parse(time))
    render :json => model.to_hash
  end

  def delete
    id = params[:id]
    zone = params[:zone].to_i
    time = params[:time]

    success = ArchiveData.delete_archive(id, zone, Time.parse(time))
    if success
      flash[:notice] = "Delete success"
    else
      flash[:error] = "Delete failed!"
    end

    current_user.site_user_records.create(
      :action => 'delete_archive',
      :success => success,
      :zone => zone,
      :target => id,
      :param1 => time
    )

    redirect_to archive_find_url(zone, id)
  end

end
