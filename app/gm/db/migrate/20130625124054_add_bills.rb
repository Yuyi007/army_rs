class AddBills < ActiveRecord::Migration
  def up
    create_table "bills", :force => true do |t|
      t.string   "sdk"
      t.string   "platform"
      t.string   "transId", :null => false
      t.string   "playerId"
      t.string   "zone"
      t.string   "goodsId"
      t.integer  "count"
      t.integer  "price"
      t.integer  "status"
      t.datetime "created_at", :null => false
      t.datetime "updated_at", :null => false
    end

    add_index('bills', 'sdk')
    add_index('bills', 'platform')
    add_index('bills', 'transId')
    add_index('bills', 'playerId')
    add_index('bills', 'zone')
    add_index('bills', 'status')
  end

  def down
    drop_table 'bills'
  end
end
