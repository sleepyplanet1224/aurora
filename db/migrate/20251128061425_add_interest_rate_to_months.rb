class AddInterestRateToMonths < ActiveRecord::Migration[7.1]
  def change
    add_column :months, :interest_rate, :float
  end
end
