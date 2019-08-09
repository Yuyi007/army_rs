# rewards_controller.rb

class RewardsController < ApplicationController
  include RsRails

  layout 'rewards'

  protect_from_forgery

  before_filter :require_user

  access_control do
    allow :admin, :p0, :p1
  end

  set_tab :package_config



  def packagelist
    @active = "package_link"
    @packages = RsRails.get_package_configs

    if not params[:errorMessage].nil?
      @errorMessage = params[:errorMessage]
    end

    if not params[:successMessage].nil?
      @successMessage = params[:successMessage]
    end
  end

  def packagenew
    @active = "package_link"
  end

  def packageedit
    @active = "package_link"
    @id = params[:id]
end

  def storelist
    @active = "store_link"
    @stores = RsRails.get_store_configs
    @stores.each do |store|
      store['startTime'] = TimeHelper.gen_date_time(Time.at(store['startTime']))
      store['endTime'] = TimeHelper.gen_date_time(Time.at(store['endTime']))
    end
    @auth = curAuth()
    @stores

    if not params[:errorMessage].nil?
      @errorMessage = params[:errorMessage]
    end

    if not params[:successMessage].nil?
      @successMessage = params[:successMessage]
    end
  end

  def storenew
    @active = "store_link"
  end

  def storeedit
    @active = "store_link"
    @id = params[:tid]
  end

  def createPackage
    packageData = {}
    itemDataList = params[:drops].split("<br>")
    packageData['drops'] = []
    itemDataList.each do |data|
      itemId, itemName, itemNum = data.split(",")
      itemInfo = {}
      itemInfo['tid'] = itemId
      itemInfo['name'] = itemName
      itemInfo['num'] = itemNum.to_i < 0 ? 0 : itemNum.to_i
      itemInfo['weight'] = 0
      packageData['drops'] << itemInfo
    end

    packageData['name'] = params[:name]
    packageData['desc'] = params[:desc]
    packageData['assetId'] = params[:assetId]
    packageData['subtype'] = params[:subtype]
    packageData['grade'] = params[:grade]
    packageData['value'] = params[:value].to_i < 0 ? 0 : params[:value].to_i
    packageData['price'] = params[:price].to_i < 0 ? 0 : params[:price].to_i
    packageData['weight'] = params[:weight].to_i < 0 ? 0 : params[:weight].to_i
    packageData['detail'] = params[:detail]
    packageData['usable'] = params[:usable]

    packageData['needKey'] = false
    packageData['chance'] = 0
    packageData['requires'] = ""
    packageData['effect'] = ""
    packageData['dropsweight'] = 0

    res = RsRails.create_package_config(packageData)
    render :json => res
  end

  def updatePackage
    packageData = {}
    itemDataList = params[:drops].split("<br>")
    packageData['drops'] = []
    itemDataList.each do |data|
      itemId, itemName, itemNum = data.split(",")
      itemInfo = {}
      itemInfo['tid'] = itemId
      itemInfo['name'] = itemName
      itemInfo['num'] = itemNum.to_i < 0 ? 0 : itemNum.to_i
      itemInfo['weight'] = 0
      packageData['drops'] << itemInfo
    end

    packageData['tid'] = params[:tid]
    packageData['id'] = params[:id]
    packageData['name'] = params[:name]
    packageData['desc'] = params[:desc]
    packageData['assetId'] = params[:assetId]
    packageData['subtype'] = params[:subtype]
    packageData['grade'] = params[:grade]
    packageData['value'] = params[:value].to_i < 0 ? 0 : params[:value].to_i
    packageData['price'] = params[:price].to_i < 0 ? 0 : params[:price].to_i
    packageData['weight'] = params[:weight].to_i < 0 ? 0 : params[:weight].to_i
    packageData['detail'] = params[:detail]
    packageData['usable'] = params[:usable]

    packageData['needKey'] = false
    packageData['chance'] = 0
    packageData['requires'] = ""
    packageData['effect'] = ""
    packageData['dropsweight'] = 0

    res = RsRails.save_package_config(packageData)
    render :json => res
  end

  def deletePackage
    id = params[:id]
    RsRails.delete_package_config(id)
    flash[:notice] = t(:delete_success, :name => "#{t(:package)} #{id}")
    redirect_to rewards_packagelist_url
  end

  def getPackage
    id = params[:id]
    package = RsRails.get_package_config(id)
    if package
      itemList = package['drops']
      itemInfo = ""
      if itemList
        itemList.each do |item|
          if item
            itemInfo += "#{item['tid']},#{item['name']},#{item['num']}<br>"
          end
        end
      end
      package['drops'] = itemInfo
      render :json => package
    else
      render :json => {}
    end
  end

  def createStore
    userInfo = curUserInfo()
    storeData = {}
    storeData['weight'] = params[:weight].to_i < 0 ? 0 : params[:weight].to_i
    storeData['itemId'] = params[:itemId]
    storeData['num'] = params[:num].to_i < 0 ? 0 : params[:num].to_i
    storeData['status'] = params[:status].to_i < 0 ? 0 : params[:status].to_i
    storeData['needChief'] = params[:needChief].to_i < 0 ? 0 : params[:needChief].to_i
    storeData['price'] = params[:price].to_i < 0 ? 0 : params[:price].to_i
    storeData['specialPrice'] = params[:specialPrice].to_i < 0 ? 0 : params[:specialPrice].to_i
    storeData['vipLevel'] = params[:vipLevel].to_i < 0 ? 0 : params[:vipLevel].to_i
    storeData['buyTimes'] = params[:buyTimes].to_i < 0 ? 0 : params[:buyTimes].to_i
    storeData['startTime'] = TimeHelper.parse_date_time(params[:startTime]).to_i
    storeData['endTime'] = TimeHelper.parse_date_time(params[:endTime]).to_i
    storeData['dayliBuy'] = params[:dayliBuy]

    res = RsRails.create_store_config(storeData)
    render :json => res
  end

  def updateStore
    userInfo = curUserInfo()
    storeData = {}
    storeData['tid'] = params[:tid]
    storeData['id'] = params[:id]
    storeData['weight'] = params[:weight].to_i < 0 ? 0 : params[:weight].to_i
    storeData['itemId'] = params[:itemId]
    storeData['num'] = params[:num].to_i < 0 ? 0 : params[:num].to_i
    storeData['status'] = params[:status].to_i < 0 ? 0 : params[:status].to_i
    storeData['needChief'] = params[:needChief].to_i < 0 ? 0 : params[:needChief].to_i
    storeData['price'] = params[:price].to_i < 0 ? 0 : params[:price].to_i
    storeData['specialPrice'] = params[:specialPrice].to_i < 0 ? 0 : params[:specialPrice].to_i
    storeData['vipLevel'] = params[:vipLevel].to_i < 0 ? 0 : params[:vipLevel].to_i
    storeData['buyTimes'] = params[:buyTimes].to_i < 0 ? 0 : params[:buyTimes].to_i
    storeData['startTime'] = TimeHelper.parse_date_time(params[:startTime]).to_i
    storeData['endTime'] = TimeHelper.parse_date_time(params[:endTime]).to_i
    storeData['dayliBuy'] = params[:dayliBuy]

    res = RsRails.save_store_config(storeData)
    render :json => res
  end

  def deleteStore
    userInfo = curUserInfo()
    tid = params[:tid]
    res = RsRails.delete_store_config_by_tid(tid)
    if res['success']
      flash[:notice] = t(:delete_success, :name => "#{t(:store_slot)} #{tid}")
      redirect_to rewards_storelist_url
    else
      render :json => res
    end
  end

  def getStore
    tid = params[:tid]
    store = RsRails.get_store_config_by_tid(tid)
    if store
      store['startTime'] = TimeHelper.gen_date_time(Time.at(store['startTime']))
      store['endTime'] = TimeHelper.gen_date_time(Time.at(store['endTime']))
      render :json => store
    else
      render :json => {}
    end
  end

  def grantStore
    id = params[:tid]
    userInfo = curUserInfo()
    res = RsRails.grantStore(userInfo, id)
    if res['success']
      flash[:notice] = t(:operation_success)
    else
      flash[:notice] = t(:operation_failed)
    end
    redirect_to rewards_storelist_url
  end

  def rejectStore
    id = params[:tid]
    userInfo = curUserInfo()
    res = RsRails.rejectStore(userInfo, id)
    if res['success']
      flash[:notice] = t(:operation_success)
    else
      flash[:notice] = t(:operation_failed)
    end
    redirect_to rewards_storelist_url
  end

  def exportPackage
    logger.info ("exportPackage called")
    data = RsRails.get_package_config(params[:id])

    send_data Oj.dump(data), :filename => "#{data['name']}-#{data['tid']}.dat"

  end

  def importPackage

    if(params[:packagefile].nil?)
      redirect_to :action => 'packagelist', :errorMessage => t(:select_import_file)
    else
      raw = params[:packagefile].read
      loaded = Oj.load(raw)

      bExist, tid, name = checkPackageExists(loaded.clone)

      if bExist
        redirect_to :action => 'packagelist', :errorMessage => t(:package_exist) + ", ID = #{tid}, Name = #{name}"
      else
        RsRails.createPackage(loaded)
        redirect_to :action => 'packagelist', :successMessage => t(:import_package_success)
      end
    end
  end

  def checkPackageExists data
    bExist = false
    tid = nil
    name = ""
    data.tid = ""

    RsRails.get_package_configs.each do |v|
      tid = v.tid
      name = v.name
      v.delete('id')
      v.tid = ""
      if v == data then bExist = true; break; end
    end

    return bExist, tid, name
  end

  def exportStoreItem
    logger.info ("exportPackage called")
    storeItem = RsRails.get_store_config_by_tid(params[:tid])

    data = {}
    data['storeItem'] = storeItem

    if storeItem.itemId =~ /^IP.+/  # gm tool created package, save it, in case import
      package = RsRails.get_package_config_by_tid(storeItem.itemId)
      data['package'] = package
    else
      data['package'] = nil
    end

    send_data Oj.dump(data), :filename => "#{data['storeItem']['tid']}.dat"

  end

  def importStoreItem
    tid = nil
    if(params[:packagefile].nil?)
      redirect_to :action => 'storelist', :errorMessage => t(:select_import_file)
    else
      raw = params[:packagefile].read
      loaded = Oj.load(raw)

      bExist = false
      newStoreItem = loaded["storeItem"].clone
      newStoreItem.tid = ""
      newStoreItem.itemId = ""

      RsRails.get_store_configs.each do |v|
        tid = v.tid
        v.tid = ""
        if loaded["package"].nil? then
          v.itemId = ""
          if v == newStoreItem then bExist = true; break; end
        else
          storePackage = RsRails.get_package_config_by_tid(v.itemId)
          storePackage.tid = "" if not storePackage.nil?
          loadedPackage = loaded["package"].clone
          loadedPackage.tid = ""
          v.itemId = ""
          if v == newStoreItem and storePackage == loadedPackage then bExist = true; break; end
        end
      end

      if bExist
        redirect_to :action => 'storelist', :errorMessage => t(:store_exist) + ", ID = #{tid}"
      else
        # check if the package need to import
        if not loaded['package'].nil?
          bPackageExist, packageId = checkPackageExists(loaded["package"])

          if bPackageExist
            loaded["storeItem"]["itemId"] = packageId
          else
            result = RsRails.createPackage(loaded["package"])
            loaded["storeItem"]["itemId"] = result['tid']
          end
        end

        RsRails.createStore(loaded["storeItem"], curUserInfo())
        redirect_to :action => 'storelist', :successMessage => t(:import_store_success)
      end # store item not exist
    end # has package file
  end


end
