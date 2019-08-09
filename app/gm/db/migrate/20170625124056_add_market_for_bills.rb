class AddMarketForBills < ActiveRecord::Migration
  def change
    # add_column :bills, :market, :string
    add_index "bills", ["market"], :name => "index_bills_on_market"
    add_index "bills", ["pid"], :name => "index_bills_on_pid"
  end
end
