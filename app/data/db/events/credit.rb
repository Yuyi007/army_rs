# Credit.rb
# A more complicated credit event implementation sample for demostration

module GameEvent
  class Reward
    attr_accessor :times
    attr_accessor :credits
    attr_accessor :package_id
    attr_accessor :package

    include Jsonable
    gen_to_hash
    gen_from_hash

    def self.integer(*fields)
      fields.each do |field|
        class_eval %{
          def #{field}
            @#{field}.to_i
          end

          def #{field}=(value)
            @#{field} = value.to_i
          end
        }
      end
    end

    integer :credits, :times

    def initialize
      @package_id ||= ''
      @times ||= 1
      @credits ||= 0
    end

    def package
      @package = GameEventsDb.get_package_config_by_tid(package_id)
    end
  end

  class CreditRecord < Ohm::Model
    include Ohm::DataTypes
    include EventCommon
    include Loggable
    attribute :credits, Type::Integer
    attribute :time, Type::Integer
    attribute :total_times, Type.array
    attribute :redeemed_times, Type.array
    attribute :uid
    attribute :eid
    attribute :zone, Type::Integer
    attribute :ranking_redeemed, Type::Bool
    index :uid
    index :zone
    index :eid # event id

    def self.find_one(uid, eid, zone)
      collections = find(zone: zone, uid: uid, eid: eid)
      collections.first if collections.size > 0
    end

    def self.one(uid, eid, zone)
      d = find_one(uid, eid, zone)
      d ||= create(uid: uid, eid: eid, zone: zone)
    end

    def incr_total_times(index)
      total_times[index] ||= 0
      total_times[index] += 1
    end

    def set_total_times(index, value)
      d { "set_total_times #{index} #{value}" }
      total_times[index] = value
    end

    def get_total_times(index)
      total_times[index] ||= 0
    end

    def get_redeemed_times(index)
      redeemed_times[index] ||= 0
    end

    def can_redeem?(index)
      get_redeemed_times(index) < get_total_times(index)
    end

    def redeem(index)
      redeemed_times[index] ||= 0
      redeemed_times[index] += 1
    end
  end

  class Credit < EventBase
    include Ohm::Callbacks
    attribute :type
    attribute :ranking, Type::Bool
    attribute :close_time, Type::Integer
    attribute :rewards, Type.json_array(GameEvent::Reward)
    sorted_set :records, 'GameEvent::CreditRecord', :credits

    # The event is in show-only period, during which no records are updated
    def show_only?
      now = Time.now.to_i
      now >= end_time && now <= close_time
    end

    def opened?
      now = Time.now.to_i
      now <= close_time && now >= start_time
    end

    def self.max_size
      20
    end

    def self.valid_time?(data)
      return [false, :invalid_start_end_time] if data.start_time >= data.end_time
      return [false, :invalid_end_close_time] if data.end_time >= data.close_time
      true
    end

    def self.valid_data?(data)
      return [false, :error_no_rewards] if data.rewards.nil? || data.rewards.empty?
      data.rewards.each_with_index do |x, index|
        return [false, "error_credit_requirement credits=#{x.credits} @Reward#{index + 1}"] if x.credits.to_i <= 0
        return [false, "error_redeem_times times=#{x.times} @Reward#{index + 1}"] if x.times.to_i < 1
        no_package = x.package_id.nil? || x.package_id.empty? || GameEventsDb.get_package_config_by_tid(x.package_id).nil?
        return [false, "error_package_id package_id=#{x.package_id} @Reward#{index + 1}"] if no_package
      end

      data.rewards.each_with_index do |x, index|
        next_one = data.rewards[index + 1]
        if next_one
          return [false, 'error_credit_increment'] if x.credits.to_i > next_one.credits.to_i
        end
      end

      true
    end

    def chongzhi?
      type == 'single_credit' || type == 'total_credit'
    end

    def paid?
      type == 'total_paid'
    end

    def overlap?(other)
      return false if other.close_time < start_time
      return false if other.start_time > close_time
      true
    end

    # delete the records of the event as well
    def after_delete
      redis.del(rank_key)
    end

    def before_delete
      records.to_a.each(&:delete)
    end

    def update_record(uid, zone, credit)
      return unless opened?
      return if show_only?

      time = Time.now.to_i
      record = GameEvent::CreditRecord.one(uid, id, zone)

      case type.to_sym
      when :single_credit
        record.credits += credit.abs
        reward = rewards.reverse.find { |x| x && x.credits <= credit.abs } if rewards
        largest_index = rewards.index(reward) if reward
        if largest_index
          largest_index.downto(0) do |index|
            reward = rewards[index]
            next if reward.nil?
            record.redeemed_times[index] ||= 0
            record.total_times[index] ||= 0
            if reward.times > record.redeemed_times[index] && reward.times > record.total_times[index]
              record.incr_total_times(index)
              break
            end
          end
        end
      when :total_credit
        record.credits += credit.abs
        rewards.each_with_index do |x, index|
          record.set_total_times(index, 1) if x.credits <= record.credits
        end
      when :total_paid
        record.credits += credit.abs if credit < 0
        rewards.each_with_index do |x, index|
          record.set_total_times(index, 1) if x.credits <= record.credits
        end
      end
      record.time = time
      record.save
      records.add(record)
    end

    def find_record(uid, zone)
      collections = records.find(uid: uid, eid: id, zone: zone)
      collections.first if collections && collections.size > 0
    end

    def rank_key
      key[:rank]
    end

    def _compute_top_10
      a = records.revrange(0, 15)
      a.sort! { |x, y| [y.credits, x.time] <=> [x.credits, y.time] }.take(10).to_data
    end

    def get_top_10
      if !show_only?
        return _compute_top_10
      else
        raw = redis.get(rank_key)
        if raw
          JSON.parse(raw)
        else
          a = _compute_top_10
          return a if a.empty?
          lock(rank_key) do
            redis.set(rank_key, a.to_json)
          end
          a
        end
      end
    end
  end
end
