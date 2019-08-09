# events_controller.rb

class CheckPaymentitempackagesController < ApplicationController
  layout 'check'

  protect_from_forgery

  before_filter :require_user

  helper_method :getPaymentItems, :getPaymentPackages, :getItems

  access_control do
    allow :admin, :p0, :p1, :p2, :p3
  end

  set_tab :check_paymentitempackages



  def index
  end

  def getPaymentItems
    @paymentItems ||= RsRails.getPaymentItemsInfo.to_json
  end

  def getPaymentPackages
    @packages ||= RsRails.getPaymentPackagesInfo.to_json
  end

  def getItems
    @items ||= GameConfig.items.to_json
  end

  def content
    tid = params[:tid]
    item = GameConfig.items[tid]
    a = []
    if item.drops
      a = item.drops.sort_by(&:weight).reverse.map {|d|
        name = GameConfig.strings["str_#{d.tid}_name"]
        grade = 'C'
        grade = d.tid[1] if d.tid !~ /koujue/

        if d.tid =~ /^I/
          grade = GameConfig.items[d.tid].grade
        end

        if d.weight == 0
          "#{grade}-#{name}x#{d.num}"
        else
          rate = ((d.weight.to_f / item.dropsWeight) * 100)
          rate = sprintf("%.8f%", rate)
           "#{grade}-#{name}x#{d.num} (#{rate})"
        end
      }
    end

    render :json => {content: a.join('<br>')}
  end

  def package
    storeId = params[:tid]
    package = GameConfig.paymentItemPackage[storeId]
    if package
      package = package.dup
      package.startTime = TimeHelper.gen_date_time(Time.at(package.startTime))
      package.endTime = TimeHelper.gen_date_time(Time.at(package.endTime))
    end
    render json: package
  end

  def item
    storeId = params[:tid]
    item = GameConfig.paymentitem[storeId]
    if item
      item = item.dup
      item.startTime = TimeHelper.gen_date_time(Time.at(item.startTime))
      item.endTime = TimeHelper.gen_date_time(Time.at(item.endTime))
    end
    render json: item
  end

  def getByDate
    date = params[:date]
    time = TimeHelper.parse_date_time(date)
    all = GameConfig.paymentItemPackage.select{|x| x.startTime >= time and x.endTime <= time}
    render json: all
  end

end