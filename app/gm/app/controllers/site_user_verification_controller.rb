class SiteUserVerificationController < ApplicationController

  before_filter :load_user_using_perishable_token

  include RsRails

  def show
    if @user
      @user.verify!
      flash[:notice] = "Thank you for verifying your account. You may now login."
    end

    redirect_to root_url
  end

private

  def load_user_using_perishable_token
    @user = SiteUser.find_using_perishable_token(params[:token])
    flash[:notice] = "Unable to find your account." unless @user
  end

end