class ZoneController < ApplicationController

  include RsRails

  layout 'main'

  protect_from_forgery

  before_filter :require_user

  access_control do
    allow :admin, :p0, :p1, :p2
  end

  def index
    @numOpenZones = num_open_zones
  end

  def saveNumOpenZones
    numOpenZones = params[:numOpenZones]

    success = set_num_open_zones(numOpenZones)

    current_user.site_user_records.create(
      :action => 'edit_num_open_zones',
      :success => success,
      :param1 => numOpenZones,
    )

    render :json => { 'success' => success }
  end

end
