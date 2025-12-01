class MonthsController < ApplicationController
  def new
    @month = Month.new
  end

  def create
    @month = Month.new(month_params)
    @month.user = current_user

    if @month.save
      start_month = @month.date
      end_month   = (start_month + 30.years).end_of_month

      current = start_month
      total_assets = @month.total_assets
      saved_amount = @month.saved_amount
      interest_rate = @month.interest_rate

      while current <= end_month
        current_user.months.find_or_create_by!(
          date: current,
          user: current_user,
          total_assets: total_assets,
          saved_amount: saved_amount,
          interest_rate: interest_rate
        )
        total_assets += saved_amount
        total_assets *= interest_rate
        current = current.next_month
      end
      redirect_to dashboard_path, notice: "Month and 30 years of months created!"
    else
      render :new
    end
  end

  private

  def month_params
    params.require(:month).permit(:total_assets, :saved_amount, :date, :interest_rate)
  end
end
