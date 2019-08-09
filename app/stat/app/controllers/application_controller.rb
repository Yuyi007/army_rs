class ApplicationController < ActionController::Base
  include RsRails

  protect_from_forgery

  @@game_config  = nil

  def get_zones
    @@game_config = @@game_config || load_game_config
    zones = @@game_config['zones']
    res = {'success' => 'ok', 'res' => zones}
    sendc(res)
  end

  def cfg_zones
    @@game_config = @@game_config || load_game_config
    @@game_config['zones']
  end

  def game_config
    @@game_config = @@game_config || load_game_config
    @@game_config
  end

  def uuid
    sid = SecureRandom.hex(16)
    sid.encode!(Encoding::UTF_8)
    sid
  end

  def sign_up(uid)
    sid = uuid
    session[sid] = uid
    sid
  end

  def check_session(sid = nil)
    sid = params[:sid]
    return nil if sid.nil?
    return session[sid]
  end


  def remove_session(sid)
    session.delete(sid)
  end

  def sendc(res)
    respond_to do |format|
      format.json { render json: res }
    end
  end

  def sendok
    respond_to do |format|
      format.json { render json: {'success' => 'ok'} }
    end
  end

  def ng(reason)
    sendc({'success' => 'fail', 'reason' => reason.to_s})
    true
  end

  def execSql(sql)
    ActiveRecord::Base.connection.exec_query(sql)
  end

  private

  def load_game_config
    file_path = File.expand_path(File.join(File.dirname(__FILE__), "../../../../game-config/config.json"))
    inflated = IO.read(file_path)
    Oj.load(inflated) 
  end
end
