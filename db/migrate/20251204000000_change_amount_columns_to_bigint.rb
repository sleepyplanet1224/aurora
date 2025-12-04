class ChangeAmountColumnsToBigint < ActiveRecord::Migration[7.1]
  def change
    change_column :months, :total_assets, :bigint
    change_column :months, :saved_amount, :bigint

    change_column :events, :new_total_assets, :bigint
    change_column :events, :new_saved_amount, :bigint
  end
end
