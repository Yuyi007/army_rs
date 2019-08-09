# encoding: utf-8

class SiteUserRecord < ActiveRecord::Base

  attr_accessible :action, :success, :target, :zone, :tid, :count, :param1, :param2, :param3

  belongs_to :site_user

  self.per_page = 100

  def self.search(site_user_id, a, target, zone, tid,
    created_at_s, created_at_e, sort, direction, page, per_page)

    sort = (not sort.nil? or SiteUserRecord.column_names.include? sort) ? sort : 'created_at'
    direction = (direction.nil? or direction.downcase == 'desc') ? 'desc' : 'asc'
    page = 1 if page.to_i == 0
    per_page = self.per_page if per_page.to_i == 0

    queries = []
    fields = {}
    unless site_user_id.blank?
      queries << 'site_user_id = :site_user_id'
      fields[:site_user_id] = site_user_id
    end
    unless a.blank?
      queries << 'action = :action'
      fields[:action] = a
    end
    unless target.blank?
      queries << 'target = :target'
      fields[:target] = target
    end
    unless zone.blank?
      queries << 'zone = :zone'
      fields[:zone] = zone
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

    where(queries.join(' AND '), fields)
    .order("#{sort} #{direction}")
    .paginate(:page => page, :per_page => per_page)
  end

end
