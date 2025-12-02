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
      mortgage_rate = params[:event][:mortgage_rate].to_f / 100.0 / 12.0  # monthly
      mortgage_years = params[:event][:mortgage_years].to_i

      principal = house_price - down_payment
      months = mortgage_years * 12

      if mortgage_rate > 0
        monthly_payment = principal * (
          mortgage_rate * (1 + mortgage_rate)**months
        ) / ((1 + mortgage_rate)**months - 1)
      else
        monthly_payment = principal / months # zero interest mortgage
      end

      @event.new_total_assets = @event.new_total_assets.to_f - down_payment
      @event.new_saved_amount = @event.new_saved_amount.to_f - monthly_payment
    end

    if @event.save
      events_to_update = current_user.events
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

        @months.each do |month|
          interest_rate = month.interest_rate.to_f.nonzero? || 1.0  # prevent nil or zero

          month.update(
            total_assets: total_assets,
            saved_amount: saved_amount
          )

          total_assets += saved_amount
          total_assets *= interest_rate
        end
      end

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
