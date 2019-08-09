class Bill < ActiveRecord::Base
  attr_accessible :sdk, :platform, :goodsId, :count, :playerId, :transId, :zone, :price, :status, :detail, :pid, :market
end
