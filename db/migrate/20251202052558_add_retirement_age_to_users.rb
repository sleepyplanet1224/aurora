class AddRetirementAgeToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :retirement_age, :integer
  end
end
