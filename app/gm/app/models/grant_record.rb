class GrantRecord < ActiveRecord::Base
  attr_accessible :action, :item_amount, :item_id, :item_name, :reason, :site_user_id, :status, :success, :target_id, :target_zone
  belongs_to :site_user
end
