# group_mail_controller.rb

class GroupMailController < ApplicationController

  layout 'main'

  before_filter :require_user

  access_control do
    allow :admin, :p0
  end

  protect_from_forgery

  include RsRails
  include ConfigHelper

  def list
    @mails = []
    @ids = ''
    @ids2 = []
    # datas = GroupMailDb.get_all_gm_mails()
    datas = GroupMailDb.get_all_mails()

    # datas.sort!{|d1, d2|
    #   t1 = 0
    #   t2 = 0
    #   if d1['published'] == d2['published']
    #   else
    #     if d1['published'].nil? or d1['published'].to_i == 0
    #       t1 = 2
    #     else
    #       t1 = 1
    #     end

    #     if d2['published'].nil? or d2['published'].to_i == 0
    #        t2 = 2
    #     else
    #        t2 = 1
    #     end
    #   end
    #   t2 <=> t1
    # }

    datas.sort!{|a, b| b.id <=> a.id}

    datas.each_with_index do|data, index|
      if data
        @ids += "_" if index > 0
        @ids += data['id']
        @ids2 << data['id']
        data['start_time'] = TimeHelper.gen_date_time(Time.at(data['start_time']))
        data['end_time'] = TimeHelper.gen_date_time(Time.at(data['end_time']))
        @mails << data
      end
    end
  end

  def save
    group_mail = {}
    group_mail['id'] = params[:id]
    group_mail['start_time'] = TimeHelper.parse_date_time(params[:start_time]).to_i
    group_mail['end_time'] = TimeHelper.parse_date_time(params[:end_time]).to_i
    group_mail['min_lv'] = params[:min_lv]
    group_mail['max_lv'] = params[:max_lv]
    group_mail['need_activity'] = params[:need_activity]
    mail = {}
    mail['from_name'] = params[:senderName]
    #mail['kind'] = params[:kind]
    mail['reason'] = ''
    mail['content'] = {}
    mail['content']['text'] = params[:content_text]
    mail['content']['title_one'] = params[:title_one]
    mail['content']['title_two'] = params[:title_two]
    mail['content']['things'] = []

    mail['send_type'] = params[:send_type]
    mail['type'] = params[:type]
    mail['sub_type'] = params[:sub_type]

    for i in 1..5 do
      a = {}
      if params["hide_type#{i}"] and params["hide_type#{i}"] != "" and params["hide_param#{i}1"] and params["hide_param#{i}1"] != ""
        a['type'] = params["hide_type#{i}"]
        a['params1'] = params["hide_param#{i}1"]
        if params["hide_param#{i}2"] and params["hide_param#{i}2"] != ""
          a['params2'] = params["hide_param#{i}2"]
        else
          a['params2'] = 1
        end
        mail['content']['things'] << a
      end
    end

    zones = []
    if params[:zones] == 'all'
      zones = 'all'
    else
      temp_zones = params[:zones].split(',')

      temp_zones.each_with_index do|z, i|
        zones[i] = z.strip.to_i
      end
    end

    pids = {}
    if params[:pids] == 'all'
      pids = 'all'
    else
      temp_pids = params[:pids].split(',')

      temp_pids.each_with_index do|pid, i|
        pids[pid.strip.to_s] = true
      end
    end

    to_pid = []
    if params[:pids] == 'all'
      to_pid = 'all'
    else
      temp_to_pid = params[:pids].split(',')

      temp_to_pid.each_with_index do|pid, i|
        to_pid[i] = pid.strip.to_s
      end
    end

    group_mail['zones'] = zones
    group_mail['pids'] = pids
    group_mail['to_pid'] = to_pid
    group_mail['mail'] = mail
    GroupMailDb.update_mail(group_mail)

    render :json => { 'success' => true }
  end

  def get_mail
    id = params[:id]
    #data = GroupMailDb.get_gm_mail(id)
    data = GroupMailDb.get_mail(id)
    data['start_time'] = TimeHelper.gen_date_time(Time.at(data['start_time']))
    data['end_time'] = TimeHelper.gen_date_time(Time.at(data['end_time']))

    if data['mail'] && data['mail']['content'] && data['mail']['content']['things']
      data['mail']['content']['things'] = process_attachments(data['mail']['content']['things'])
    end

    if data['zones'].class.to_s == 'Array'
      data['zones'] = data['zones'].join(',')
    end
    if data['pids'].class.to_s == 'Hash'
      data['pids'] = data['pids'].keys.join(',')
    end

    if data
      render :json => data
    else
      render :json => {'success' => false}
    end
  end

  def edit
    @id = params[:id]
  end

  def new
  end

  def get_mails
    mails = {}
    mails['mails'] = []
    datas = GroupMailDb.get_all_gm_mails()

    datas.each do|data|
      if data
        data['start_time'] = TimeHelper.gen_date_time(Time.at(data['start_time']))
        data['end_time'] = TimeHelper.gen_date_time(Time.at(data['end_time']))
        mails['mails'] << data
      end
    end

    render :json => mails
  end

  def create
    group_mail = {}
    start_time = params[:start_time]
    end_time = params[:end_time]
    if (not start_time) or start_time == ""
      start_time = "01/01/1970 00:00"
    end

    if (not end_time) or end_time == ""
      end_time = "01/01/2020 00:00"
    end
    group_mail['start_time'] = TimeHelper.parse_date_time(start_time).to_i
    group_mail['end_time'] = TimeHelper.parse_date_time(end_time).to_i

    min_lv = params[:min_lv]
    max_lv = params[:max_lv]
    if (not min_lv) or min_lv == ""
      min_lv = 0
    end

    if (not max_lv) or max_lv == ""
      max_lv = 70
    end

    group_mail['min_lv'] = min_lv.to_i
    group_mail['max_lv'] = max_lv.to_i

    need_activity = params[:need_activity]
    if need_activity.nil? || need_activity == ""
      need_activity = 0
    end
    group_mail['need_activity'] = need_activity

    mail = {}
    mail['from_name'] = params[:senderName]
    # mail['kind'] = params[:kind]
    mail['send_type'] = params[:send_type]
    mail['type'] = params[:type]
    mail['sub_type'] = params[:sub_type]

    mail['content'] = {}
    mail['content']['text'] = params[:content_text]
    mail['content']['title_one'] = params[:title_one]
    mail['content']['title_two'] = params[:title_two]
    mail['content']['things'] = []
    for i in 1..5 do
      a = {}
      if params["hide_type#{i}"] and params["hide_type#{i}"] != "" and params["hide_param#{i}1"] and params["hide_param#{i}1"] != ""
        a['type'] = params["hide_type#{i}"]
        a['params1'] = params["hide_param#{i}1"]
        if params["hide_param#{i}2"] and params["hide_param#{i}2"] != ""
          a['params2'] = params["hide_param#{i}2"]
        else
          a['params2'] = 1
        end
        mail['content']['things'] << a
      end
    end

    zones = []
    if params[:zones] == 'all'
      zones = 'all'
    else
      temp_zones = params[:zones].split(',')

      temp_zones.each_with_index do|z, i|
        zones[i] = z.strip.to_i
      end
    end

    pids = {}
    if params[:pids] == 'all'
      pids = 'all'
    else
      tmp_pids = params[:pids].split(',')

      tmp_pids.each_with_index do|pid, i|
        pids[pid.strip.to_s] = true
      end
    end

    to_pid = []
    if params[:pids] == 'all'
      to_pid = 'all'
    else
      temp_to_pid = params[:pids].split(',')

      temp_to_pid.each_with_index do|pid, i|
        to_pid[i] = pid.strip.to_s
      end
    end

    group_mail['zones'] = zones
    group_mail['pids'] = pids
    group_mail['to_pid'] = to_pid
    group_mail['mail'] = mail
    GroupMailDb.add_mail(group_mail)

    render :json => { 'success' => true }
  end

  def delete
    id = params[:id]
    GroupMailDb.del_mail(id)
    render :json => { 'success' => true }
  end

  def publish
    id = params[:id]
    #data = GroupMailDb.get_gm_mail(id)
    data = GroupMailDb.get_mail(id)
    data['published'] = 1
    GroupMailDb.update_mail(data)
    render :json => { 'success' => true }
  end

private
  def process_attachments attachments
    return [] if attachments.nil?
    as = []
    attachments.each do |attach|
      a = {}
      attach.each do|key, value|
        a[key] = value
      end
      a['name'] = self.send("#{attach['type'][5..-1]}_display_name", a['params1'])
      as << a
    end
    return as
  end
end