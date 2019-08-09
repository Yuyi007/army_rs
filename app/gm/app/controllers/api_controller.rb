require 'uri'
require 'digest/md5'
require 'net/http'

class ApiController < ApplicationController

  include RsRails

  layout 'main'

  protect_from_forgery

  before_filter :set_locale, :set_default_url_options

  @@apiSecret = 'a3ce6f7a541cda538f68b7eed7334043'

  def client_version
    platform = params[:platform]
    sdk = params[:sdk]
    version = params[:version]
    sign = params[:sign]

    if validate_sign(params, sign)
      success = set_client_version(platform, sdk, version)
    else
      success = false
    end

    logger.info "[API] action=client_version success=#{success} params=#{platform}, #{sdk}, #{version}, #{sign}"

    render :json => { 'success' => success }
  end

  # def ensure_worker_threads
  #   RsRails.ensure_worker_threads
  # end

  def process_redeemed_cdkeys
    sign = params[:sign]

    if validate_sign(params, sign)
      total = Cdkey.process_redeemed_cdkeys
      success = true
    else
      success = false
    end

    logger.info "[API] action=process_redeemed_cdkeys total=#{total} #{sign}"

    render :json => { 'success' => success, 'total' => total }
  end

  def list_zones
    sign = params[:sign]
    zones = []
    if validate_sign(params, sign)
      cfg_zones = GameConfig.zones
      zone_num = num_open_zones
      zone_num.times do |i|
        zones << cfg_zones[i]
      end
      success = true
    else
      success = false
    end

    logger.info "[API] action=list_zones zones=#{zones} #{sign}"

    render :json => { 'success' => success, 'detail' => zones }
  end

  def is_valid_cdkey
    sign = params[:sign]
    zone_id = params[:zone_id].to_i
    cdkey = params[:cdkey]
    detail = ""
    if validate_sign(params, sign)
      details = CdkeyDb.get_detail(cdkey)
      if details.nil?
        detail = "cdkey_not_exist"
        success = false
      else
        #sdk, repeat_num, tid , end_time, bonus_id, count
        sdk = details[0]
        repeat_num = details[1].to_i
        cdkey_tid = details[2]
        cdkey_end_time = details[3].to_i
        cdkey_bonus_id = details[4]
        cdkey_count     = details[5].to_i
        if Time.now.to_i - 10 > cdkey_end_time
          detail = "cdkey_expired"
          success = false
        elsif cdkey_count <= 0
          detail = "cdkey_redeemed"
          success = false
        else
          detail = {
            :sdk => sdk,
            :repeat_num => repeat_num,
            :cdkey_tid => cdkey_tid,
            :cdkey_end_time => cdkey_end_time,
            :cdkey_bonus_id => cdkey_bonus_id,
            :cdkey_count => cdkey_count,
          }
          success = true
        end
      end
    else
      success = false
    end

    logger.info "[API] action=is_valid_cdkey detail=#{detail}  #{sign}"

    render :json => { 'success' => success, 'detail' => detail }
  end

  def get_game_characters
    sign = params[:sign]
    zone_id = params[:zone_id].to_i
    user_id = params[:user_id]

    detail = ""
    if validate_sign(params, sign)
      #check user info
      player_id = YousiPlayerIdManager.get_player_id(user_id)
      if player_id
        hash = CachedGameData.ask(player_id, zone_id, ReadCachedGameDataJob)
        model = GameData.new_game_data_model(player_id, zone_id).from_hash! hash
        detail = []
        if model and model.instances then
          model.instances.each do |id, data|
            detail << {
              :id => data.player_id,
              :name => data.name,
            }
            success = true
          end
        end
      else
        detail = "user_id_not_exist"
        success = false
      end
    else
      success = false
    end

    logger.info "[API] action=get_game_characters detail=#{detail}  #{sign}"

    render :json => { 'success' => success, 'detail' => detail }
  end

  def list_user_zones
    sign = params[:sign]
    user_id = params[:user_id]
    detail = ""
    if validate_sign(params, sign)
      player_id = YousiPlayerIdManager.get_player_id(user_id)
      if player_id
        detail = PlayerZones.get(player_id)
        success = true
      else
        detail = "user_id_not_exist"
        success = false
      end
    else
      success = false
    end

    logger.info "[API] action=list_user_zones detail=#{detail} #{sign}"

    render :json => { 'success' => success, 'detail' => detail }
  end


  def use_cdkey
    sign = params[:sign]
    zone_id = params[:zone_id].to_i
    game_character_id = params[:game_character_id]
    cdkey = params[:cdkey]
    sdk = params[:sdk]
    # zone_id = 1
    # game_character_id = "1_10000002_i3"
    # cdkey = "9c11-b209-41c9-8653-b35f"
    detail = ""
    success = true
    logger.info "[API] action=use_cdkey zone_id=#{zone_id} #{cdkey},#{sdk}, #{game_character_id}"
    if validate_sign(params, sign)
      details = CdkeyDb.get_detail(cdkey)
      # logger.info "[API] action=use_cdkey 222=#{details}"
      if details.nil?
        detail = "cdkey_not_exist"
        success = false
      else
        # sdk, repeat_num, tid, time, bonus_id, count = *self.cdkeys[:all].hget(cdkey).split(',')
        cdkey_sdk = details[0]
        repeat_num = details[1].to_i
        cdkey_tid = details[2]
        cdkey_end_time = details[3].to_i
        cdkey_bonus_id = details[4]
        cdkey_count     = details[5].to_i
        #check user info
        zone, player_id, instance_id = game_character_id.split("_")
        if zone.nil? || player_id.nil? || instance_id.nil?
          success = false
          detail = "error_gamecharacter_id"
        elsif (cdkey_sdk != "all") && (cdkey_sdk != sdk)
          success = false
          detail = "error_sdk"
        else
          player_id = player_id.to_i
          # logger.info "[API] action=use_cdkey 333=#{zone}, #{player_id}, #{instance_id}"
          hash = CachedGameData.ask(player_id, zone_id, ReadCachedGameDataJob)
          if hash
            model = GameData.new_game_data_model(player_id, zone_id).from_hash! hash
            instance = model.instances[instance_id]
            record_count = 0
            # logger.info "[API] action=use_cdkey 444=#{instance.record.cdkeys[cdkey_tid]}, #{repeat_num}"
            unless instance.record.cdkeys[cdkey_tid].nil?
                unless instance.record.cdkeys[cdkey_tid].size < repeat_num
                  success = false
                  detail = "user_redeem_maxed"
                end
            end
            # logger.info "[API] action=use_cdkey 555=#{success}, #{detail}"
            if success
              res, detail = CdkeyDb.redeem(sdk, game_character_id, zone_id, cdkey)
              detail = {:sdk_id => detail}
              # logger.info "[API] action=use_cdkey 666=#{res}, #{detail}"
              if res
                instance.record.cdkeys[cdkey_tid] ||= []
                instance.record.cdkeys[cdkey_tid] << cdkey
                save_game_data(player_id, zone_id, model)
                # Mailbox.deliver_bonuses(game_character_id,
                #   [{"tid" => cdkey_bonus_id, "num" => 1}],
                #   {"text" => 'str_cdkey_mail_text',"kind" => 'str_cdkey_mail_name'}
                #   )


                bonuses = []
                bonus_datas = cdkey_bonus_id.split("|")
                bonus_datas.each do |one_bonus|
                    sub_bonus_data = one_bonus.split("*")
                    if sub_bonus_data.size == 2
                        bonuses << {"tid" => sub_bonus_data[0], "num" => sub_bonus_data[1].to_i}
                    else
                        bonuses << {"tid" => sub_bonus_data[0], "num" => 1}
                    end
                end
                # puts "check bonuses: #{bonuses}"
                Mailbox.deliver_bonuses(game_character_id,
                                        bonuses,
                                        {"text" => 'str_cdkey_mail_text',"kind" => 'str_cdkey_mail_name'}
                                        )
                # logger.info "[API] action=use_cdkey 777"

              end
              #send user email
              success = res
            end
          else
            detail = "player_not_exist"
            success = false
          end
        end
      end
    else
      success = false
    end

    logger.info "[API] action=use_cdkey #{success}, detail=#{detail}  #{sign}"

    render :json => { 'success' => success, 'detail' => detail }
  end



  def process_action_log
    sign = params[:sign]

    if validate_sign(params, sign)
      total = ActionLog.process_remain_logs
      success = true
    else
      success = false
    end

    logger.info "[API] action=process_action_log total=#{total} #{sign}"

    render :json => { 'success' => success, 'total' => total }
  end


  def maintainance
    on = params[:on] == 'true'
    start_at = params[:start_at]
    end_at = params[:end_at]
    #ip_whitelist = params[:ip_whitelist]
    sign = params[:sign]
    id_whitelist = params[:id_whitelist]

    if validate_sign(params, sign)
      status = get_maintainance_status
      status.on = on if not on.nil?
      if status.on and start_at == nil and end_at == nil
        start_at = Time.now.to_i
        end_at = Time.now.to_i + 3600
      end
      status.start_at = start_at if start_at
      status.end_at = end_at if end_at
      #status.ip_whitelist = ip_whitelist if ip_whitelist
      status.id_whitelist = id_whitelist if id_whitelist

      success = set_maintainance_status(status)
    else
      success = false
    end

    logger.info "[API] action=maintainance success=#{success} params=#{on}, #{start_at}, #{end_at}, #{id_whitelist}, #{sign}"

    render :json => { 'success' => success }
  end

  private

  def validate_sign(params, sign)
    str = ''
    params.sort.each do |k, v|
      k = k.to_s
      if k != 'sign' and k != 'controller' and k != 'action' and v and v.length > 0
        str << URI.decode(v) << '#'
      end
    end
    str << @@apiSecret

    return (Digest::MD5.hexdigest(str.encode('UTF-8')) == sign)
  end

end
