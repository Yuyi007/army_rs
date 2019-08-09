class ChangeActionLog < ActiveRecord::Migration
  def up
    change_column :action_logs, :t, :string, :limit => 30
    change_column :action_logs, :param1, :string, :limit => 30
  end

  def down
    change_column :action_logs, :t, :string, :limit => 20
    change_column :action_logs, :param1, :string, :limit => 10
  end
end
