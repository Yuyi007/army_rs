class ApplicationController < ActionController::Base

  include RsRails

  protect_from_forgery

  # before_filter :ensure_worker_threads

  # def ensure_worker_threads
  #   RsRails.ensure_worker_threads
  # end

end
