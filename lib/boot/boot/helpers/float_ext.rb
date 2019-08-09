class ::Float

  def times(&blk)
    to_i.times(&blk)
  end

end