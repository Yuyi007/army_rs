class CreateNotifReceivers < ActiveRecord::Migration
  def change
    create_table :notif_alerts, :id => true do |t|
      t.string   "name",       :limit => 40, :null => false
      t.string   "receivers",  :limit => 50
      t.boolean  "enabled",    :default => true
      t.timestamps
    end

    create_table :notif_receivers, :id => true do |t|
      t.string   "name",   :limit => 40, :null => false
      t.string   "mobile", :limit => 15, :null => false
      t.string   "email",  :limit => 50
      t.timestamps
    end

    add_index('notif_alerts', 'name', unique: true)
  end
end
