require 'cocs/helpers/Jsonable'
require 'securerandom'

class OrderController < ApplicationController

  include RsRails

  #protect_from_forgery

  @@logger = Logger.new("#{Rails.root}/log/order.log")

  def generate
    uid = params[:uid]
    zoneId = params[:zoneId].to_i
    price = params[:price]
    credits = params[:credits].to_i
    sign = params[:sign]

    if uid.nil?
      render :json => {'success' => false, 'reason' => 'invalid uid'}
    elsif zoneId.nil?
      render :json => {'success' => false, 'reason' => 'invalid zoneId'}
    elsif price.nil?
      render :json => {'success' => false, 'reason' => 'invalid price'}
    elsif credits.nil?
      render :json => {'success' => false, 'reason' => 'invalid credits'}
    elsif sign != OrderController.klSign(uid, zoneId, price, credits)
      logger.error "invalid sign: #{sign}, should be #{OrderController.klSign(uid, zoneId, price, credits)}"
      render :json => {'success' => false, 'reason' => 'invalid sign'}
    else
      begin
        model = @@proxy.loadGameData(uid, zoneId.to_i)
        if model.nil?
          render :json => {'success' => false, 'reason' => 'specified user not exists'}
        else
          orderId = SecureRandom.uuid()

          platform = model.chief.platform || 'web'

          order = {
              'uid' => uid,
              'zone' => zoneId,
              'goodsNum' => 1,
              'credits' => credits,
              'price' => price.to_f,
              'sdk' => 'kunlunweb',
              'platform' => platform,
              'market' => 'unknown'
          }

          redis = @@proxy.zoneRedis(zoneId.to_i)
          redis.hset "payordersweb", orderId, Jsonable.dump_hash(order)

          @@logger.info "genOrder: #{orderId} => #{Jsonable.dump_hash(order)}"

          render :json => {'success' => true, 'orderId' => "#{orderId}|#{zoneId}", 'platform' => platform}
        end
      rescue => e
        logger.error "Exception: #{e.message}"
        render :json => {'success' => false, 'reason' => "Exception encountered: #{e.message}"}
      end
    end
  end

  def self.klSign(uid, zoneId, price, credits)
    @@kl_key ||= Payment::Application.config.kl_key
    @@kl_key ||= "8ee76bbffc9a89075a04dad985275c68"
    s = "#{uid}#{zoneId}#{price}#{credits}#{@@kl_key}"
    return Digest::MD5.hexdigest(s.encode('UTF-8'))
  end

end