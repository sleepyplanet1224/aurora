class Event < ApplicationRecord
  belongs_to :month

  NAMES = ["birth of a child", "buying a car", "inheritance", "marriage", "promotion"]

  validates :name, presence: true
  validates :new_saved_amount, presence: true
  validates :new_total_assets, presence: true
end
