class EventsController < ApplicationController
  def new
    @event = Event.new
    @month = current_user.months.find_by(date: params[:month] + "-01")
    @event_name = params.dig(:search, :name)&.strip
  end

  def create
    @event = Event.new(event_params)

    case @event.name
    when "promotion"
      if params[:event][:percentage].present?
        percentage = params[:event][:percentage].to_f
        multiplier = 1 + (percentage / 100.0)
        @event.new_saved_amount = @event.new_saved_amount.to_f * multiplier
      end
    when "marriage"
      if params[:event][:spouse_total_assets].present?
        spouse_total_assets = params[:event][:spouse_total_assets].to_f
        spouse_saved_amount = params[:event][:spouse_saved_amount].to_f
        @event.new_total_assets = @event.new_total_assets.to_f + spouse_total_assets
        @event.new_saved_amount = @event.new_saved_amount.to_f + spouse_saved_amount
      end
    when "buying a house"
      house_price = params[:event][:house_price].to_f
      down_payment = params[:event][:down_payment].to_f
      mortgage_rate = params[:event][:mortgage_rate].to_f / 100.0 / 12.0 # monthly
      mortgage_years = params[:event][:mortgage_years].to_i

      principal = house_price - down_payment
      months = mortgage_years * 12
      mortgage_end_date = @event.month.date >> months

      if mortgage_rate > 0
        monthly_payment = principal * (
          mortgage_rate * ((1 + mortgage_rate)**months)
        ) / (((1 + mortgage_rate)**months) - 1)
      else
        monthly_payment = principal / months # zero interest mortgage
      end

      # Treat the house as a consumption asset: do NOT add house_price into the
      # investable assets used for retirement calculations. Only the down payment
      # reduces investable assets here; the house value is tracked implicitly
      # through cash flows (mortgage payments) rather than as part of total_assets.
      @event.new_total_assets = @event.new_total_assets.to_f - down_payment

      # Create a marker event for when the mortgage is fully paid so users
      # can see that milestone on the timeline, without changing the projection.
      payoff_month = current_user.months.find_by(date: mortgage_end_date)
      if payoff_month
        Event.find_or_create_by(name: "mortgage paid", month: payoff_month) do |e|
          e.new_total_assets = payoff_month.total_assets
          e.new_saved_amount = payoff_month.saved_amount
        end
      end
      # @event.new_monthly_payment = monthly_payment
      # @event.mortgage_years = mortgage_years
    end

    return unless @event.save

    events_to_update = current_user.events
                                   .where.not(name: ["retirement", "mortgage paid"])
                                   .joins(:month)
                                   .where("months.date >= ?", @event.month.date)
                                   .order("months.date ASC")

    last_index = events_to_update.length - 1
    events_to_update.each_with_index do |event, index|
      if index < last_index
        event_end_date = events_to_update[index + 1].month.date
      else
        event_end_date = current_user.months.last.date.next
      end
      @months = current_user.months.where("date >= ? AND date < ?", event.month.date, event_end_date).order(:date)

      total_assets = event.new_total_assets.to_f
      saved_amount = event.new_saved_amount.to_f

      if event.name == "buying a house"
        mortgage_years_param = params[:event][:mortgage_years].to_i
        mortgage_months = mortgage_years_param * 12
        mortgage_end_date = event.month.date >> mortgage_months

        house_price_param = params[:event][:house_price].to_f
        down_payment_param = params[:event][:down_payment].to_f
        mortgage_rate_param = params[:event][:mortgage_rate].to_f / 100.0 / 12.0

        principal_param = house_price_param - down_payment_param
        if mortgage_rate_param > 0
          monthly_payment = principal_param * (
            mortgage_rate_param * ((1 + mortgage_rate_param)**mortgage_months)
          ) / (((1 + mortgage_rate_param)**mortgage_months) - 1)
        else
          monthly_payment = principal_param / mortgage_months
        end
      end

      @months.each do |month|
        interest_rate = month.interest_rate.to_f.nonzero? || 1.0 # prevent nil or zero

        if event.name == "buying a house" && month.date < mortgage_end_date
          saved_amount_for_month = saved_amount.to_f - monthly_payment
          # saved_amount_for_month = 0 if saved_amount_for_month < 0  # prevent negative saving
        else
          saved_amount_for_month = saved_amount
        end

        previous_assets = total_assets

        month.update(
          total_assets: total_assets,
          saved_amount: saved_amount_for_month
        )

        total_assets += saved_amount_for_month
        total_assets *= interest_rate

        if defined?(Rails) && Rails.env.development?
          Rails.logger.info(
            "[EventsController] user_id=#{current_user.id} " \
            "event=#{event.name} month=#{month.date} " \
            "prev_assets=#{previous_assets.round(2)} " \
            "saved_amount=#{saved_amount_for_month.round(2)} " \
            "interest_rate=#{interest_rate} " \
            "new_assets=#{total_assets.round(2)}"
          )
        end
      end
    end

    # Recompute retirement event based on the updated projection.
    retirement_event = RetirementPlanner.call(current_user)
    ApplyEvents.call(retirement_event, current_user) if retirement_event

    redirect_to dashboard_path, notice: "Event created successfully."
  end

  private

  def event_params
    params.require(:event).permit(:name, :new_total_assets, :new_saved_amount, :month_id)
  end
end
