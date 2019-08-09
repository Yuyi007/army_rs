class Util

  #return: play_id 账户中的某一个角色id, account_id 账户id,
  def self.split_uid(uid)
    arr = uid.split('_')
    if arr.length == 1
      return [uid, uid]
    else
      return [uid, arr[1]]
    end
  end

end