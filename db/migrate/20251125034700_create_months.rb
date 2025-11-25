class CreateMonths < ActiveRecord::Migration[7.1]
  def change
    create_table :months do |t|
      t.integer :total_assets
      t.integer :saved_amount
      t.date :date
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
