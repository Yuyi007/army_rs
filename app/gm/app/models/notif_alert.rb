class NotifAlert < ActiveRecord::Base
  attr_accessible :name, :receivers, :enabled
end
