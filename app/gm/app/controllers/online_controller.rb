class OnlineController < ApplicationController

  include RsRails

  layout 'main'

  protect_from_forgery

  before_filter :require_user

  access_control do
    allow :admin, :p0, :p1, :p2, :p3, :p4, :p5
  end

  def index
    @num_open_zones = self.num_open_zones()
    @onlines = {}
    if params[:with_gate]
      @gate_onlines = self.gate_num_onlines
    else
      @gate_onlines = {}
    end

    zones_total = 0
    total = nil

    gate_zones_total = 0
    gate_total = 0

    (1..@num_open_zones).each do |zone_id|
      @onlines[zone_id.to_s] = self.num_online(zone_id)
      zones_total += self.num_online(zone_id)
    end

    @gate_onlines.each do |zone_id, online|
      gate_zones_total += online if zone_id.to_i > 0
      gate_total += online
    end

    @onlines['all_zones'] = zones_total
    @onlines['no_zone'] = nil
    @onlines['total'] = total
    @gate_onlines['all_zones'] = gate_zones_total
    #@gate_onlines['no_zone'] already set
    @gate_onlines['total'] = gate_total
  end

  def fix

    online_ids = self.gate_onlines_ids
    online_ids.each do |zone_id, ids|
      zone = zone_id.to_i
      # Rails.logger.info "fixing online of zone #{zone}"
      all_online_ids = SessionManager.all_online_ids(zone)
      all_online_ids.each do |uid|
        uid = uid.to_i
        if ids.include?(uid) then
          Rails.logger.info "fix: #{uid}:#{zone} is online"
        else
          Rails.logger.info "fix: #{uid}:#{zone} #{session} is not online!!"
          SessionManager.remove_online(uid, zone)
        end
      end
    end

    redirect_to online_index_url
  end

  def clear
    (1..self.num_open_zones()).each do |zone_id|
      zone = zone_id.to_i
      SessionManager.remove_all_onlines(zone)
    end
    redirect_to online_index_url
  end

end