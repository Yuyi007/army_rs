# MathExt.rb

module ::Math
  def self.min(num1, num2)
    num1 > num2 ? num2 : num1
  end

  def self.max(num1, num2)
    num1 > num2 ? num1 : num2
  end

  def self.clamp(num, min, max)
    return min if num < min
    return max if num > max
    num
  end

  def self.random(min, max)
    dis = max - min
    return min if (dis <= 0)
    return min + rand(dis)
  end
end
