class CreateEvents < ActiveRecord::Migration[7.1]
  def change
    create_table :events do |t|
      t.references :month, null: false, foreign_key: true
      t.string :name
      t.integer :new_saved_amount
      t.integer :new_total_assets

      t.timestamps
    end
  end
end
