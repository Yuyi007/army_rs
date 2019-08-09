# update.rb

class Update < Handler

  @@open_zones = {}
  @@last_refresh_open_zones = nil

  def self.process(session, msg)
    platform = msg.platform
    sdk = msg.sdk
    market = msg.market || ''
    pkg_version = msg.pkgVersion || ''
    client_version = msg.clientVersion
    location = msg.location

    session.platform = msg.platform
    session.sdk = msg.sdk
    session.location = msg.location
    session.encoding = msg.encoding
    session.codec_state = CodecState.new

    base_url = AppConfig.server['publish_url']
    # check = (!AppConfig.server['disable_publish'])
    current_version = DynamicAppConfig.client_version platform, sdk
    current_pkg_version = DynamicAppConfig.pkg_version platform, sdk

    d { "current_version = #{current_version}" }


    res = {
      'url' => base_url + '/' + current_version.to_s,
      # 'server_settings' => server_settings,
    }

    # if current_pkg_version && !current_pkg_version.empty? &&
    #    !pkg_version.start_with?(current_pkg_version) && platform == 'android'
      # 强制更新
      # res['pkg_version'] = current_pkg_version
      # res['pkg_url'] = "#{base_url}/dhjh-#{platform}-#{sdk}-#{market}-#{current_pkg_version}.apk"

    if current_version && !current_version.empty? &&
          current_version != client_version
      # 游戏内更新
      res['client_version'] = current_version
      res['concurrent_downloads'] = 4
    end



    zone_res = GetOpenZones.do_process(session, msg)
    res.merge!(zone_res)

    d { "res=#{res}" }

    # check hot patch code
    lpcode = ClientHotPatchDb.get_patch_code_cached()
    res['client_lua_patch_code'] = lpcode if lpcode

    # if required server pkg version is smaller than the client pkgversion, disable the client update
    if current_pkg_version && !current_pkg_version.gsub(' ', '').empty? && current_pkg_version < pkg_version
      res['client_version'] = ''
      res.delete('client_lua_patch_code')
    end

    res
  end

end
