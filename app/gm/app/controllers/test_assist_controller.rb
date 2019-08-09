# test_assist_controller.rb
require 'boot/helpers/loggable'
class Log_
  include Boot::Loggable
end

class TestAssistController < ApplicationController

  include ApplicationHelper

  layout 'main'

  before_filter :require_user

  access_control do
    allow :admin, :p0, :p1
    allow :p2, :p3 => [:set_main_quest, :add_branch_quest, :add_story_quest, :reset_all_quest, :unlock_all, :reset_position]
    allow :p4, :p5 => [:reset_position]
  end

  protect_from_forgery

  include RsRails

  def skill_tools
  end

  def unlock_all_skills
    return unless AppConfig.dev_mode?

    success = false
    id = params.uid.to_i
    zone = params.zone.to_i
    if id.nil? || id == ''
      render json: { 'success' => false }
      return
    end

    success = CachedGameData.ask(id, zone, UnlockAllSkillsJob)

    current_user.site_user_records

    current_user.site_user_records.create(
      :action => 'test_assist_unlock_all_skills',
      :success => success,
      :target => id,
      :zone => zone,
    )

    notify_gm_edit(id, zone, success)
    render json: { 'success' => success }
  end

  def player_tools
  end

  def all_firevale_ids
    all_user_ids = YousiPlayerIdManager.all_user_ids
    render json: all_user_ids
  end

  def all_chongzhi_ids
    record = PayDb.dump_json2
    render json: record
  end

  def set_main_quest
    success = false
    id = params.uid.to_i
    zone = params.zone.to_i
    qid = params.qid

    success = CachedGameData.ask(id, zone, SetMainQuestJob, qid)

    current_user.site_user_records.create(
      :action => 'test_assist_set_main_quest',
      :success => success,
      :target => id,
      :zone => zone,
    )


    notify_gm_edit(id, zone, success)
    render json: { 'success' => success }
  end

  def add_branch_quest
    success = false
    id = params.uid.to_i
    qid = params.qid
    zone = params.zone.to_i

    success = CachedGameData.ask(id, zone, AddBranchQuestJob, qid)

    current_user.site_user_records.create(
      :action => 'test_assist_add_branch_quest',
      :success => success,
      :target => id,
      :zone => zone,
    )


    notify_gm_edit(id, zone, success)
    render json: { 'success' => success }
  end

  def add_story_quest
    success = false
    id = params.uid.to_i
    zone = params.zone.to_i
    pid = params.pid

    success = CachedGameData.ask(id, zone, AddStoryQuestJob, pid)

    current_user.site_user_records.create(
      :action => 'test_assist_add_story_quest',
      :success => success,
      :target => id,
      :zone => zone,
    )


    notify_gm_edit(id, zone, success)
    render json: { 'success' => success }
  end

  def reset_all_quest
    return unless AppConfig.dev_mode?


    success = false
    id = params.uid.to_i
    zone = params.zone.to_i

    success = CachedGameData.ask(id, zone, ResetAllQuestJob)

    current_user.site_user_records.create(
      :action => 'test_assist_reset_all_quest',
      :success => success,
      :target => id,
      :zone => zone,
    )

    notify_gm_edit(id, zone, success)
    render json: { 'success' => success }
  end

  def send_ability_gifts
    success = false
    id = params.uid.to_i
    zone = params.zone.to_i

    success = CachedGameData.ask(id, zone, SendAbilityItemsJob)

    current_user.site_user_records.create(
      :action => 'test_assist_send_ability_gifts',
      :success => success,
      :target => id,
      :zone => zone,
    )


    notify_gm_edit(id, zone, success)
    render json: { 'success' => success }
  end

  def send_gifts
    return unless AppConfig.dev_mode?

    success = false
    id = params.uid.to_i
    zone = params.zone.to_i

    success = CachedGameData.ask(id, zone, SendGiftItemsJob)

    current_user.site_user_records.create(
      :action => 'test_assist_send_gifts',
      :success => success,
      :target => id,
      :zone => zone,
    )

    notify_gm_edit(id, zone, success)
    render json: { 'success' => success }
  end

  def send_item

    success = false
    id = params.uid.to_i
    zone = params.zone.to_i
    tid = params.tid
    item_count = params.item_count.to_i
    Log_.info("before check send item job data11: #{params.item_count}")

    if id.nil? || id == '' || tid.nil? || tid == '' || item_count < 0
      render json: { 'success' => false }
      return
    end
    Log_.info("before check send item job data22:#{id} #{zone} #{tid}, #{item_count}")
    success = CachedGameData.ask(id, zone, SendItemJob, tid, item_count, 1)

    current_user.site_user_records.create(
      :action => 'test_assist_send_item',
      :success => success,
      :target => id,
      :zone => zone,
      :tid => tid,
      :count => item_count,
    )

    notify_gm_edit(id, zone, success)
    render json: { 'success' => success }
  end

  def send_equip

    success = false
    id = params.uid.to_i
    zone = params.zone.to_i
    tid = params.tid
    equip_level = [params.equip_level.to_i, 1].max
    # Log_.info("send_equip:id:#{id} zone:#{zone} tid:#{tid}" )
    count = 1
    if id.nil? || id == '' || tid.nil? || tid == ''
      render json: { 'success' => false }
      return
    end

    success = CachedGameData.ask(id, zone, SendItemJob, tid, count, equip_level)

    current_user.site_user_records.create(
      :action => 'test_assist_send_equip',
      :success => success,
      :target => id,
      :zone => zone,
      :tid => tid,
      :count => count,
      :param3 => "level=#{equip_level}",
    )

    notify_gm_edit(id, zone, success)
    render json: { 'success' => success }
  end

  def send_do_drop
    return unless AppConfig.dev_mode?

    success = false
    id = params.uid.to_i
    zone = params.zone.to_i
    tid = params.tid
    # Log_.info("send_equip:id:#{id} zone:#{zone} tid:#{tid}" )
    if id.nil? || id == '' || tid.nil? || tid == ''
      render json: { 'success' => false }
      return
    end

    success = CachedGameData.ask(id, zone, DoDropJob, tid)

    current_user.site_user_records.create(
      :action => 'test_assist_send_do_drop',
      :success => success,
      :target => id,
      :zone => zone,
      :tid => "#{tid}",
    )

    notify_gm_edit(id, zone, success)
    render json: { 'success' => success }
  end

  def send_debug_suit
    return unless AppConfig.dev_mode?

    success = false
    id = params.uid.to_i
    zone = params.zone.to_i

    success = CachedGameData.ask(id, zone, SendDebugSuitJob)

    current_user.site_user_records.create(
      :action => 'test_assist_send_debug_suit',
      :success => success,
      :target => id,
      :zone => zone,
    )


    notify_gm_edit(id, zone, success)
    render json: { 'success' => success }
  end

  def clear_bag
    return unless AppConfig.dev_mode?

    success = false
    id = params.uid.to_i
    zone = params.zone.to_i
    if id.nil? || id == ''
      render json: { 'success' => false }
      return
    end

    success = CachedGameData.ask(id, zone, ClearBagJob)

    current_user.site_user_records.create(
      :action => 'test_assist_clear_bag',
      :success => success,
      :target => id,
      :zone => zone,
    )

    notify_gm_edit(id, zone, success)
    render json: { 'success' => success }
  end

  def reset_position
    success = false
    id = params.uid.to_i
    zone = params.zone.to_i
    if id.nil? || id == ''
      render json: { 'success' => false }
      return
    end

    success = CachedGameData.ask(id, zone, ResetPositionJob)

    current_user.site_user_records.create(
      :action => 'test_assist_reset_position',
      :success => success,
      :target => id,
      :zone => zone,
    )

    notify_gm_edit(id, zone, success)
    render json: { 'success' => success }
  end

  def set_credit
    return unless AppConfig.dev_mode?

    success = false
    id = params.uid.to_i
    zone = params.zone.to_i
    credits = params.credits.to_i
    coins = params.coins.to_i
    money = params.money.to_i

    if id.nil? || id == ''
      render json: { 'success' => false }
      return
    end

    success = CachedGameData.ask(id, zone, SetCreditJob, credits, coins, money)

    current_user.site_user_records.create(
      :action => 'test_assist_set_credit',
      :success => success,
      :target => id,
      :zone => zone,
      :param3 => "credits=#{credits} coins=#{coins} money=#{money}",
    )

    notify_gm_edit(id, zone, success)
    render json: { 'success' => success }
  end

  def set_energy

    success = false
    id = params.uid.to_i
    zone = params.zone.to_i
    energy = params.energy.to_i

    if id.nil? || id == ''
      render json: { 'success' => false }
      return
    end

    success = CachedGameData.ask(id, zone, SetEnergyJob, energy)

    current_user.site_user_records.create(
      :action => 'test_assist_set_energy',
      :success => success,
      :target => id,
      :zone => zone,
      :tid => "energy",
      :count=>energy,
    )

    notify_gm_edit(id, zone, success)
    render json: { 'success' => success }
  end

  def unlock_all
    return unless AppConfig.dev_mode?

    id = params.uid.to_i
    zone = params.zone.to_i

    CachedGameData.ask(id, zone, UnlockAllFunctions)

    current_user.site_user_records.create(
      :action => 'test_assist_unlock_all',
      :success => success,
      :target => id,
      :zone => zone,
    )

    notify_gm_edit(id, zone, true)
    render json: { 'success' => true }
  end

  def city_tools
  end

  def clear_city_time_offset
    return unless AppConfig.dev_mode?

    Log_.info('clear_city_time_offset enter')
    zone = params.zone.to_i
    city = CityDb.get_city(zone)
    city.city_time.clear_time_offset()

    Log_.info("clear_city_time_offset #{city.city_time.time_offset}")

    current_user.site_user_records.create(
      :action => 'test_assist_clear_city_time_offset',
      :success => true,
    )

    CityDb.save_city(zone, city)
    Channel.publish_system_invalidate_cache(CityDb, 'get_city', zone)
    render json: { 'success' => true }
  end

  def skip_to_next_city_time
    return unless AppConfig.dev_mode?

    Log_.info('skip_to_next_city_time enter')
    zone = params.zone.to_i
    city = CityDb.get_city(zone)
    city.city_time.skip_to_next_city_time()

    Log_.info("skip_to_next_city_time #{city.city_time.time_offset}")

    current_user.site_user_records.create(
      :action => 'test_assist_skip_to_next_city_time',
      :success => true,
    )


    CityDb.save_city(zone, city)
    Channel.publish_system_invalidate_cache(CityDb, 'get_city', zone)
    render json: { 'success' => true }
  end

  def skip_to_next_weather
    return unless AppConfig.dev_mode?

    Log_.info('skip_to_next_weather enter')
    zone = params.zone.to_i
    city = CityDb.get_city(zone)
    city.city_weather.skip_to_next_weather()

    Log_.info("skip_to_next_weather done")

    current_user.site_user_records.create(
      :action => 'test_assist_skip_to_next_weather',
      :success => true,
    )

    CityDb.save_city(zone, city)
    Channel.publish_system_invalidate_cache(CityDb, 'get_city', zone)
    render json: { 'success' => true }
  end

  def notify_upload_log
    Log_.info('notify_upload_log enter')

    zone = params.zone.to_i
    uid = params.uid.to_i
    lua_script = params.lua_script

    data = {
      'uid' => uid,
      'zone' => zone,
      'lua_script' => lua_script,
    }

    Channel.publish('upload_logs', zone, data)

    @uploaded_logs = UploadGameLog.blpop(uid)

    # Log_.info("notify_upload_log done #{@uploaded_logs}")
    render json: { 'success' => true, 'uploaded_log' => @uploaded_logs }
  end

  def show_auto_log
    Log_.info('show_auto_log enter')

    zone = params.zone.to_i
    uid = params.uid.to_i

    data = {
      'uid' => uid,
      'zone' => zone,
    }

    Channel.publish('upload_logs', zone, data)

    @client_auto_log = UploadGameLog.get_auto_log(uid)

    # Log_.info("show_auto_log done #{@uploaded_logs}")
    render json: { 'success' => true, 'client_auto_log' => @client_auto_log }
  end

  def incr_event_attr
  end
end
