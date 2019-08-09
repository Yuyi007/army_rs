# Jsonable.rb

require 'oj'
require 'msgpack'
require 'zlib'
require 'lz4-ruby'

module Boot

  module Jsonable

    # Legacy hash convert methods - by code generation
    module HashConvertGen

      def gen_from_hash
        objects = class_eval("@@objects")
        hashes = class_eval("@@hashes")
        arrays = class_eval("@@arrays")
        dynamic_objects = class_eval("@@dynamic_objects")
        dynamic_hashes = class_eval("@@dynamic_hashes")
        dynamic_arrays = class_eval("@@dynamic_arrays")
        object_assigners = []
        dynamic_objects_assigner = []
        dynamic_objects_tester = []
        hash_assigners = []
        dynamic_hashes_assigner = []
        dynamic_hashes_tester = []
        array_assigners = []
        dynamic_arrays_assigner = []
        dynamic_arrays_tester = []
        plain_assigners = []
        instance_methods.each do |sym|
          name = sym.to_s
          if name.match(/^[a-z]/) and
            instance_methods.include? (name + '=').to_sym and
            if objects[name]
              object_assigners << "@#{name}=#{objects[name]}.new.from_hash!(hash['#{name}']).set_owner(self) if hash['#{name}'] != nil"
            elsif hashes[name]
              hash_assigners << "@#{name}={}; hash['#{name}'].each { |k,v| @#{name}[k] = #{hashes[name]}.new.from_hash!(v).set_owner(self) } if hash['#{name}'] != nil"
            elsif arrays[name]
              array_assigners << "@#{name}=[]; hash['#{name}'].each { |v| @#{name} << if v then #{arrays[name]}.new.from_hash!(v).set_owner(self) else nil end } if hash['#{name}'] != nil"
            elsif dynamic_objects[name]
              dynamic_objects_assigner << %Q{
                if not hash['#{name}'].nil? then
                  cls = __test_type_#{name}(hash['#{name}']);
                  @#{name} = cls.new.from_hash!(hash['#{name}']).set_owner(self) if not cls.nil?
                end}
              dynamic_objects_tester << "def __test_type_#{name}(hash); raise 'U must implement __test_type_#{name}(hash)'; end"
            elsif dynamic_hashes[name]
              dynamic_hashes_assigner << %Q{
                @#{name}={}
                hash['#{name}'].each { |k,v|
                    if not v.nil? then
                      cls = __test_type_#{name}(v);
                      @#{name}[k] = cls.new.from_hash!(v).set_owner(self) if not cls.nil?
                    end
                  } if not hash['#{name}'].nil?}
              dynamic_hashes_tester << "def __test_type_#{name}(hash); raise 'U must implement __test_type_#{name}(hash)'; end"
            elsif dynamic_arrays[name]
              dynamic_arrays_assigner << %Q{
                @#{name}=[]
                hash['#{name}'].each { |v|
                  o = nil
                  if not v.nil? then
                    cls = __test_type_#{name}(v);
                    o = cls.new.from_hash!(v).set_owner(self) if not cls.nil?
                  end
                  @#{name} << o
                } if not hash['#{name}'].nil?}
                dynamic_arrays_tester << "def __test_type_#{name}(hash); raise 'U must implement __test_type_#{name}(hash)'; end"
            else
              plain_assigners << "@#{name}=hash['#{name}'] if hash['#{name}'] != nil;"
            end
          end

        end
        m = %[
          #{dynamic_objects_tester.join("\r\n\t")}
          #{dynamic_hashes_tester.join("\r\n\t")}
          #{dynamic_arrays_tester.join("\r\n\t")}

          def from_hash! hash
            #{object_assigners.join("\r\n\t")}
            #{hash_assigners.join("\r\n\t")}
            #{array_assigners.join("\r\n\t")}
            #{plain_assigners.join("\r\n\t")}
            #{dynamic_objects_assigner.join("\r\n\t")}
            #{dynamic_hashes_assigner.join("\r\n\t")}
            #{dynamic_arrays_assigner.join("\r\n\t")}
            self
          end
        ]
        class_eval m
      end

      def gen_to_hash
        objects = class_eval("@@objects")
        hashes = class_eval("@@hashes")
        arrays = class_eval("@@arrays")
        dynamic_objects = class_eval("@@dynamic_objects")
        dynamic_hashes = class_eval("@@dynamic_hashes")
        dynamic_arrays = class_eval("@@dynamic_arrays")
        object_assigners = []
        hash_assigners = []
        array_assigners = []
        plain_assigners = []
        instance_methods.each do |sym|
          name = sym.to_s
          if name.match(/^[a-z]/) and instance_methods.include? (name + '=').to_sym
            if objects[name] or dynamic_objects[name]
              object_assigners << "if not ignored['#{name}'] then hash['#{name}']=self.#{name}.to_hash if self.#{name} != nil; end"
            elsif hashes[name] or dynamic_hashes[name]
              hash_assigners << "if not ignored['#{name}'] then hash['#{name}']={}; self.#{name}.each { |k,v| hash['#{name}'][k] = v.to_hash  } if self.#{name} != nil; end"
            elsif arrays[name] or dynamic_arrays[name]
              array_assigners << "if not ignored['#{name}'] then hash['#{name}']=[]; self.#{name}.each { |v| hash['#{name}'] << if v then v.to_hash else nil end } if self.#{name} != nil; end"
            else
              plain_assigners << "if not ignored['#{name}'] then hash['#{name}']=self.#{name} if self.#{name} != nil; end"
            end
          end
        end
        m = %[
          def to_hash options = {}
            ignored = options[:ignored] || {}
            hash = {}
            #{object_assigners.join("\r\n\t")}
            #{hash_assigners.join("\r\n\t")}
            #{array_assigners.join("\r\n\t")}
            #{plain_assigners.join("\r\n\t")}
            hash
          end
        ]
        class_eval m
      end

    end

    # Legacy hash convert methods
    module HashConvert

      def to_hash options = {}
        ignored = options[:ignored] || {}
        hash = {}
        objects = self.class.class_variable_get(:@@objects)
        hashes = self.class.class_variable_get(:@@hashes)
        arrays = self.class.class_variable_get(:@@arrays)
        dynamic_objects = self.class.class_variable_get(:@@dynamic_objects)
        dynamic_hashes = self.class.class_variable_get(:@@dynamic_hashes)
        dynamic_arrays = self.class.class_variable_get(:@@dynamic_arrays)
        # only the variables which have getters and setters are supposed to be stored in the database
        self.instance_variables.each do |var|
          # puts "instance_variables #{var}"
          name = var.to_s[1..-1]
          next unless self.respond_to?(name) && self.respond_to?(name+'=')
          next if ignored[name]
          if objects[name] != nil or dynamic_objects[name] != nil
            hash[name] = self.send(name).to_hash
          elsif hashes[name] != nil or dynamic_hashes[name] != nil
            hash[name] = {}
            h = self.send(name)
            h.each { |k, v| hash[name][k] = v.to_hash }
          elsif arrays[name] != nil or dynamic_arrays[name] != nil
            hash[name] = []
            a = self.send(name)
            a.each { |v| hash[name] << if v then v.to_hash else nil end }
          else
            hash[name] = self.send(name)
          end
        end
        hash
      end

      def from_hash! hash
        objects = self.class.class_variable_get(:@@objects)
        hashes = self.class.class_variable_get(:@@hashes)
        arrays = self.class.class_variable_get(:@@arrays)
        dynamic_objects = self.class.class_variable_get(:@@dynamic_objects)
        dynamic_hashes = self.class.class_variable_get(:@@dynamic_hashes)
        dynamic_arrays = self.class.class_variable_get(:@@dynamic_arrays)
        hash.each do |name, val|
          sym = "@#{name}"
          setter = "#{name}=".to_sym
          # puts "$$$ #{name}|#{objects[name]}|#{hashes[name]}|#{arrays[name]}"
          if objects[name] != nil
            self.instance_call_setter setter,
              Object.const_get(objects[name]).new.from_hash!(val).set_owner(self)
          elsif hashes[name] != nil
            h = {}
            val.each do |k, v|
              if v then
                h[k] = Object.const_get(hashes[name]).new.from_hash!(v).set_owner(self)
              end
            end
            self.instance_call_setter setter, h
          elsif arrays[name] != nil
            a = []
            if val then
              val.each do |e|
                a << if e then Object.const_get(arrays[name]).new.from_hash!(e).set_owner(self) else nil end
              end
            end
            self.instance_call_setter setter, a
          elsif dynamic_objects[name] != nil
            cls = self.send "__test_type_#{name}", val
            self.instance_call_setter setter,
              cls.new.from_hash!(val).set_owner(self)
          elsif dynamic_hashes[name] != nil
            h = {}
            val.each do |k, v|
              if v then
                cls = self.send "__test_type_#{name}", v
                h[k] = cls.new.from_hash!(v).set_owner(self)
              end
            end
            self.instance_call_setter setter, h
          elsif dynamic_arrays[name] != nil
            a = []
            if val then
              val.each do |v|
                o = nil
                cls = self.send "__test_type_#{name}", v
                o = cls.new.from_hash!(v).set_owner(self) if not v.nil?
                a << o
              end
            end
            self.instance_call_setter setter, a
          else
            self.instance_call_setter setter, val
          end
        end
        self
      end

    end

    include HashConvert

    def self.included(base)
      base.extend ClassMethods
      base.class_variable_set(:@@objects, {})
      base.class_variable_set(:@@hashes, {})
      base.class_variable_set(:@@arrays, {})
      base.class_variable_set(:@@dynamic_objects, {})
      base.class_variable_set(:@@dynamic_hashes, {})
      base.class_variable_set(:@@dynamic_arrays, {})
    end

    module ClassMethods
      include HashConvertGen

      def json_object field, cls
        class_eval("@@objects['#{field.to_s}'] = '#{cls.to_s}'")

        # automatically set owner, when the object assignment is done through setter
        # For exmaple: model.zhuwei ||= Zhuwei.new; model.zhuwei.__owner__ == model;
        class_eval(%Q{
          def #{field}= value
            @#{field} = value
            @#{field}.set_owner(self) if @#{field}.respond_to?(:set_owner)
          end
        })
      end

      def json_hash field, cls
        class_eval("@@hashes['#{field.to_s}'] = '#{cls.to_s}'")
      end

      def json_array field, cls
        class_eval("@@arrays['#{field.to_s}'] = '#{cls.to_s}'")
      end

      def json_dynamic_object field, base_cls
        class_eval("@@dynamic_objects['#{field.to_s}'] = '#{base_cls.to_s}'")

        class_eval(%Q{
          def #{field}= value
            @#{field} = value
            @#{field}.set_owner(self) if @#{field}.respond_to?(:set_owner)
          end
          })
      end

      def json_dynamic_hash field, base_cls
        class_eval("@@dynamic_hashes['#{field.to_s}'] = '#{base_cls.to_s}'")
      end

      def json_dynamic_array field, base_cls
        class_eval("@@dynamic_arrays['#{field.to_s}'] = '#{base_cls.to_s}'")
      end

      def json_get_type field
        cls = class_eval("@@hashes['#{field.to_s}']")
        cls = class_eval("@@dynamic_objects['#{field.to_s}']") if not cls
        return { :type => 'hash', :class => Object.const_get(cls), :default => {} } if cls

        cls = class_eval("@@arrays['#{field.to_s}']")
        cls = class_eval("@@dynamic_arrays['#{field.to_s}']") if not cls
        return { :type => 'array', :class => Object.const_get(cls), :default => [] } if cls

        cls = class_eval("@@objects['#{field.to_s}']")
        cls = class_eval("@@dynamic_objects['#{field.to_s}']") if not cls
        return { :type => 'object', :class => Object.const_get(cls), :default => nil } if cls

        return { :type => nil, :class => nil, :default => nil }
      end
    end

    def to_json
      Helper.to_json(to_hash)
    end

    def to_data
      to_hash
    end

    def to_s
      to_json
    end

    def to_msgpack(io = nil)
      to_hash.to_msgpack(io)
    end

    def instance_call_setter(sym, value)
      # puts 'setter ' + setter
      if self.respond_to? sym
        # we should only set the attributes if the variable is being monitored by the model's accessors
        # puts 'respond to ' + setter.to_s + " value " + value.to_s
        self.method(sym).call(value)
      else
        # self.instance_variable_set sym, value
      end
    end

    # An owner is used to store the *owner* reference.
    # The owner is assigned when the *member* object is created during deserialization
    # This is to accomplish, for example, accessing model from within record/chief,
    # with self.__owner__, without having to pass model as a parameter.
    # Attributs starts with __ are ignored by to_hash/from_hash,
    # so we are still sane with our data.
    # And since ruby uses mark & sweep for GC, cyclic refrences would have no side effects
    #
    # no need to: model.record.update_record(model)
    # just  model.record.update_record, and use the __owner__ refrenced inside
    # - evepoe
    def __owner__= owner
      @__owner = owner
    end

    def __owner__
      defined?(@__owner) ? @__owner : nil
    end

    # Manually set the owner
    # When the object is created by code rather than deserialization
    # example: Skill.new.set_owner(model)
    def set_owner(owner)
      self.__owner__ = owner if owner
      self
    end

    def from_json! json_string
      o = Helper.to_hash(json_string)
      if o.nil?
        nil
      else
        from_hash!(o)
      end
    end

    def load! raw
      from_hash! Jsonable.load_hash(raw)
    end

    def dump options = {}
      Jsonable.dump_hash to_hash(options)
    end

    # Define the 2 interfaces used in Marshal.dump/load (used in Helper.deppCopy)
    # marshal_dump and marshal_load
    # so __owner__ is ignored during marshaling
    # as it can be quite large
    def marshal_dump
      dump
    end

    def marshal_load raw
      load! raw
    end

    # this has to be compatible with both json and msgpack
    def self.load_hash raw
      return Oj.load raw if raw.bytesize < 3

      tag, buf = raw.unpack('a2a*')
      case tag
      when "\x00\x01"
        MessagePack.unpack(buf)
      when "\x00\x02"
        MessagePack.unpack(Zlib::Inflate.inflate buf)
      when "\x00\x03"
        MessagePack.unpack(LZ4::uncompress buf)
      when "\x00\x04"
        MessagePack.unpack(LZ4::Fixed.uncompress buf)
      else
        Oj.load raw
      end
    end

    def self.dump_hash hash
      pack = MessagePack.pack(hash)

      # if hash.is_a? Hash
      #   l = pack.length
      #   puts "total=#{l}"
      #   hash.each { |k, v| l2 = MessagePack.pack(v).length; puts "#{k}=#{l2} %=#{l2 * 100 / l}"}
      # end

      if pack.length > 128
        tag = "\x00\x04"
        buf = LZ4::Fixed.compress pack
      elsif true
        tag = "\x00\x01"
        buf = pack
      elsif false
        tag = "\x00\x03"
        buf = LZ4::compress pack
      elsif false
        tag = "\x00\x02"
        buf = Zlib::Deflate.deflate pack
      else
        return JSON.generate hash # for testing with old data only
      end

      #puts "-- before compression: #{pack.bytesize} after: #{buf.bytesize}"

      raw = [ tag, buf ].pack('a2a*').force_encoding('utf-8')

      # temporary code just to check data corruption bug
      begin
        hash2 = Jsonable.load_hash raw
        #Log_.info "load_hash succeed"
        return raw
      rescue => er
        Log_.error "load_hash failed!", er
        Log_.error "load_hash failed! buf.len=#{buf.bytesize}"
        Log_.error "load_hash failed! raw.len=#{raw.bytesize}"
        Log_.error "load_hash failed! raw.to_s.len=#{raw.to_s.bytesize}"
        File.open("load_hash_fail_content","w+") { |f| f.write(JSON.generate(hash)) }
        return JSON.generate hash
      end
    end

  end

end