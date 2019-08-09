class AddActionParam6 < ActiveRecord::Migration
  def up
     add_column :action_logs, :param6, :string, :limit => 10
  end

  def down
  end
end
