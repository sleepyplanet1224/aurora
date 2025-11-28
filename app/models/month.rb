class Month < ApplicationRecord
  belongs_to :user
  has_many :events, dependent: :destroy

  validates :date, presence: true
  validates :total_assets, presence: true
  validates :saved_amount, presence: true
  RATES = {
    "Savings Account (Standard Bank) ~0%" => 1.0,
    "Savings Account (High-Yield) ~2%" => 1.001652,
    "Government Bonds (US/Japan/EU) ~3%" => 1.002466,
    "Corporate Bonds ~4%" => 1.003274,
    "World Index Fund - Conservative ~5%" => 1.004074,
    "World Index Fund - Balanced ~6%" => 1.004868,
    "World Index Fund - Optimistic ~8%" => 1.006434,
    "S&P 500 ETF - Historical Avg ~7%" => 1.005654
  }
end
