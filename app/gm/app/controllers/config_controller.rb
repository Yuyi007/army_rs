
class ConfigController < ApplicationController

  layout 'main'

  protect_from_forgery

  before_filter :require_user

  access_control do
     allow :admin, :p0, :p1
  end

  include RsRails
  include ConfigHelper

  def complete
    type = params[:type]
    term = params[:term].downcase
    json = send("_complete_#{type}") rescue []
    json.select! { |item| item[:label].downcase.include?(term) } if term.length > 0

    render :json => json
  end

private

  def _complete_item
    json = []
    GameConfig.config['items'].each do |tid, value|
      json << { id: "#{tid}", label: item_display_name(tid) }
    end
    json.each { |item| item[:category] = t(:item) }
  end

  def _complete_equip
    json = []
    GameConfig.config['equips'].each do |tid, value|
      json << { id: "#{tid}", label: equip_display_name(tid) }
    end
    json.each { |item| item[:category] = t(:equip) }
  end

  def _complete_garment
    json = []
    GameConfig.config['garments'].each do |tid, value|
      json << { id: "#{tid}", label: garment_display_name(tid) }
    end
    json.each { |item| item[:category] = t(:garment) }
  end

  def _complete_special
    json = []
    ['sogs', 'credits', 'stamina', 'spirit', 'exp', 'medals'].each do |tid|
      json << { id: "#{tid}", label: "#{tid}" }
    end
    json.each { |item| item[:category] = t(:special) }
  end

  def _complete_credits
    json = []
    ['chongzhi', 'budan', 'putong'].each do |type|
      json << { id: "#{type}", label: credits_chongzhi_type_name(type) }
    end
    json.each { |item| item[:category] = t(:credits) }
  end
end