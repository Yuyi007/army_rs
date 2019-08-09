
class CreateShareAwardReport < ActiveRecord::Migration
  def up
    create_table :share_award, :options => 'ENGINE=InnoDB DEFAULT CHARSET=utf8' do |t|
      t.integer :zone_id,        :default => 0
      t.string  :sdk,            :null => false, :limit => 50
      t.string  :platform,       :null => false, :limit => 10
      t.date     :date,           :null => false
      t.string   :tid,            :null => false
    end
    add_index :share_award, [:date, :zone_id]

    create_table :share_award_report, :options => 'ENGINE=InnoDB DEFAULT CHARSET=utf8' do |t|
      t.integer :zone_id,        :default => 0
      t.string  :sdk,            :null => false, :limit => 50
      t.string  :platform,       :null => false, :limit => 10
      t.date     :date,           :null => false
      t.string   :tid,            :null => false
      t.integer  :num,            :default => 0
    end
    add_index :share_award_report, [:date, :zone_id]
  
  end

  def down
    drop_table :share_award
    drop_table :share_award_report
  end

end