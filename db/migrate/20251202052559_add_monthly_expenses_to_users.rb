class AddMonthlyExpensesToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :monthly_expenses, :integer
  end
end
