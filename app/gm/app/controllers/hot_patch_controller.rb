# hot_patch_controller.rb
require 'boot/helpers/loggable'
class Log_
  include Boot::Loggable
end

class HotPatchController < ApplicationController

  include ApplicationHelper

  layout 'main'

  before_filter :require_user

  access_control do
    allow :admin, :p0, :p1
  end

  protect_from_forgery

  include RsRails

  def client_tools
    @lua_code = ClientHotPatchDb.get_patch_code()
    logger.info "client_tools #{@lua_code}"
  end

  def patch_ruby_code
    Log_.info('patch_ruby_code enter')
    server_ruby_code = params.server_ruby_code
    success = gm_patch_ruby_code(server_ruby_code)
    current_user.site_user_records.create(
      :action => 'hot_patch_patch_ruby_code',
      :success => success,
    )
    render json: { 'success' => success }
  end

  def patch_elixir_code
    Log_.info('patch_elixir_code enter')
    server_elixir_code = params.server_elixir_code
    success = gm_patch_elixir_code(server_elixir_code)
    current_user.site_user_records.create(
      :action => 'hot_patch_patch_elixir_code',
      :success => success,
    )
    render json: { 'success' => success }
  end

  def reload_server_config
    Log_.info('reload_server_config enter')
    success = gm_reload_server_config()
    current_user.site_user_records.create(
      :action => 'hot_patch_reload_server_config',
      :success => success,
    )
    render json: { 'success' => success }
  end

  def patch_client_code
    Log_.info('patch_client_code enter')
    client_lua_code = params.client_lua_code
    success = gm_patch_client_code(client_lua_code)
    current_user.site_user_records.create(
      :action => 'hot_patch_patch_client_code',
      :success => success,
    )
    render json: { 'success' => success }
  end

  def clear_patch_client_code
    Log_.info('clear_patch_client_code enter')
    success = gm_clear_patch_client_code()
    current_user.site_user_records.create(
      :action => 'hot_patch_clear_patch_client_code',
      :success => success,
    )
    render json: { 'success' => success }
  end

end