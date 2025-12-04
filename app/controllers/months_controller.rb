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

      current_user.update(retirement_age: params[:retirement_age].to_i,
                          monthly_expenses: params[:monthly_expenses].to_i)

      # ----------------- CHANGED PART -----------------
      # Original code:
      # month = current_user.months.find_by(date: retirement_date.beginning_of_month)
      # This could return nil and cause NoMethodError

      retirement_date = current_user.birthday + params[:retirement_age].to_i.years

      # Use find_or_create_by to ensure month exists
      current_user.months.find_or_create_by(date: retirement_date.beginning_of_month) do |m|
        m.user = current_user              # Associate with current user
        m.total_assets = total_assets      # Safe default total assets
        m.saved_amount = 0                 # No savings in retirement month
        m.interest_rate = interest_rate    # Use last known interest rate
      end
      # ----------------- END CHANGED PART -----------------

      current_user.update(retirement_age: params[:retirement_age].to_i,
                          monthly_expenses: params[:monthly_expenses].to_i)
      retirement_date = current_user.birthday + params[:retirement_age].to_i.years
      month = current_user.months.find_by(date: retirement_date.beginning_of_month)

      @event = Event.create(
        name: "retirement",
        month: month,
        new_total_assets: month.total_assets,
        new_saved_amount: -current_user.monthly_expenses
      )
    end

    success, @event = ApplyEvents.call(@event, current_user)

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
