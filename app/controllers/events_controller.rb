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

        total_assets = event.new_total_assets
        saved_amount = event.new_saved_amount
        @months.each do |month|
          month.update(
            total_assets: total_assets,
            saved_amount: saved_amount
          )
          total_assets += saved_amount
          total_assets *= month.interest_rate
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
