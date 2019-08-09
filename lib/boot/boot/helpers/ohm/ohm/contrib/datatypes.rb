require 'bigdecimal'
require 'date'
require 'json'
require 'time'
require 'set'

module Ohm
  module DataTypes
    module Meaningful
      def to_s
        Helper.to_json(to_data)
      end
    end

    module Type
      Integer   = ->(x) { x.to_i }
      Decimal   = ->(x) { BigDecimal(x.to_s) }
      Float     = ->(x) { x.to_f }
      Symbol    = ->(x) { x && x.to_sym }
      Boolean   = ->(x) { !!x }
      Time      = ->(t) { t && (t.is_a?(::Time) ? t : ::Time.parse(t)) }
      Date      = ->(d) { d && (d.is_a?(::Date) ? d : ::Date.parse(d)) }
      Timestamp = ->(t) { t && UnixTime.at(t.to_i) }
      Hash      = ->(h) { h && SerializedHash[h.is_a?(::Hash) ? h : JSON(h)] }
      Array     = ->(a) { a && SerializedArray.new(a.is_a?(::Array) ? a : JSON(a)) }
      Set       = ->(s) { s && SerializedSet.new(s.is_a?(::Set) ? s : JSON(s)) }
      Bool      = ->(x) { x == 'true' || x == true || x.to_s == '1' }


      def self.parse_json(json)
        Helper.to_hash(json)
      end

      def self.hash
        lambda do |x|
          next {} if x.nil?
          if x.is_a?(::Hash)
            x.extend(Meaningful)
            x
          elsif x.is_a?(::String)
            a = parse_json(x)
            a.extend(Meaningful)
            a
          end
        end
      end

      def self.array
        lambda do |x|
          next [] if x.nil?
          if x.is_a?(::Array)
            x.extend(Meaningful)
            x
          elsif x.is_a?(::String)
            a = parse_json(x)
            a.extend(Meaningful)
            a
          end
        end
      end

      def self.json_array(clazz)
        fail "class #{clazz} must be a jsonable" unless clazz < Jsonable
        lambda do |x|
          next [] if x.nil?
          if x.is_a?(::Array)
            x.extend(Meaningful)
            a = x.map do |d|
              if d.is_a?(::Hash) then clazz.new.from_hash!(d) else d end
            end
            x.replace(a)
          elsif x.is_a?(::String)
            begin
              a = parse_json(x).map { |d| clazz.new.from_hash!(d) if d }
              a.extend(Meaningful)
              a
            rescue
              []
            end
          end
        end
      end

      def self.json_object(clazz)
        fail "class #{clazz} must be a jsonable" unless clazz < Jsonable
        lambda do |x|
          next x if x.nil?
          if x.is_a?(clazz)
            x
          elsif x.is_a?(::Hash)
            clazz.new.from_hash!(x)
          else
            clazz.new.from_json!(x)
          end
        end
      end


      def self.json_hash(clazz)
        fail "class #{clazz} must be a jsonable" unless clazz < Jsonable
        lambda do |x|
          next {} if x.nil?
          if x.is_a?(::Hash)
            x.extend(Meaningful)
            a = x.map do |k, d|
              if d.is_a?(::Hash)
                [k, clazz.new.from_hash!(d)]
              else
                [k, d]
              end
            end
            x.replace(::Hash[a])
          elsif x.is_a?(::String)
            begin
              h = ::Hash[parse_json(x).map { |k, d| if d then [k, clazz.new.from_hash!(d)] else [k, nil] end }]
              h.extend(Meaningful)
              h
            rescue
              {}
            end
          end
        end
      end
    end

    class UnixTime < Time
      def to_s
        to_i.to_s
      end
    end

    class SerializedHash < Hash
      def to_s
        JSON.dump(self)
      end
    end

    class SerializedArray < Array
      def to_s
        JSON.dump(self)
      end
    end

    class SerializedSet < ::Set
      def to_s
        JSON.dump(to_a.sort)
      end
    end
  end

end
