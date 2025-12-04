class MonthsController < ApplicationController
  def new
    @month = Month.new
  end

  def create
    @month = Month.new(month_params)
    @month.user = current_user

    if @month.save
      # Build 80 years of baseline months
      start_month = @month.date
      end_month   = (start_month + 80.years).end_of_month

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

      # Save retirement preferences on the user
      current_user.update(
        retirement_age: params[:retirement_age].to_i,
        monthly_expenses: params[:monthly_expenses].to_i
      )

      # Automatically determine the first possible retirement month:
      # find the earliest month where monthly interest on total assets
      # is greater than or equal to the desired retirement monthly expenses.
      monthly_expenses = current_user.monthly_expenses.to_f
      retirement_month = nil

      current_user.months.order(:date).each do |month|
        rate = month.interest_rate.to_f
        # Interest is the growth part only (e.g. 1.004868 -> 0.004868)
        monthly_interest = month.total_assets.to_f * (rate - 1.0)

        if monthly_interest >= monthly_expenses
          retirement_month = month
          break
        end
      end

      # Only create a retirement event if it's actually possible within the horizon.
      if retirement_month
        @event = Event.new(
          name: "retirement",
          month: retirement_month,
          new_total_assets: retirement_month.total_assets,
          new_saved_amount: -current_user.monthly_expenses
        )
      else
        @event = nil
      end
    end

    if @event
      success, @event = ApplyEvents.call(@event, current_user)
    else
      success = true
    end

    if success

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
