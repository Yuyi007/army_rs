module EnumLevel
  def enum_level(&block)
    i = 0;
    while i < 100 do
      if i < 20
        i += 10
      else
        i += 5
      end
      block.call(i) if block
    end
  end

  def empty
    x = {}
    enum_level do |i|
      x[i.to_s] = {:num => 0, :players => 0}
    end
    x
  end

  def lv_rgn(level)
    level_rgn = 10
    if level <= 20
      level_rgn = (level.to_f/10).ceil*10
    else
      level_rgn = (level.to_f/5).ceil*5
    end
    level_rgn
  end
  
end