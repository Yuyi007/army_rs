# HashExt.rb

class ::Hash
  # Deep merge another hash
  def deep_merge(second)
    merge(second) do |_k, v1, v2|
      if Hash === v1 && Hash === v2
        v1.deep_merge(v2)
      elsif Array === v1 && Array === v2
        v1 + v2
      else
        v2
      end
    end
  end

  # the reverse operation of deep_merge
  def deep_substract(second)
    tmp = merge(second) do |_k, v1, v2|
      if Hash === v1 && Hash === v2
        v1.deep_substract(v2)
      elsif Array === v1 && Array === v2
        v1 - v2 # note v1 - v2 will remove duplicate elements
      elsif v1 == v2
        :__to_be_removed
      else
        v1
      end
    end
    tmp.deep_reject(:__to_be_removed)
  end

  # The same with deep_merge except that it doesn't try to concat Arrays
  def deep_merge_hash(second)
    merge(second) do |_k, v1, v2|
      if Hash === v1 && Hash === v2
        v1.deep_merge(v2)
      else
        v2
      end
    end
  end

  def method_missing(name, *args, &_block)
    key = name.to_s
    if self.key?(key)
      self[key]
    elsif key =~ /=$/
      self[key.chop] = args[0]
    elsif key =~ /[^a-zA-Z0-9]+$/
      raise "you can't use #{key} to a Hash"
    end
  end

  def delete_empty_key!
    delete('')
    delete(nil)

    each do |_k, v|
      v.delete_empty_key! if v.is_a?(::Hash)
    end
  end

  def dump
    Jsonable.dump_hash self
  end

  def to_data
    ::Hash[map do |k, v|
      if v.respond_to?(:to_data)
        [k, v.to_data]
      elsif v.is_a?(::String)
        if v =~ /^[0-9]+$/
          [k, v.to_i]
        else
          [k, v]
        end
      else
        [k, v]
      end
    end]
  end

  def deep_reject(value)
    each do |k, v|
      if Hash === v
        self[k] = v.deep_reject(value)
      elsif v == value
        delete k
      end
    end
  end
end
