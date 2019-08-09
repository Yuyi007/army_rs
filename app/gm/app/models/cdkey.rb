require 'csv'


class Cdkey < ActiveRecord::Base
  attr_accessible :key, :tid, :player_id, :zone, :created_at, :redeemed
  attr_accessible :bonus_id, :bonus_count, :end_time, :sdk

  self.per_page = 10

  include ApplicationHelper

  def self.search(params)
    player_id = params[:player_id]
    zone = params[:zone]
    key = params[:key]
    tid = params[:tid]
    created_at_s = params[:created_at_s]
    created_at_e = params[:created_at_e]
    redeemed = params[:redeemed]
    sdk = params[:sdk]

    sort = (not sort.nil? or Bill.column_names.include? sort) ? sort : 'created_at'
    direction = (direction.nil? or direction.downcase == 'desc') ? 'desc' : 'asc'
    page = 1 if page.to_i == 0
    per_page = self.per_page if per_page.to_i == 0

    queries = []
    fields = {}
    unless player_id.blank?
      queries << 'player_id = :player_id'
      fields[:player_id] = player_id
    end

    unless sdk.blank?
      queries << 'sdk = :sdk'
      fields[:sdk] = sdk
    end

    unless zone.blank?
      queries << 'zone = :zone'
      fields[:zone] = zone
    end

    unless key.blank?
      queries << "`key` = :key"
      fields[:key] = key
    end

    unless tid.blank?
      queries << 'tid = :tid'
      fields[:tid] = tid
    end

    unless created_at_s.blank?
      queries << 'created_at >= :created_at_s'
      fields[:created_at_s] = TimeHelper.parse_date_time(created_at_s)
    end

    unless created_at_e.blank?
      queries << 'created_at <= :created_at_e'
      fields[:created_at_e] = TimeHelper.parse_date_time(created_at_e)
    end

    if redeemed
      queries << 'redeemed = :redeemed'
      fields[:redeemed] = true
    end

    where(queries.join(' AND '), fields)
    .order("#{sort} #{direction}")
    .paginate(:page => page, :per_page => per_page)
  end

  def self.process_redeemed_cdkeys
    total = 0

    while true do
      data = CdkeyDb.redeemed_list.rpop
      break unless data
      data = MessagePack.unpack(data)
      cdkey = Cdkey.where(:key => data[3]).first || Cdkey.create(:key => data[3], :tid => data[4], :created_at => Time.now)
      cdkey.sdk = data[0]
      cdkey.player_id = data[1]
      cdkey.zone = data[2]
      cdkey.tid = data[4]
      cdkey.created_at = Time.at(data[5])
      cdkey.redeemed = true
      cdkey.save
      total += 1
    end

    total
  end

  def self.generate(sdks, tid, num, end_time, bonus_id, is_repeatable, is_special)
    repeat_num = 1
    if is_special
      keys = CdkeyDb.generate_new(sdks, 1, tid, num, end_time, bonus_id)
      real_num = num
    elsif is_repeatable
      keys = CdkeyDb.generate(sdks, 100, tid, num, end_time, bonus_id)
      real_num = 1
      repeat_num = 100
    else
      keys = CdkeyDb.generate(sdks, 1, tid, num, end_time, bonus_id)
      real_num = 1
    end

    cdkeys = keys.each_slice(2).map {|key, key_tid|
      sdk = key_tid.split(",")[0]
                Cdkey.new(:key => key,
                          :tid => tid,
                          :player_id => 'none',
                          :created_at => Time.now,
                          :bonus_id => bonus_id,
                          :bonus_count => real_num,
                          :end_time => Time.at(end_time),
                          :sdk => sdk,
                          )
            }
    if ActiveRecord::Base.connection.instance_values["config"][:adapter] == "mysql2"
      max_pack = 5000
    else
      max_pack = 1
    end

    cdkeys.each_slice(max_pack) do |keys|
      Cdkey.import(keys)
    end
    keys.each_slice(2).map{|key, data|
      sdk = data.split(",")[0]
      "#{key}\t#{sdk},#{repeat_num},#{tid},#{end_time},#{bonus_id},#{real_num}"
    }
  end

  def self.import_from_local(logger)
    file_list = Dir.glob("#{Rails.root}/../../cdkeys/data/*.json")
    logger.info "check file list: #{file_list}"
    if ActiveRecord::Base.connection.instance_values["config"][:adapter] == "mysql2"
      max_pack = 5000
    else
      max_pack = 1
    end
    file_list.each do |file_path|
      logger.info "check all cdkeys: #{file_path}"
      ac_cdkeys = []
      IO.foreach(file_path) do |block|
        logger.info "block is: #{block}"
        block_details = block.split(":")
        next if block_details.size != 2
        one_key = block_details[0].strip.gsub("\"", "")
        data = block_details[1].strip.gsub("\"", "")
        logger.info "block detail: #{one_key}:=>#{data}"
        CdkeyDb.add_new(one_key, data)
        if !Cdkey.exists?(:key => one_key)
          details = data.split(",")
          ac_cdkeys << Cdkey.new(:key => one_key,
                            :sdk => details[0].to_s,
                            :tid => details[2].to_s,
                            :player_id => 'none',
                            :created_at => Time.now,
                            :bonus_id => details[4].to_s,
                            :bonus_count => details[5].to_i,
                            :end_time => details[3].to_i
                            )
        end

      end
      ac_cdkeys.each_slice(max_pack) do |keys|
        Cdkey.import(keys)
      end
    end

  end

  def self.import_from_file(file, logger)
    ac_cdkeys = []
    # CdkeyDb.redis.del("newcdkeys") #.delete_all()
    # Cdkey.delete_all
    CSV.foreach(file.path, headers: false) do |row|
      key_sdk = row[0].split("\t")
      # logger.info "test1: #{row[0]}:#{row[1]}:#{row[2]}:#{row[3]}:#{row[4]}:#{row[5]}"
      one_key = key_sdk[0]
      data = "#{key_sdk[1]},#{row[1]},#{row[2]},#{row[3]},#{row[4]},#{row[5]}"
      CdkeyDb.add_new(one_key, data)
      # logger.info "check all cdkeys2:#{data}, #{CdkeyDb.get_detail(one_key)}"
      if !Cdkey.exists?(:key => one_key)
        ac_cdkeys << Cdkey.new(:key => one_key,
                          :sdk => key_sdk[1],
                          :tid => row[2],
                          :player_id => 'none',
                          :created_at => Time.now,
                          :bonus_id => row[4].to_s,
                          :bonus_count => row[5].to_i,
                          :end_time => row[3].to_i
                          )
      end
    end

    if ActiveRecord::Base.connection.instance_values["config"][:adapter] == "mysql2"
      max_pack = 5000
    else
      max_pack = 1
    end

    ac_cdkeys.each_slice(max_pack) do |keys|
      Cdkey.import(keys)
    end
  end
end
