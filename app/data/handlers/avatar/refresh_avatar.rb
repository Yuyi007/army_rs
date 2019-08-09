class RefreshAvatar < Handler
  def self.process(session, msg, model)
    instance = model.instance
    avatar_data = instance.avatar_data
    avatar_data.refresh_avatar
    res = {'success'=> true, 'avatar'=> avatar_data.to_hash}
  end
end