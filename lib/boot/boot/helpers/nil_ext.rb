class NilClass
  def to_hash
    nil
  end

  def empty?
    true
  end

  def to_data(*args)
    nil
  end

  # def [](x)
  #   nil
  # end
end