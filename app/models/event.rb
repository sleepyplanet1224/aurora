class Event < ApplicationRecord
  belongs_to :month

  validates :name, presence: true
  validates :new_saved_amount, presence: true
  validates :new_total_assets, presence: true
end
