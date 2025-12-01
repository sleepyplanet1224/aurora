class EventsController < ApplicationController
  def new
    @event = Event.new
    @month = current_user.months.find_by(date: params[:month] + "-01")
  end

  def create
    @event = Event.new(event_params)

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
