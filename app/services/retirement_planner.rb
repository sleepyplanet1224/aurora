class RetirementPlanner
  ANNUAL_WITHDRAWAL_RATE = 0.04

  def self.call(user)
    new(user).call
  end

  def initialize(user)
    @user = user
  end

  def call
    monthly_expenses = @user.monthly_expenses.to_f
    return nil if monthly_expenses <= 0

    retirement_month = find_retirement_month(months, monthly_expenses)
    return nil unless retirement_month

    retirement_event = existing_retirement_event || Event.new
    retirement_event.name = "retirement"
    retirement_event.month = retirement_month
    retirement_event.new_total_assets = retirement_month.total_assets
    retirement_event.new_saved_amount = -monthly_expenses

    if defined?(Rails) && Rails.env.development?
      monthly_withdrawal_rate = ANNUAL_WITHDRAWAL_RATE / 12.0
      sustainable_withdrawal = retirement_month.total_assets.to_f * monthly_withdrawal_rate

      Rails.logger.info(
        "[RetirementPlanner] user_id=#{@user.id} " \
        "chosen_month=#{retirement_month.date} " \
        "total_assets=#{retirement_month.total_assets.round(2)} " \
        "monthly_expenses=#{monthly_expenses.round(2)} " \
        "sustainable_withdrawal=#{sustainable_withdrawal.round(2)}"
      )
    end

    retirement_event
  end

  private

  def months
    @user.months.order(:date)
  end

  def existing_retirement_event
    @user.events.find_by(name: "retirement")
  end

  def find_retirement_month(months, monthly_expenses)
    monthly_withdrawal_rate = ANNUAL_WITHDRAWAL_RATE / 12.0

    months.detect do |month|
      sustainable_withdrawal = month.total_assets.to_f * monthly_withdrawal_rate
      sustainable_withdrawal >= monthly_expenses
    end
  end
end
