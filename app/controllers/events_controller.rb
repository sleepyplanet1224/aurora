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

      if mortgage_rate > 0
        monthly_payment = principal * (
          mortgage_rate * ((1 + mortgage_rate)**months)
        ) / (((1 + mortgage_rate)**months) - 1)
      else
        monthly_payment = principal / months # zero interest mortgage
      end

      @event.new_total_assets = @event.new_total_assets.to_f - down_payment
      @event.new_saved_amount = @event.new_saved_amount.to_f - monthly_payment
    end

    success, @event = ApplyEvents.call(@event, current_user)

    if success
      redirect_to dashboard_path, notice: "Event created successfully."
    else
      redirect_to dashboard_path, alert: "Failed to create event."
    end
  end

  private

  def event_params
    params.require(:event).permit(:name, :new_total_assets, :new_saved_amount, :month_id)
  end
end
