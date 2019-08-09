class ::Array
  def to_data(*args)
    map { |x| x.respond_to?(:to_data) ? x.to_data(*args) : x }
  end

  def random(weight_key, total_weight = nil)
    total_weight ||= inject(0) { |sum, x| sum += x[weight_key].to_i }
    roll = rand(total_weight)
    start = 0
    stop = 0
    detect do |x|
      start = stop
      stop += x[weight_key].to_i
      start <= roll && roll < stop
    end
  end

  # select one element and delete it from array
  def random_pick!(weight_key, total_weight = nil)
    total_weight ||= inject(0) { |sum, x| sum += x[weight_key].to_i }
    roll = rand(total_weight)
    start = 0
    stop = 0

    res_x = nil
    res_index = nil
    each_with_index do |x, i|
      start = stop
      stop += x[weight_key].to_i
      if start <= roll && roll < stop
        res_x = x
        res_index = i
        break
      end
    end
    delete_at(res_index) if res_index
    return res_x
  end

  # add this function will be faster than modifying
  # random_pick! to let weight_key can be nil
  def random_pick_no_weight!()
    total_weight = inject(0) { |sum, x| sum += 1 }
    roll = rand(total_weight)
    start = 0
    stop = 0

    res_x = nil
    res_index = nil
    each_with_index do |x, i|
      start = stop
      stop += 1
      if start <= roll && roll < stop
        res_x = x
        res_index = i
        break
      end
    end
    delete_at(res_index) if res_index
    return res_x
  end

  def weighted_sample(weight_key, num = 1)
    res = []
    num = size if num > size
    until res.size == num
      list = self - res
      break if list.empty?
      res << list.random(weight_key)
    end
    res
  end

  def delete_empty_key!
    each do |v|
      v.delete_empty_key! if v.is_a?(::Hash)
    end
  end

  # make sure your array is sorted
  # judge_method(value)  in -1, 0, 1
  # -1 means value is smaller, 1 means value is bigger
  # npc = Npc.new()
  # judje_method = npc.method(:check_topic_value)
  # return index of result in array, and nil means not find.
  def binary_search(judge_method, low=0, high=self.size-1)
    return nil if low > high
    mid = (low + high) / 2
    res = judge_method.call(self[mid])
    return mid if res == 0
    if res == 1
      high = mid - 1
    else
      low = mid + 1
    end
    binary_search(judge_method, low, high)
  end

  def bsearch_index(&blk)
    (0...self.size).bsearch do |i|
      yield(self[i])
    end
  end
end
