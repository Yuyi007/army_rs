require 'cocs/sdk/SDKJd'

class JdController < ActionController::Base

  include RsRails

  def queryRole
    logger.info "queryRole, params: #{params}"
    begin
      sdk = SDKJd.instance

      if sdk.sign_payment(params, logger)
        data = Oj.load(Base64.decode64(params['data']))

        playerId = "#{data['userId']}$jd$"
        zoneId = data['gateWayId'].to_i

        player = @@proxy.player_by_id(playerId, zoneId)

        if player.nil?
          render :json => {:retCode => 108, :retMessage => "no role exists"}
        else
          render :json => {:retCode => 100, :retMessage => "success", :data => Base64.encode64(Oj.dump :roleInfos => [{:roleId => player.id, :roleName => player.name}])}
        end
      else
        logger.error "invalid sign"
        render :json => { :retCode => 103, :retMessage => "invalid sign" }
      end
    rescue Exception => e
      logger.error "error when dispatch goods: #{e.message} #{e.backtrace.inspect}"
      render :json => { :retCode => 999, :retMessage => "exception encountered" }
    end
  end

  def queryOrder
    logger.info "queryOrder, params: #{params}"
    begin
      sdk = SDKJd.instance

      if sdk.sign_payment(params, logger)
        data = Oj.load(Base64.decode64(params['data']))

        records = Bill.where('transId = ?', data['orderId'])

        if records and records.length > 0
          render :json => { :retCode => 100, :retMessage => "success", :data => Base64.encode64(Oj.dump :orderStatus => 0)}
        else
          render :json => { :retCode => 100, :retMessage => "success", :data => Base64.encode64(Oj.dump :orderStatus => 1)}
        end
      else
        logger.error "invalid sign"
        render :json => { :retCode => 103, :retMessage => "invalid sign" }
      end
    rescue Exception => e
      logger.error "error when dispatch goods: #{e.message} #{e.backtrace.inspect}"
      render :json => { :retCode => 999, :retMessage => "exception encountered" }
    end
  end

end