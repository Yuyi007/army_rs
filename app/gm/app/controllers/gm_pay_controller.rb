class GmPayController < ApplicationController

  include RsRails

  access_control do
    allow :admin, :p0, :p1
  end

  def index

  end

  def add
    pid       = params[:pid]
    zone      = params[:zone].to_i
    uid       = 0
    if pid =~ /^(\d+)_(\d+)_i(\d)$/
      pid_array = pid.split("_")
      zone      = pid_array[0].to_i
      uid       = pid_array[1].to_i
    elsif pid =~ /^(\d+)_i(\d)$/
      pid_array = pid.split("_")
      pid       = "#{zone}_#{pid}"
      uid       = pid_array[0].to_i
    else
      flash.now[:error] = t(:wrong_id_format)
      render "gm_pay/index"
      return
    end

    model = load_game_data(uid, zone)
    if model.nil?
      flash.now[:error] = "#{t(:player)}#{pid}#{t(:not_exist)}"
      render "gm_pay/index"
      return
    end

    recharge  = params[:recharge]
    cfg = GameConfig.chongzhi[recharge]
    price = cfg.cost unless cfg.nil?

    record = model.instance.record
    month_cards = record.month_cards
    month_cards.each do |tid, card|
      mc_cfg = GameConfig.month_card[tid]
      if !mc_cfg.nil? && mc_cfg.recharge_id == recharge && card.valid?
        flash.now[:error] = "#{t(:already_active)}#{cfg.name}!"
        render "gm_pay/index"
        return
      end
    end



    if recharge == "recharge014"
      growth_fund = record.growth_fund
      if growth_fund.bought?
        flash.now[:error] = t(:already_active_czjj)
        render "gm_pay/index"
        return
      end
    end

    trans_id = PayOrder.gen_id
    trans_id = "gm_#{trans_id}"
    ret = GoodsDispatcher.dispatch(
        :id       => uid,
        :pid      => pid,
        :sdk      => "gmt",
        :platform => "gmt",
        :zone     => zone,
        :trans_id => trans_id,
        :goods_id => recharge,
        :price    => price)

    if ret
      flash.now[:notice] = "#{t(:player)}#{pid}  #{cfg.name}#{t(:recharge_success)}"
    else
      flash.now[:error] = "#{t(:player)}#{pid}  #{cfg.name}#{t(:recharge_fail)}"
    end

    item = "#{recharge}_#{cfg.name}"
    current_user.site_user_records.create(
      :action  => 'gm_pay',
      :success => ret,
      :target  => uid,
      :zone    => zone,
      :tid     => item,
      :param1  => trans_id,
      :param2  => pid,
    )

    render "gm_pay/index"
  end
end
