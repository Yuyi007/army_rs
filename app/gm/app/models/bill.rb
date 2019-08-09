class Bill < ActiveRecord::Base
  attr_accessible :sdk, :platform, :goodsId, :count, :playerId, :transId, :zone, :price, :status, :detail, :pid, :market

  self.per_page = 10

  include ApplicationHelper

  def self.search(sdk, platform, playerId, zone, goodsId, transId,
    created_at_s, created_at_e, sort, direction, page, per_page)

    sort = (not sort.nil? or Bill.column_names.include? sort) ? sort : 'created_at'
    direction = (direction.nil? or direction.downcase == 'desc') ? 'desc' : 'asc'
    page = 1 if page.to_i == 0
    per_page = self.per_page if per_page.to_i == 0

    queries = []
    fields = {}
    unless sdk.blank?
      queries << 'sdk = :sdk'
      fields[:sdk] = sdk
    end
    unless platform.blank?
      queries << 'platform = :platform'
      fields[:platform] = platform
    end
    unless playerId.blank?
      queries << 'playerId = :playerId'
      fields[:playerId] = playerId
    end
    unless zone.blank?
      queries << 'zone = :zone'
      fields[:zone] = zone
    end
    unless goodsId.blank?
      queries << 'goodsId = :goodsId'
      fields[:goodsId] = goodsId
    end
    unless transId.blank?
      queries << 'transId = :transId'
      fields[:transId] = transId
    end
    unless created_at_s.blank?
      queries << 'created_at >= :created_at_s'
      fields[:created_at_s] = TimeHelper.parse_date_time(created_at_s)
    end
    unless created_at_e.blank?
      queries << 'created_at <= :created_at_e'
      fields[:created_at_e] = TimeHelper.parse_date_time(created_at_e)
    end

    where(queries.join(' AND '), fields)
    .order("#{sort} #{direction}")
    .paginate(:page => page, :per_page => per_page)
  end

  def self.empty_ret
     where('transId is null')
    .paginate(:page => 1, :per_page => 1)
  end
end
