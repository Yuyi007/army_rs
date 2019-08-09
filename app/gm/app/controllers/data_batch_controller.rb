# data_batch_controller.rb
require_relative 'batch_add_module'

class DataBatchController < ApplicationController

  include ApplicationHelper

  layout 'main'

  protect_from_forgery

  before_filter :require_user

  access_control do
    allow :admin, :p0, :p1, :p2, :p3
    # allow :p0, :to => [ :edit, :batch_save ]
    # allow :p1, :to => [ :edit, :batch_save ]
    # allow :p2, :p3, :to => [ :edit, :batch_save ]

  end

  include RsRails

  def edit
  end

  def batch_save
    fail_ids = []

    ids = split_str params[:ids]
    zone = params[:zone]
    temp = params[:records]
    records = []
    temp.each do |i, v|
      records << v
    end
    reason = params[:reason]
    # puts ">>>>ids:#{ids} zone:#{zone} records:#{records}"

    if ids.length <= 0
      flash[:error] = t(:id_list_empty)
    else
      if current_user.role_name == 'admin'
        do_batch_edit(zone, ids, records, fail_ids)
      else
        counts = records.map{|rc| rc['count'].to_s}.join(',')
        categories = records.map{|rc| rc['category'].to_s}.join(',')
        tids = records.map{|rc| rc['tid'].to_s}.join(',')
        names = records.map{|rc| rc['name'].to_s}.join(',')

        success = current_user.grant_records.create(
          :action => categories,
          :success => true,
          :target_id => ids.join(','),
          :target_zone => zone.to_i,
          :item_id => tids,
          :item_amount => counts,
          :item_name => names,
          :reason => reason,
          :status => 'new'
        )
        fail_ids << id unless success
      end

      if fail_ids.length == 0
        flash[:notice] = t(:success)
       else
        flash[:error] = t(:save_num) + "#{ids.length}" + ' ' + t(:save_fail_list) + ': ' + fail_ids.join(', ')
      end
    end
    render :edit
  end

private
  include ModuleBatchAdd
end
