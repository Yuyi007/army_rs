# RationalExt.rb

class ::Rational

  def to_msgpack io=nil
    to_f.to_msgpack io
  end

end