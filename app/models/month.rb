class Month < ApplicationRecord
  belongs_to :user
  has_many :events, dependent: :destroy

  validates :date, presence: true
  validates :total_assets, presence: true
  validates :saved_amount, presence: true
end
