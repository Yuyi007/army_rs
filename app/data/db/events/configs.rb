module GameEvent
  class Package < ConfigBase
    attribute :tid
    attribute :name
    attribute :assetId
    attribute :subtype
    attribute :grade
    attribute :value, Type::Integer
    attribute :price, Type::Integer
    attribute :weight, Type::Integer
    attribute :detail
    attribute :desc
    attribute :drops, Type.array
    attribute :needKey, Type::Bool
    attribute :usable, Type::Bool

    unique :tid
    index :tid

    def self.tid_prefix
      'IPGM'
    end

    def self.on_post_from_hash(data)
      data.tid = "#{tid_prefix}#{data.id}"
    end
  end

  class Store < ConfigBase
    attribute :tid
    attribute :weight, Type::Integer
    attribute :itemId
    attribute :num, Type::Integer
    attribute :status, Type::Integer
    attribute :needChief, Type::Integer
    attribute :price, Type::Integer
    attribute :specialPrice, Type::Integer
    attribute :vipLevel, Type::Integer
    attribute :buyTimes, Type::Integer
    attribute :startTime, Type::Integer
    attribute :endTime, Type::Integer
    attribute :dayliBuy, Type::Bool
    unique :tid
    index :tid

    def self.tid_prefix
      'StoreGM'
    end

    def self.on_post_from_hash(data)
      data.tid = "#{tid_prefix}#{data.id}"
    end

    def opened?
      now = Time.now.to_i
      startTime <= now && endTime >= now
    end

    def self.get_all_open
      opened_list = []
      all.to_a.each do |data|
        opened_list << data if data.opened?
      end
      opened_list
    end
  end

  class Notice < ConfigBase
    attribute :title
    attribute :tid, Type::Integer
    attribute :content
    attribute :isNew, Type::Bool
    attribute :type, Type::Integer
    attribute :month, Type::Integer
    attribute :day, Type::Integer

    index :tid

    def self.get_all
      all.to_a.sort { |x, y| x.tid <=> y.tid }
    end
  end
end
