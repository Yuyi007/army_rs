# HashStorable.rb

module Boot

  # The meta fields for a hash storable
  module HashStorableMeta

    # a special field that stores whatever not defined as hash_field
    DEFAULT_FIELD = 'model'

    # the field stores version of the hash storable
    # the version should be manually updated from outside this module
    VERSION_FIELD = 'version'

    attr_accessor :version

    # init the hash storable
    # @param fields [Array] an array of fields corresponding to preload_fields, or
    #               [Object] the value of HashStorableMeta::DEFAULT_FIELD
    # @param read_field [Proc] A proc for reading a particular hash field of the model
    # @return [HashStorableMeta] self
    def init_hash_storable! fields, &read_field
      if fields.is_a? Array
        value, @version = fields[0], fields[1].to_i
      else
        value, @version = fields, 0
      end
      if value.respond_to? :unpack
        self.load! value
      elsif value.respond_to? :each
        self.from_hash! value
      else
        raise "HashStorableMeta: invalid field #{HashStorableMeta::DEFAULT_FIELD}: #{value.inspect}"
      end

      @_read_field = read_field

      self
    end

    # return the fields that should be preloaded
    # @return [Array] the field names
    def self.preload_fields
      [ HashStorableMeta::DEFAULT_FIELD, HashStorableMeta::VERSION_FIELD ]
    end

    # whether the field name is reserved for meta use
    # @return [Bool] true if the field name is reserved
    def self.field_reserved? field
      ( field == HashStorableMeta::DEFAULT_FIELD || field == HashStorableMeta::VERSION_FIELD )
    end

  end

  # Hash storable allows Jsonable to store fields in redis hash
  module HashStorable

    def self.included(base)
      raise "a HashStorable must be a Jsonable first" if base.ancestors.select { |o| o == Jsonable }.length == 0

      base.extend ClassMethods
      base.class_variable_set(:@@hash_loads, {})
      base.class_variable_set(:@@hash_saves, {})
      base.class_variable_set(:@@hash_types, {})
    end

    module ClassMethods

      def hash_field field
        hash_load field
        hash_save field
      end

      def hash_load field
        raise "HashStorable: cannot hash_load #{field} because the name is reserved" if HashStorableMeta.field_reserved? field

        class_eval("@@hash_loads['#{field.to_s}'] = true")
        class_eval("@@hash_types['#{field.to_s}'] = json_get_type('#{field.to_s}')")

        attr_writer field

        class_eval(%Q{
        def #{field}
          hash_types = self.class.class_variable_get(:@@hash_types)
          if @#{field} == nil or @#{field} == hash_types['#{field}'][:default]
            if not defined? @_#{field}_loaded
              value = load_field('#{field}')
              @#{field} = value if value
              @_#{field}_loaded = true
            end
          end
          @#{field}
        end

        def #{field}_loaded?
          defined? @_#{field}_loaded
        end
        })
      end

      def hash_save field
        raise "HashStorable: cannot hash_save #{field} because the name is reserved" if HashStorableMeta.field_reserved? field

        class_eval("@@hash_saves['#{field.to_s}'] = true")
        class_eval("@@hash_types['#{field.to_s}'] = json_get_type('#{field.to_s}')")
      end

    end

    ####

    include HashStorableMeta

    # breakdown the hash storable and dump each hash fields
    # @return [Array] An array suitable for calling hmset with
    def breakdown_dump
      res = []
      hash_saves = self.class.class_variable_get(:@@hash_saves)
      hash_types = self.class.class_variable_get(:@@hash_types)
      hash_saves.each do |field, _|
        value = instance_variable_get "@#{field}"
        if value != nil and value != hash_types[field][:default]
          type = hash_types[field][:type]
          clazz = hash_types[field][:class]
          if clazz
            case type
            when 'hash'
              h = {}
              value.each { |k, v| h[k] = v.to_hash }
            when 'array'
              h = value.map { |v| v.to_hash }
            when 'object'
              h = value.to_hash
            else
              raise "HashStorable: trying to breakdown #{field} with class but type is #{type}"
            end
            res << "#{field}" << Jsonable.dump_hash(h)
          else
            res << "#{field}" << Jsonable.dump_hash(value)
          end
        else
          # ignore if no value, or not loaded
        end
      end
      ignored = hash_saves.merge({ HashStorableMeta::VERSION_FIELD => true })
      res << HashStorableMeta::DEFAULT_FIELD << self.dump(:ignored => ignored)
      res << HashStorableMeta::VERSION_FIELD << self.version
    end

  private

    def load_field field
      cur = instance_variable_get "@#{field}"
      # puts "load_field #{field} #{cur}"
      # raise "tt" if field == 'equips'
      hash_loads = self.class.class_variable_get(:@@hash_loads)
      hash_types = self.class.class_variable_get(:@@hash_types)
      raise "HashStorable: load_field called on #{field} but the field is not defined" if not hash_loads[field]

      raw = @_read_field.call(field, cur)
      if raw.respond_to? :bytesize
        data = Jsonable.load_hash(raw)
        type = hash_types[field][:type]
        clazz = hash_types[field][:class]
        if clazz
          case type
          when 'hash'
            value = {}
            #puts ">>>>>field:#{field} clazz:#{clazz.class.classname}"
            data.each { |k, v| value[k] = clazz.new.from_hash!(v).set_owner(self) }
            value
          when 'array'
            data.map { |v| clazz.new.from_hash!(v).set_owner(self) }
          when 'object'
            clazz.new.from_hash!(data).set_owner(self)
          else
            raise "HashStorable: trying to load_field #{field} with class but type is #{type}"
          end
        else
          data
        end
      elsif raw
        raw
      else
        # We can't simply throw error here: it can and should return nil on hash_load
        # previously saved hash fields
        # raise "HashStorable: trying to load_field #{field} but data is nil"

        # But keep in mind errorly returning nil is dangerous:
        # Model may initialize the field again with an initial value
        nil
      end
    end

  end

end