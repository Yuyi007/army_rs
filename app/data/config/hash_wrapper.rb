# HashWrapper.rb

module HashWrapper
  def self.included(base)
    base.class_variable_set(:@@json_methods, [])
    base.extend(ClassMethods)
  end

  def initialize(h = nil)
    from_hash!(h) if h
  end

  def from_hash!(h)
    @hash = h
    self
  end

  def method_missing(name, *args)
    key_name = name.to_s
    fail 'function has no name' if key_name.empty?

    if key_name =~ /=$/
      key_name = key_name.chop
      self.class.class_eval <<-EVAL
        def #{name}(x)
          @hash['#{key_name}'] = x
        end
      EVAL
      send(name, args[0])
    else
      self.class.class_eval <<-EVAL
        def #{name}
          @hash['#{key_name}']
        end
      EVAL
      send(name)
    end
  end

  def to_s
    to_hash.to_s
  end

  def to_json
    h = to_hash
    Oj.dump(h, mode: :compat)
  end

  def to_data
    to_hash
  end

  def to_hash
    h = @hash.clone
    json_methods = self.class.json_methods
    json_methods.each do |method|
      res = send(method)
      if res.is_a?(::Array)
        res = res.map { |x| if x && x.respond_to?(:to_hash) then x.to_hash else x end }
      elsif res.is_a?(::Hash)
        res = ::Hash[res.map { |k, v| if v && v.respond_to?(:to_hash) then [k, v.to_hash] else [k, v] end }]
      elsif res.respond_to?(:to_hash)
        res = res.to_hash
      end

      h[method.to_s] = res
    end
    h
  end

  def clone
    h = Helper.deep_copy(@hash)
    self.class.new(h)
  end

  def [](attr)
    @hash[attr.to_s]
  end

  module ClassMethods
    def jsonable(method)
      json_methods = self.json_methods
      json_methods << method
    end

    def json_methods
      class_variable_get('@@json_methods')
    end
  end
end
