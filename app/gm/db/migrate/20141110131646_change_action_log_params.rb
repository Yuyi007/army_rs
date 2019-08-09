class ChangeActionLogParams < ActiveRecord::Migration
  def up
    change_column :action_logs, :param2, :string, :limit => 30
    change_column :action_logs, :param3, :string, :limit => 30
  end

  def down
  end
end
