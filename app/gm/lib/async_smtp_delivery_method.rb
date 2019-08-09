# lib/async_smtp_delivery_method.rb
require 'mail'
 
class AsyncSmtpDeliveryMethod
 
  def initialize(settings)
    @settings = settings
  end
 
  def deliver!(mail)
    Thread.start do
      begin
        Mail::SMTP.new(@settings).deliver!(mail)
      rescue Exception => ex
        ::Rails.logger.error "Failed to send email: #{ex.inspect}"
        raise
      end
    end
  end
 
end
 
ActionMailer::Base.add_delivery_method :async_smtp, AsyncSmtpDeliveryMethod