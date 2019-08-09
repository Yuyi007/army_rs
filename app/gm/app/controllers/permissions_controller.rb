class PermissionsController < ApplicationController

  layout 'main'

  protect_from_forgery

  before_filter :require_user

  access_control do
    allow :admin, :p0, :p1
  end

  def index
  end

  def show
    id = params[:id]

    if id.nil? or id.length == 0
      render :index
    else
      @id = id
      @denies = Permission.get_denies id
      @denies.each { |d| d.zones = d.zones.join(' ') }
      @new_deny = DenyInfo.new 'login', nil
    end
  end

  def create
    id = params[:id]
    index = params[:index].to_i
    deny = params[:boot_deny_info]

    res = Permission.add_deny id, deny.name, deny.zones.split(' ')

    current_user.site_user_records.create(
      :action => 'create_deny',
      :success => res,
      :target => id,
      :param1 => index,
      :param2 => deny.name,
      :param3 => deny.zones,
    )

    res ? flash[:notice] = 'Create success' : flash[:error] = 'Create failed'
    redirect_to :action => :show, :id => id
  end

  def update
    id = params[:id]
    index = params[:index].to_i
    deny = params[:boot_deny_info]

    res = Permission.update_deny_by_index id, index, deny.name, deny.zones.split(' ')

    current_user.site_user_records.create(
      :action => 'update_deny',
      :success => res,
      :target => id,
      :param1 => index,
      :param2 => deny.name,
      :param3 => deny.zones,
    )

    res ? flash[:notice] = 'Update success' : flash[:error] = 'Update failed'
    redirect_to :action => :show, :id => id
  end

  def destroy
    id = params[:id]
    index = params[:index].to_i

    res = Permission.remove_deny_by_index id, index

    current_user.site_user_records.create(
      :action => 'destroy_deny',
      :success => res,
      :target => id,
      :param1 => index,
    )

    res ? flash[:notice] = 'Delete success' : flash[:error] = 'Delete failed'
    redirect_to :action => :show, :id => id
  end

  def sort
    id = params[:id]
    indexes = params[:indexes].split('_').reject { |s| s.nil? or s.length == 0 }.map { |s| s.to_i }

    res = Permission.sort_by_indexes id, indexes

    current_user.site_user_records.create(
      :action => 'sort_deny',
      :success => res,
      :target => id,
      :param1 => params[:indexes],
    )

    res ? flash[:notice] = 'Sort success' : flash[:error] = 'Sort failed'
    redirect_to :action => :show, :id => id
  end

end

module Boot

  class DenyInfo

    include ActiveModel::Conversion
    extend ActiveModel::Naming

    def persisted?
      false
    end
  end

end