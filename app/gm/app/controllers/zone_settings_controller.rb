class ZoneSettingsController < ApplicationController

  include RsRails

  layout 'main'

  protect_from_forgery

  before_filter :require_user

  access_control do
    allow :admin, :p0, :p1, :p2
  end

  def index
    @zone_settings = DynamicAppConfig.get_zone_settings

    sync_zone_settings @zone_settings, false
    @zone_settings
    @numOpenZones = num_open_zones
  end

  def sync_zone_settings zone_settings, set_capacity
    logger.debug "sync_zone_settings: zone_settings=#{zone_settings}"
    zones = GameConfig.zones

    zones.each_with_index do |zone, idx|
      zone_id = idx + 1
      setting = zone_settings.settings[zone_id]
      if not setting
        logger.info "sync_zone_settings: add zone #{zone}"
        setting = ZoneSetting.new zone_id
        zone_settings.settings[zone_id] = setting
      end
      setting.name = zone['name']
      setting.status = zone['status']
      if set_capacity and setting.max_online <= 0
        setting.max_online = zone['capacity']
      end
    end

    zone_settings.settings.keys.each do |zone_id|
      if not zones[zone_id - 1]
        logger.info "sync_zone_settings: delete zone #{setting}"
        zone_settings.settings.delete(zone_id)
      end
    end

    # logger.debug "sync_zone_settings: zone list #{zone_settings.settings}"
  end

  def fix_zone_settings new_settings
    # logger.info "fix_zone_settings: new_settings=#{new_settings}"
    zone_settings = ZoneSettings.new
    all_groups = {}

    # build zone settings
    new_settings.each do |zone_id, zone|
      if zone.is_a? ZoneSetting then
        zone_id = zone.zone_id
        zone_name = zone.name
        zone_status = zone.status
        recommend = zone.recommend
        max_online = zone.max_online
        zone_group = zone.zone_group
        divisions = zone.divisions
      else
        zone_id = zone['zone_id'].to_i
        zone_name = zone['name']
        zone_status = zone['status']
        recommend = (zone['recommend'] == 'true' or zone['recommend'] == true)
        max_online = zone['max_online'].to_i
        zone_group = zone['zone_group'].to_i
        divisions = zone['divisions'].to_i
      end

      setting = ZoneSetting.new zone_id
      zone_settings.settings[zone_id] = setting

      setting.zone_id = zone_id
      setting.name = zone_name
      setting.status = zone_status
      setting.recommend = recommend
      setting.max_online = max_online.to_i
      setting.zone_group = zone_group.to_i
      setting.divisions = divisions.to_i

      if setting.zone_group > 0
        all_groups[setting.zone_group] ||= []
        all_groups[setting.zone_group] << setting
      end
    end

    # shrink max online in one zone_group
    all_groups.each do |zone_group, settings|
      total_max_online = 0
      settings.each do |setting|
        total_max_online += setting.max_online
      end
      if total_max_online > DynamicAppConfig::ZoneSetting::DEFAULT_MAX_ONLINE
        ratio = DynamicAppConfig::ZoneSetting::DEFAULT_MAX_ONLINE / total_max_online.to_f
        logger.info "fix_zone_settings: shrink zone group #{zone_group} max_online by #{ratio}"
        settings.each do |setting|
          setting.max_online = (setting.max_online * ratio).to_i
        end
      end
    end

    logger.info "fix_zone_settings: #{zone_settings.to_json}"
    zone_settings
  end

  # quick set in open zone view
  def open_zone_auto_set
    new_settings = DynamicAppConfig.get_zone_settings
    sync_zone_settings new_settings, true
    @zone_settings = fix_zone_settings(new_settings.settings.to_hash)

    success = self.set_zone_settings(@zone_settings)

    current_user.site_user_records.create(
      :action => 'open_zone_auto_set_zone_settings',
      :success => success,
      :param1 => "",
      :param2 => "",
      :param3 => "",
    )

    render :index
  end

  def restore_default_settings
    new_settings = ZoneSettings.new
    sync_zone_settings new_settings, true

    zone_settings = fix_zone_settings(new_settings.settings.to_hash)

    success = self.set_zone_settings(zone_settings)

    current_user.site_user_records.create(
      :action => 'restore_zone_settings',
      :success => success,
      :param1 => "",
      :param2 => "",
      :param3 => "",
    )

    render :json => { 'success' => success }
  end

  def save
    new_settings = ActiveSupport::JSON.decode(params[:settings])
    zone_settings = fix_zone_settings(new_settings)

    success = self.set_zone_settings(zone_settings)

    current_user.site_user_records.create(
      :action => 'save_zone_settings',
      :success => success,
      :param1 => "",
      :param2 => "",
      :param3 => "",
    )

    render :json => { 'success' => success }
  end

  def delete
    success = self.set_zone_settings(nil)

    current_user.site_user_records.create(
      :action => 'delete_zone_settings',
      :success => success,
      :param1 => "",
      :param2 => "",
      :param3 => "",
    )

    render :json => { 'success' => success }
  end

end