# events_controller.rb

class EventsController < ApplicationController
	AUTH_LEVEL = {:admin => 1, :p0 => 2, :p1 => 3, :p2 => 4, :p3 => 5, :p4 => 6, :guest => 7} unless defined? AUTH_LEVEL



	def authSuperThan auth
		authLevel = current_user.role_ids[0]
		if AUTH_LEVEL[auth].nil?
			return false
		end
		if AUTH_LEVEL[auth].to_i <= authLevel
			return false
		else
			return true
		end
	end

	def curAuth
		current_user.role_ids[0]
	end

	def grant
    eventType = params[:eventType]
    userInfo = curUserInfo()
    res = RsRails.grant(userInfo, eventType)
    render :json => res
  end

  def reject
    eventType = params[:eventType]
    userInfo = curUserInfo()
    res = RsRails.reject(userInfo, eventType)
    render :json => res
  end


end