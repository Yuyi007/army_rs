# pay_controller.rb

require 'digest/md5'
require 'openssl'
require 'base64'
require 'oj'
require 'uri'
require 'rexml/document'

class PayController < ApplicationController
  include RsRails
  include Statsable

  # protect_from_forgery

  @@logger = Logger.new("#{Rails.root}/log/goods.log")
  @@firevale_missing_order = Logger.new("#{Rails.root}/log/firevale_missing_orders.log")

  def firevale
    sdk = SDKFirevale.instance
    cp_order_id = params[:cp_order_id]
    price = params[:amount].to_i / 100.0
    order = PayOrder.get(cp_order_id)
    market = params[:market]

    if order
      # logger.info "order=#{order.to_hash}"
      location = params[:location] || order.location || 'cn'

      if sdk.sign_payment(location, params, logger)
        if order.dispatched
          render text: 'ok'
        else
          goods_id = order.goods_id
          cfg = GameConfig.chongzhi[goods_id]

          if cfg then
            price = cfg.cost
          end

          res = PayController.dispatch_goods(
            'uid'         => order.cid,
            'zone'        => order.zone, # zone
            'pid'         => order.pid,
            'sdk'         => order.sdk || 'firevale',
            'platform'    => order.platform, # platform
            'trans_id'    => params[:order_id],
            'goods_id'    => order.goods_id,
            'price'       => price,
            'cp_order_id' => order.id,
            'market'      => market,
          )

          if res
            order.dispatched = true
            order.save
            render text: 'ok'
          else
            logger.error 'firevale: dispatch goods failed'
            render text: 'DISPATCH FAILED', json: { 'success' => false, 'reason' => 'dispatch_goods_failed' }
          end # dispatch goods ok
        end
      else
        logger.error 'firevale: invalid signature'
        stats_increment_global 'payment.firevale.invalid_signature'
        render text: 'INVALID SIGN', json: { 'success' => false, 'reason' => 'invalid_sign' }
      end # valid signature
    else
      logger.error "firevale: invalid cp order id #{cp_order_id}"
      # log order and return ok
      @@firevale_missing_order.info "#{params[:user_id]}, #{params[:cp_order_id]}, #{params[:order_id]}, #{params[:trade_no]}, #{params[:fee]}, #{params[:currency]}"
      stats_increment_global 'payment.firevale.invalid_cp_order_id'
      render text: 'INVALID ORDER', json: { 'success' => false, 'reason' => 'invalid_cp_order_id', 'cp_order_id' => cp_order_id }
    end # valid order
  rescue => er
    logger.error "firevale pay Error: #{er.to_s} #{$ERROR_INFO} at #{$ERROR_POSITION}"
    stats_increment_global 'payment.firevale.error'
    render text: 'failed', json: { 'success' => false, 'reason' => 'pay_error', 'error' => er.to_s }
  end

  def firevale_web
    location = params[:location] || 'cn'
    pid      = params[:game_character_id]
    cid      = params[:game_player_id]
    zone     = params[:zone]
    trans_id = params[:order_id]
    platform = params[:platform]
    goods_id = params[:goods_id]
    price    = params[:price]

    cp_order_id = 'web'

    sdk = SDKFirevale.instance

    location = params[:location] || 'cn'

    if goods_id.nil? || GameConfig.chongzhi[goods_id].nil?
      render json: { 'success' => false, 'reason' => 'invalid goods_id'}
      return
    end

    if sdk.sign_payment(location, params, logger)
      res = PayController.dispatch_goods(
        'uid'         => cid,
        'zone'        => zone, # zone
        'pid'         => pid,
        'sdk'         => 'firevale',
        'platform'    => platform, # platform
        'trans_id'    => trans_id,
        'goods_id'    => goods_id,
        'price'       => price,
        'cp_order_id' => cp_order_id
      )

      if res
        render text: 'ok'
      else
        logger.error 'firevale: dispatch goods failed'
        render text: 'DISPATCH FAILED', json: { 'success' => false, 'reason' => 'dispatch_goods_failed' }
      end # dispatch goods ok

    else
      logger.error 'firevale: invalid signature'
      stats_increment_global 'payment.firevale.invalid_signature'
      render text: 'INVALID SIGN', json: { 'success' => false, 'reason' => 'invalid_sign' }
    end # valid signature

  rescue => er
    logger.error "firevale pay Error: #{er.to_s} #{$ERROR_INFO} at #{$ERROR_POSITION}"
    stats_increment_global 'payment.firevale.error'
    render text: 'failed', json: { 'success' => false, 'reason' => 'pay_error', 'error' => er.to_s }
  end

  private

  def self.dispatch_goods(opt)
    uid         = opt.uid
    zone        = opt.zone
    sdk         = opt.sdk
    platform    = opt.platform
    trans_id    = opt.trans_id
    goods_id    = opt.goods_id
    price       = opt.price
    cp_order_id = opt.cp_order_id
    pid         = opt.pid
    count       = 1
    market      = opt.market

    records = Bill.where('transId = ?', trans_id)

    if records && records.length > 0
      logger.warning "goods already dispatched: #{trans_id} #{uid} #{pid} #{zone} #{goods_id} #{count} #{price} #{cp_order_id}"
      return true
    end

    success = GoodsDispatcher.dispatch(
      id: uid,
      sdk: sdk,
      pid: pid,
      platform: platform,
      zone: zone,
      trans_id: cp_order_id, # client dispatch goods according to cp_order_id
      goods_id: goods_id,
      price: price)

    if success
      begin
        logger.debug "dispatch goods successful: #{trans_id} #{uid} #{pid} #{zone} #{goods_id} #{count} #{price} #{cp_order_id}"

        # save a dispatch log
        @@logger.info("#{Time.now}, #{sdk}, #{trans_id}, #{uid}, #{pid}, #{zone}, #{goods_id}, #{count}, #{price}, #{platform}, #{cp_order_id}")

        # save a bill record for this transaction in our db
        bill = Bill.new(
          sdk: sdk,
          pid: pid,
          platform: platform,
          transId: trans_id,
          playerId: uid,
          zone: zone,
          goodsId: goods_id,
          count: 1,
          price: price,
          detail: cp_order_id,
          market: market,
          status: 0)

        bill.save

        stats_increment_global 'payment.dispatch_goods.success'
      rescue => er
        logger.error "bill save #{er} error:#{$ERROR_INFO} at:#{$ERROR_POSITION}"
        stats_increment_global 'payment.dispatch_goods.error'
      end

      return true
    else
      logger.error "dispatch goods failed: #{trans_id} #{uid} #{pid} #{zone} #{goods_id} #{count} #{price} #{cp_order_id}"
      stats_increment_global 'payment.dispatch_goods.failure'
      return false
    end
  end

  def self.get_price(sdk, goods_id, count)
    cfg = GameConfig.chongzhiCfg(sdk)
    goods = cfg['normal'][goods_id]
    goods['gold'] * count
  end
end
