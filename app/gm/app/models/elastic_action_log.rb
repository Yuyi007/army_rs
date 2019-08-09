# The new action log using elasticsearch

class ElasticActionLog < ActiveRecord::Base

  include Elasticsearch::Model
  include Elasticsearch::Model::Callbacks

  self.per_page = 50

  def self.columns() @columns ||= []; end

  def self.column(name, sql_type = nil, default = nil, null = true)
    columns << ActiveRecord::ConnectionAdapters::Column.new(name.to_s, default, sql_type.to_s, null)
  end

  def self.sortable_columns
    [ 'player_id', 'zone', 'type', 'time', 'params' ]
  end

  def self.search_by(opts)
    player_id = opts[:player_id]
    zone = opts[:zone]
    type = opts[:type]
    time_s = TimeHelper.parse_date_time(opts[:time_s]).to_f
    time_e = TimeHelper.parse_date_time(opts[:time_e]).to_f
    params = opts[:parameters]
    sort = opts[:sort]
    direction = opts[:direction]
    page = opts[:page]
    per_page = opts[:per_page]

    sort = (not sort.nil? or ElasticActionLog.sortable_columns.include? sort) ? sort : 'time'
    direction = (direction.nil? or direction.downcase == 'desc') ? 'desc' : 'asc'
    page = 1 if page.to_i == 0
    per_page = self.per_page if per_page.to_i == 0
    time_s = (Time.now - 3600 * 1).to_f if time_s <= 0
    time_e = Time.now.to_f if time_e <= 0

    phrases = []
    phrases << { 'term' => { 'player_id' => player_id.downcase } } unless player_id.blank?
    phrases << { 'term' => { 'zone' => zone.to_i } } unless zone.blank?
    phrases << { 'prefix' => { 'type' => type.downcase } } unless type.blank?
    phrases << { 'prefix' => { 'params' => params.downcase } } unless params.blank?
    phrases << { 'range' => { 'time' => { 'gte' => time_s.to_s, 'lte' => time_e.to_s } } }

    query = {
      'query' => {
        'filtered' => {
          'query' => {
            'match_all' => {}
          },
          'filter' => {
            'bool' =>  {
              'must' => phrases
            }
          }
        }
      },
      'sort' => [
        {
          "#{sort}" => {
            "mode" => "min",
            "order" => "#{direction}"
          }
        }
      ]
    }

    res = search(query, index: 'rs-actionlog-*', type: '')
      .paginate(:page => page, :per_page => per_page)
  end

end
