class AddBillsDetail < ActiveRecord::Migration
  def change
    add_column :bills, :detail, :string
  end
end
