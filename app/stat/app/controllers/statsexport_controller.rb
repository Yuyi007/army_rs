require_relative 'stats_req'
class StatsexportController < ApplicationController
  @@export_data = {}


  def save_export_data
    uid = check_session
    return ng('verify fail') if uid.nil?
    str_data = params[:str_data]
    str_header = params[:str_header]
    return ng('invalid args') if str_data.nil? || str_header.nil?

    obj_header = JSON.parse(str_header)
    obj_data = JSON.parse(str_data)
    return ng('invalid json') if obj_data.nil? || obj_header.nil?

    @@export_data[uid.to_s] = {:header => obj_header, :data => obj_data}
    sendok
  end

  def export_to_xls
    uid = params[:uid]
    @file_name = params[:file_name]

    return ng('invalid args') if uid.nil? || @file_name.nil?
    tmp = @@export_data[uid.to_s]
    @header = tmp[:header]
    @data = tmp[:data]
    
    @@export_data.delete(uid)

    respond_to do |format|
      format.html
      format.xls
    end
  end
end